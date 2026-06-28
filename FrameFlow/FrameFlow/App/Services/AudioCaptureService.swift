//
//  AudioCaptureService.swift
//  FrameFlow
//

import AVFoundation
import AudioToolbox
import CoreMedia
import Foundation

/// Shared mic-active flag readable from mixQueue without touching `@MainActor` service state.
final class MicCaptureState: @unchecked Sendable {
    nonisolated(unsafe) var isActive = false
}

/// Thread-safe system PCM ring consumed on the audio mix queue during combined capture.
fileprivate final class CombinedSystemPCMRing: @unchecked Sendable {
    nonisolated(unsafe) var samples: [Float] = []
    nonisolated let maxSamples: Int = 480_000 * 2
}

@MainActor
@Observable
final class AudioCaptureService {
    private(set) var liveLevel: Float = 0
    private(set) var statusMessage: String?
    private(set) var isRunning = false
    private(set) var micCaptureActive = false

    private var audioEngine: AVAudioEngine?
    private var audioMode: AudioModeOption = .none
    private var micVolume: Float = 1.0
    private var systemVolume: Float = 1.0
    private var appendSampleBuffer: ((CMSampleBuffer, CMTime) -> Void)?
    private nonisolated(unsafe) var onAppendSampleBuffer: ((CMSampleBuffer, CMTime) -> Void)?
    private var systemBufferCount = 0
    private var writerSampleRate: Double = 48_000
    private let combinedSystemRing = CombinedSystemPCMRing()

    private let micCaptureState = MicCaptureState()
    /// Larger buffer reduces HAL cycle pressure during PiP + composite recording.
    private static let tapBufferSize: AVAudioFrameCount = 4096
    private let mixQueue = DispatchQueue(
        label: "com.Simranjit.FrameFlow.audio.capture",
        qos: .userInteractive
    )

    nonisolated static func defaultInputSampleRate() -> Double {
        let engine = AVAudioEngine()
        defer { engine.stop() }
        return engine.inputNode.outputFormat(forBus: 0).sampleRate
    }

    func start(
        mode: AudioModeOption,
        micVolume: Float,
        systemVolume: Float,
        preferredMicDeviceUniqueID: String?,
        appendSampleBuffer: @escaping (CMSampleBuffer, CMTime) -> Void
    ) async {
        stop()

        self.audioMode = mode
        self.micVolume = max(0, min(1, micVolume))
        self.systemVolume = max(0, min(1, systemVolume))
        self.appendSampleBuffer = appendSampleBuffer
        self.onAppendSampleBuffer = appendSampleBuffer
        self.systemBufferCount = 0
        self.combinedSystemRing.samples.removeAll()
        self.writerSampleRate = 48_000
        self.statusMessage = nil
        self.liveLevel = 0
        self.micCaptureActive = false

        guard mode != .none else {
            isRunning = true
            return
        }

        if includesMic {
            await startMicrophoneCapture(
                preferredMicDeviceUniqueID: preferredMicDeviceUniqueID,
                onAppend: appendSampleBuffer
            )
        }

        isRunning = true
    }

    func stop() {
        micCaptureState.isActive = false
        if let audioEngine {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        audioEngine = nil
        appendSampleBuffer = nil
        onAppendSampleBuffer = nil
        combinedSystemRing.samples.removeAll()
        isRunning = false
        micCaptureActive = false
        liveLevel = 0
        AudioCaptureDiagnostics.logStopSummaryIfNeeded()
    }

    func ingestSystemAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isRunning, includesSystem else { return }
        systemBufferCount += 1

        if systemBufferCount == 1 {
            statusMessage = "System audio stream detected."
        }

        if let level = AudioMixerEngine.levelFromSampleBuffer(sampleBuffer) {
            Task { @MainActor in
                self.liveLevel = max(self.liveLevel * 0.7, min(1, level * max(0.05, self.systemVolume)))
            }
        }

        let captureHostTime = CMClockGetTime(CMClockGetHostTimeClock())

        if audioMode == .combined {
            let targetRate = writerSampleRate
            let ring = combinedSystemRing
            mixQueue.async {
                guard let samples = AudioMixerEngine.interleavedPCMFromSampleBuffer(
                    sampleBuffer,
                    targetSampleRate: targetRate
                ), !samples.isEmpty else {
                    return
                }
                ring.samples.append(contentsOf: samples)
                if ring.samples.count > ring.maxSamples {
                    ring.samples.removeFirst(ring.samples.count - ring.maxSamples)
                }
            }
            return
        }

        AudioCaptureDiagnostics.recordAppend()
        onAppendSampleBuffer?(sampleBuffer, captureHostTime)
    }

    private var includesMic: Bool {
        audioMode == .mic || audioMode == .combined
    }

    private var includesSystem: Bool {
        audioMode == .system || audioMode == .combined
    }

    private func startMicrophoneCapture(
        preferredMicDeviceUniqueID: String?,
        onAppend: @escaping (CMSampleBuffer, CMTime) -> Void
    ) async {
        let status = PermissionManager.shared.checkMicrophonePermission()
        if status == .notDetermined {
            let granted = await PermissionManager.shared.requestMicrophonePermission()
            guard granted else {
                statusMessage = "Microphone permission denied. Recording will continue with available audio sources."
                return
            }
        } else if status != .authorized {
            statusMessage = "Microphone permission denied. Recording will continue with available audio sources."
            return
        }

        if preferredMicDeviceUniqueID != nil {
            // Device selection support remains tied to system default input for now.
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let outputSampleRate = inputFormat.sampleRate
        self.writerSampleRate = outputSampleRate
        let canonicalFormat = AudioMixerEngine.canonicalPCMFormat(sampleRate: outputSampleRate)
        let gain = micVolume
        let mixMode = audioMode
        let systemGain = systemVolume

        #if DEBUG
        print(
            "[AudioCapture] mic tap format: \(inputFormat.sampleRate)Hz " +
            "channels=\(inputFormat.channelCount) interleaved=\(inputFormat.isInterleaved) " +
            "writerRate=\(outputSampleRate)Hz"
        )
        #endif

        micCaptureState.isActive = true

        let liveLevelUpdater: (Float) -> Void = { [weak self] level in
            Task { @MainActor in
                guard let self else { return }
                self.liveLevel = self.liveLevel * 0.65 + min(1, level) * 0.35
            }
        }

        installMicrophoneTap(
            on: inputNode,
            format: inputFormat,
            canonicalFormat: canonicalFormat,
            outputSampleRate: outputSampleRate,
            gain: gain,
            mixMode: mixMode,
            systemGain: systemGain,
            captureState: micCaptureState,
            onAppend: onAppend,
            onLiveLevel: liveLevelUpdater
        )

        do {
            engine.prepare()
            try engine.start()
            self.audioEngine = engine

            try await Task.sleep(nanoseconds: micWarmupNanoseconds(for: mixMode))
            var tapCount = AudioCaptureDiagnostics.snapshot().tapCount
            if tapCount == 0, mixMode == .combined {
                try await Task.sleep(nanoseconds: 500_000_000)
                tapCount = AudioCaptureDiagnostics.snapshot().tapCount
            }
            if tapCount == 0 {
                micCaptureState.isActive = false
                micCaptureActive = false
                inputNode.removeTap(onBus: 0)
                engine.stop()
                self.audioEngine = nil
                statusMessage = "Microphone capture failed to produce audio. Recording will continue without mic."
                #if DEBUG
                print("[AudioCapture] WARNING: no mic taps within 300ms after engine start")
                #endif
            } else {
                micCaptureActive = true
            }
        } catch {
            micCaptureState.isActive = false
            micCaptureActive = false
            inputNode.removeTap(onBus: 0)
            statusMessage = "Could not start microphone capture. Recording will continue with available audio sources."
        }
    }

    private func micWarmupNanoseconds(for mode: AudioModeOption) -> UInt64 {
        mode == .combined ? 600_000_000 : 300_000_000
    }

    private func installMicrophoneTap(
        on inputNode: AVAudioInputNode,
        format tapFormat: AVAudioFormat,
        canonicalFormat: AVAudioFormat,
        outputSampleRate: Double,
        gain: Float,
        mixMode: AudioModeOption,
        systemGain: Float,
        captureState: MicCaptureState,
        onAppend: @escaping (CMSampleBuffer, CMTime) -> Void,
        onLiveLevel: @escaping (Float) -> Void
    ) {
        let captureMixQueue = mixQueue
        let systemRing = combinedSystemRing
        inputNode.installTap(
            onBus: 0,
            bufferSize: Self.tapBufferSize,
            format: tapFormat
        ) { buffer, time in
            AudioCaptureDiagnostics.recordTap()
            let captureHostTime = AudioMixerEngine.hostTime(from: time)
            guard let copiedBuffer = AudioMixerEngine.copyPCMBuffer(buffer) else {
                AudioCaptureDiagnostics.recordCopyFail()
                return
            }

            captureMixQueue.async {
                AudioCaptureDiagnostics.recordMixQueueEnter()
                guard captureState.isActive else {
                    AudioCaptureDiagnostics.recordSkippedNotRunning()
                    return
                }
                guard let converted = AudioMixerEngine.convert(
                    buffer: copiedBuffer,
                    to: canonicalFormat
                ) else {
                    AudioCaptureDiagnostics.recordConvertFail()
                    return
                }

                let level = AudioMixerEngine.levelFromPCMBuffer(converted) * max(0.05, gain)
                onLiveLevel(level)

                let bufferForWriter: AVAudioPCMBuffer
                if mixMode == .combined {
                    bufferForWriter = AudioMixerEngine.mixMicBufferWithSystemRing(
                        micBuffer: converted,
                        systemRing: systemRing,
                        micGain: gain,
                        systemGain: systemGain
                    ) ?? converted
                } else {
                    bufferForWriter = converted
                }

                let writerGain: Float = mixMode == .combined ? 1.0 : gain
                guard let sampleBuffer = AudioMixerEngine.makeSampleBuffer(
                    from: bufferForWriter,
                    sampleRate: outputSampleRate,
                    gain: writerGain
                ) else {
                    AudioCaptureDiagnostics.recordMakeBufferFail()
                    return
                }

                AudioCaptureDiagnostics.recordAppend()
                AudioCaptureDiagnostics.logPeriodicIfNeeded()
                onAppend(sampleBuffer, captureHostTime)
            }
        }
    }
}

enum AudioMixerEngine {
    static func canonicalPCMFormat(sampleRate: Double) -> AVAudioFormat {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 2,
            interleaved: false
        )!
    }

    static func hostTime(from audioTime: AVAudioTime) -> CMTime {
        if audioTime.isHostTimeValid {
            return CMClockMakeHostTimeFromSystemUnits(audioTime.hostTime)
        }
        return CMClockGetTime(CMClockGetHostTimeClock())
    }

    static func convert(buffer: AVAudioPCMBuffer, to outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard buffer.frameLength > 0 else { return nil }

        if formatsMatch(buffer.format, outputFormat) {
            return buffer
        }

        var working = buffer

        if working.format.channelCount == 1, outputFormat.channelCount >= 2 {
            guard let stereo = upmixMonoToStereoNonInterleaved(working) else {
                AudioCaptureDiagnostics.logConvertFailOnce(
                    stage: "upmix",
                    input: working.format,
                    output: outputFormat
                )
                return nil
            }
            working = stereo
            if formatsMatch(working.format, outputFormat) {
                return working
            }
        }

        guard let resampled = resamplePCMBuffer(working, to: outputFormat) else {
            AudioCaptureDiagnostics.logConvertFailOnce(
                stage: "resample",
                input: working.format,
                output: outputFormat
            )
            return nil
        }
        return resampled
    }

    static func pcmBuffer(from sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        guard CMSampleBufferGetNumSamples(sampleBuffer) > 0,
              let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription),
              let format = AVAudioFormat(streamDescription: asbd) else {
            return nil
        }

        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sampleBuffer,
            at: 0,
            frameCount: Int32(frameCount),
            into: buffer.mutableAudioBufferList
        )
        guard status == noErr else { return nil }
        return buffer
    }

    static func interleavedPCMFromSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        targetSampleRate: Double
    ) -> [Float]? {
        guard let pcm = pcmBuffer(from: sampleBuffer) else { return nil }
        let targetFormat = canonicalPCMFormat(sampleRate: targetSampleRate)
        guard let converted = convert(buffer: pcm, to: targetFormat) else { return nil }
        return interleavedFloatData(from: converted)
    }

    fileprivate static func mixMicBufferWithSystemRing(
        micBuffer: AVAudioPCMBuffer,
        systemRing: CombinedSystemPCMRing,
        micGain: Float,
        systemGain: Float
    ) -> AVAudioPCMBuffer? {
        guard let micInterleaved = interleavedFloatData(from: micBuffer) else { return nil }

        let frameCount = Int(micBuffer.frameLength)
        let channels = Int(micBuffer.format.channelCount)
        guard frameCount > 0, channels > 0 else { return nil }

        let needed = frameCount * channels
        var systemSamples = [Float](repeating: 0, count: needed)
        let available = min(needed, systemRing.samples.count)
        if available > 0 {
            for index in 0..<available {
                systemSamples[index] = systemRing.samples[index]
            }
            systemRing.samples.removeFirst(available)
        }

        var mixed = [Float](repeating: 0, count: needed)
        for index in 0..<needed {
            let sum = micInterleaved[index] * micGain + systemSamples[index] * systemGain
            mixed[index] = softLimitSample(sum, gain: 1.0)
        }

        guard let output = AVAudioPCMBuffer(
            pcmFormat: micBuffer.format,
            frameCapacity: micBuffer.frameCapacity
        ) else {
            return nil
        }
        output.frameLength = micBuffer.frameLength

        guard let channelData = output.floatChannelData else { return nil }
        for frame in 0..<frameCount {
            for channel in 0..<channels {
                channelData[channel][frame] = mixed[frame * channels + channel]
            }
        }
        return output
    }

    private static func resamplePCMBuffer(
        _ input: AVAudioPCMBuffer,
        to outputFormat: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        guard input.format.channelCount == outputFormat.channelCount else {
            return nil
        }

        if abs(input.format.sampleRate - outputFormat.sampleRate) < 1 {
            return input
        }

        guard let converter = AVAudioConverter(from: input.format, to: outputFormat) else {
            return nil
        }

        let inputFrames = Double(input.frameLength)
        let ratio = outputFormat.sampleRate / input.format.sampleRate
        let expectedFrames = AVAudioFrameCount(ceil(inputFrames * ratio) + 64)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: expectedFrames) else {
            return nil
        }

        let scratchCapacity = max(expectedFrames, AVAudioFrameCount(4096))
        guard let scratchBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: scratchCapacity) else {
            return nil
        }

        var hasProvidedInput = false
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            if hasProvidedInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            hasProvidedInput = true
            outStatus.pointee = .haveData
            return input
        }

        var totalOutputFrames: AVAudioFrameCount = 0
        var conversionError: NSError?
        var iterations = 0
        let maxIterations = 32

        while iterations < maxIterations {
            iterations += 1
            scratchBuffer.frameLength = 0
            let status = converter.convert(to: scratchBuffer, error: &conversionError, withInputFrom: inputBlock)

            if status == .error {
                return nil
            }

            if scratchBuffer.frameLength > 0 {
                guard appendPCMBuffer(
                    scratchBuffer,
                    to: outputBuffer,
                    atFrameOffset: totalOutputFrames
                ) else {
                    return nil
                }
                totalOutputFrames += scratchBuffer.frameLength
            }

            if status == .inputRanDry || status == .endOfStream {
                break
            }

            if hasProvidedInput && scratchBuffer.frameLength == 0 {
                break
            }
        }

        #if DEBUG
        if iterations >= maxIterations {
            print("[AudioCapture] WARNING: resample hit iteration cap")
        }
        #endif

        outputBuffer.frameLength = totalOutputFrames
        guard totalOutputFrames > 0 else {
            return nil
        }
        return outputBuffer
    }

    private static func upmixMonoToStereoNonInterleaved(_ input: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard input.format.channelCount == 1,
              input.format.commonFormat == .pcmFormatFloat32,
              let mono = input.floatChannelData?[0] else {
            return nil
        }

        let frameCount = Int(input.frameLength)
        guard frameCount > 0,
              let outFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: input.format.sampleRate,
                channels: 2,
                interleaved: false
              ),
              let out = AVAudioPCMBuffer(
                pcmFormat: outFormat,
                frameCapacity: AVAudioFrameCount(frameCount)
              ),
              let left = out.floatChannelData?[0],
              let right = out.floatChannelData?[1] else {
            return nil
        }

        out.frameLength = AVAudioFrameCount(frameCount)
        for index in 0..<frameCount {
            let sample = mono[index]
            left[index] = sample
            right[index] = sample
        }
        return out
    }

    static func makeSampleBuffer(
        from pcmBuffer: AVAudioPCMBuffer,
        sampleRate: Double,
        gain: Float
    ) -> CMSampleBuffer? {
        guard pcmBuffer.frameLength > 0,
              let data = interleavedFloatData(from: pcmBuffer) else {
            #if DEBUG
            print("[AudioCapture] makeSampleBuffer fail: interleavedFloatData unavailable")
            #endif
            return nil
        }

        let channels = Int(pcmBuffer.format.channelCount)
        let frameCount = Int(pcmBuffer.frameLength)
        let expectedInterleavedSamples = frameCount * channels
        guard data.count == expectedInterleavedSamples else {
            #if DEBUG
            print("[AudioCapture] makeSampleBuffer fail: frames=\(frameCount) channels=\(channels)")
            #endif
            return nil
        }

        let scaled = data.map { softLimitSample($0, gain: gain) }
        let expectedByteLength = expectedInterleavedSamples * MemoryLayout<Float>.size

        var asbd = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
            mBytesPerPacket: UInt32(channels * MemoryLayout<Float>.size),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(channels * MemoryLayout<Float>.size),
            mChannelsPerFrame: UInt32(channels),
            mBitsPerChannel: 32,
            mReserved: 0
        )

        var formatDescription: CMAudioFormatDescription?
        let formatStatus = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &asbd,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        guard formatStatus == noErr, let formatDescription else {
            #if DEBUG
            print("[AudioCapture] makeSampleBuffer fail: frames=\(frameCount) channels=\(channels)")
            #endif
            return nil
        }

        let dataLength = scaled.count * MemoryLayout<Float>.size
        guard dataLength == expectedByteLength else {
            return nil
        }
        var blockBuffer: CMBlockBuffer?
        let blockStatus = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: dataLength,
            blockAllocator: nil,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: dataLength,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        guard blockStatus == noErr, let blockBuffer else {
            return nil
        }

        let replaceStatus = scaled.withUnsafeBytes { raw in
            CMBlockBufferReplaceDataBytes(
                with: raw.baseAddress!,
                blockBuffer: blockBuffer,
                offsetIntoDestination: 0,
                dataLength: dataLength
            )
        }
        guard replaceStatus == noErr else {
            return nil
        }

        let frameLength = pcmBuffer.frameLength
        var timing = CMSampleTimingInfo(
            duration: CMTime(
                value: CMTimeValue(frameLength),
                timescale: CMTimeScale(sampleRate)
            ),
            presentationTimeStamp: .invalid,
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        let sampleCount = CMItemCount(frameCount)
        let sampleStatus = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleCount: sampleCount,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        guard sampleStatus == noErr else {
            return nil
        }
        return sampleBuffer
    }

    static func levelFromPCMBuffer(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let data = interleavedFloatData(from: buffer), !data.isEmpty else {
            return 0
        }
        var sum: Float = 0
        for sample in data {
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(data.count))
        return min(1, rms * 8)
    }

    static func levelFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> Float? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else {
            return nil
        }

        guard asbd.pointee.mFormatFlags & kAudioFormatFlagIsFloat != 0 else {
            return nil
        }

        var audioBufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: AudioBuffer())
        var blockBuffer: CMBlockBuffer?
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: kCFAllocatorDefault,
            blockBufferMemoryAllocator: kCFAllocatorDefault,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        guard status == noErr else { return nil }

        let audioBuffer = audioBufferList.mBuffers
        guard let dataPtr = audioBuffer.mData else { return nil }
        let sampleCount = Int(audioBuffer.mDataByteSize) / MemoryLayout<Float>.size
        guard sampleCount > 0 else { return nil }

        let samples = dataPtr.bindMemory(to: Float.self, capacity: sampleCount)
        var sum: Float = 0
        for i in 0..<sampleCount {
            let sample = samples[i]
            sum += sample * sample
        }
        return min(1, sqrt(sum / Float(sampleCount)) * 8)
    }

    private static func interleavedFloatData(from buffer: AVAudioPCMBuffer) -> [Float]? {
        let channels = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)
        guard channels > 0, frameCount > 0 else { return nil }

        if buffer.format.isInterleaved,
           let data = buffer.audioBufferList.pointee.mBuffers.mData {
            let sampleCount = frameCount * channels
            let pointer = data.bindMemory(to: Float.self, capacity: sampleCount)
            return Array(UnsafeBufferPointer(start: pointer, count: sampleCount))
        }

        guard let channelData = buffer.floatChannelData else { return nil }
        var interleaved = [Float](repeating: 0, count: frameCount * channels)
        for frame in 0..<frameCount {
            for channel in 0..<channels {
                interleaved[frame * channels + channel] = channelData[channel][frame]
            }
        }
        return interleaved
    }

    private static func softLimitSample(_ sample: Float, gain: Float) -> Float {
        tanh(sample * gain)
    }

    private static func formatsMatch(_ lhs: AVAudioFormat, _ rhs: AVAudioFormat) -> Bool {
        lhs.sampleRate == rhs.sampleRate
            && lhs.channelCount == rhs.channelCount
            && lhs.commonFormat == rhs.commonFormat
            && lhs.isInterleaved == rhs.isInterleaved
    }

    static func copyPCMBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard buffer.frameLength > 0 else { return nil }
        guard let copy = AVAudioPCMBuffer(
            pcmFormat: buffer.format,
            frameCapacity: buffer.frameLength
        ) else {
            return nil
        }
        guard appendPCMBuffer(buffer, to: copy, atFrameOffset: 0) else {
            return copyViaAudioBufferListFallback(from: buffer, to: copy)
        }
        copy.frameLength = buffer.frameLength
        return copy
    }

    private static func copyViaAudioBufferListFallback(
        from source: AVAudioPCMBuffer,
        to destination: AVAudioPCMBuffer
    ) -> AVAudioPCMBuffer? {
        let frameCount = Int(source.frameLength)
        let channels = Int(source.format.channelCount)
        guard frameCount > 0, channels > 0 else { return nil }

        if source.format.isInterleaved,
           destination.format.isInterleaved,
           let srcData = source.audioBufferList.pointee.mBuffers.mData,
           let dstData = destination.mutableAudioBufferList.pointee.mBuffers.mData {
            let sampleCount = frameCount * channels
            let src = srcData.assumingMemoryBound(to: Float.self)
            let dst = dstData.assumingMemoryBound(to: Float.self)
            dst.update(from: src, count: sampleCount)
            destination.frameLength = source.frameLength
            return destination
        }

        if !source.format.isInterleaved,
           !destination.format.isInterleaved,
           source.format.channelCount == 1,
           let srcData = source.audioBufferList.pointee.mBuffers.mData,
           let dstData = destination.mutableAudioBufferList.pointee.mBuffers.mData {
            let src = srcData.assumingMemoryBound(to: Float.self)
            let dst = dstData.assumingMemoryBound(to: Float.self)
            dst.update(from: src, count: frameCount)
            destination.frameLength = source.frameLength
            return destination
        }

        return nil
    }

    private static func appendPCMBuffer(
        _ source: AVAudioPCMBuffer,
        to destination: AVAudioPCMBuffer,
        atFrameOffset: AVAudioFrameCount
    ) -> Bool {
        let frameCount = Int(source.frameLength)
        let channels = Int(source.format.channelCount)
        guard frameCount > 0, channels > 0 else { return true }

        let requiredCapacity = atFrameOffset + source.frameLength
        guard destination.frameCapacity >= requiredCapacity else { return false }

        if source.format.isInterleaved, destination.format.isInterleaved {
            guard let srcData = source.audioBufferList.pointee.mBuffers.mData,
                  let dstData = destination.mutableAudioBufferList.pointee.mBuffers.mData else {
                return false
            }
            let sampleCount = frameCount * channels
            let dstOffsetBytes = Int(atFrameOffset) * channels * MemoryLayout<Float>.size
            let src = srcData.assumingMemoryBound(to: Float.self)
            let dst = dstData.advanced(by: dstOffsetBytes).assumingMemoryBound(to: Float.self)
            dst.update(from: src, count: sampleCount)
            destination.frameLength = max(destination.frameLength, atFrameOffset + source.frameLength)
            return true
        }

        guard let srcChannels = source.floatChannelData,
              let dstChannels = destination.floatChannelData else {
            if !source.format.isInterleaved,
               !destination.format.isInterleaved,
               source.format.channelCount == 1,
               destination.format.channelCount == 1,
               let srcData = source.audioBufferList.pointee.mBuffers.mData,
               let dstData = destination.mutableAudioBufferList.pointee.mBuffers.mData {
                let dstOffsetBytes = Int(atFrameOffset) * MemoryLayout<Float>.size
                let src = srcData.assumingMemoryBound(to: Float.self)
                let dst = dstData.advanced(by: dstOffsetBytes).assumingMemoryBound(to: Float.self)
                dst.update(from: src, count: frameCount)
                destination.frameLength = max(destination.frameLength, atFrameOffset + source.frameLength)
                return true
            }
            return false
        }

        let dstStart = Int(atFrameOffset)
        for channel in 0..<channels {
            dstChannels[channel].advanced(by: dstStart).update(
                from: srcChannels[channel],
                count: frameCount
            )
        }
        destination.frameLength = max(destination.frameLength, atFrameOffset + source.frameLength)
        return true
    }
}