//
//  AudioCaptureService.swift
//  FrameFlow
//

import AVFoundation
import CoreMedia
import Foundation

@MainActor
@Observable
final class AudioCaptureService {
    private(set) var liveLevel: Float = 0
    private(set) var statusMessage: String?
    private(set) var isRunning = false

    private var audioEngine: AVAudioEngine?
    private var audioMode: AudioModeOption = .none
    private var micVolume: Float = 1.0
    private var systemVolume: Float = 1.0
    private var appendSampleBuffer: ((CMSampleBuffer) -> Void)?
    private var nextAudioFrame: Int64 = 0
    private var systemBufferCount = 0

    private let sampleRate: Double = 48_000
    private let mixQueue = DispatchQueue(label: "com.Simranjit.FrameFlow.audio.capture", qos: .userInitiated)

    func start(
        mode: AudioModeOption,
        micVolume: Float,
        systemVolume: Float,
        preferredMicDeviceUniqueID: String?,
        appendSampleBuffer: @escaping (CMSampleBuffer) -> Void
    ) async {
        stop()

        self.audioMode = mode
        self.micVolume = max(0, micVolume)
        self.systemVolume = max(0, systemVolume)
        self.appendSampleBuffer = appendSampleBuffer
        self.nextAudioFrame = 0
        self.systemBufferCount = 0
        self.statusMessage = nil
        self.liveLevel = 0

        guard mode != .none else {
            isRunning = true
            return
        }

        if includesMic {
            await startMicrophoneCapture(preferredMicDeviceUniqueID: preferredMicDeviceUniqueID)
        }

        // System audio arrives from ScreenCaptureKit through `ingestSystemAudioSampleBuffer`.
        isRunning = true
    }

    func stop() {
        if let audioEngine {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        audioEngine = nil
        appendSampleBuffer = nil
        isRunning = false
        liveLevel = 0
    }

    func ingestSystemAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isRunning, includesSystem else { return }
        systemBufferCount += 1

        if systemBufferCount == 1 {
            statusMessage = "System audio stream detected."
        }

        // Best-effort live level from raw system sample buffer.
        if let level = AudioMixerEngine.levelFromSampleBuffer(sampleBuffer) {
            Task { @MainActor in
                self.liveLevel = max(self.liveLevel * 0.7, min(1, level * max(0.05, self.systemVolume)))
            }
        }

        appendSampleBuffer?(sampleBuffer)
    }

    private var includesMic: Bool {
        audioMode == .mic || audioMode == .combined
    }

    private var includesSystem: Bool {
        audioMode == .system || audioMode == .combined
    }

    private func startMicrophoneCapture(preferredMicDeviceUniqueID: String?) async {
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
            // Avoid changing global default input during active recording.
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let canonicalFormat = AudioMixerEngine.canonicalPCMFormat(sampleRate: sampleRate)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            self.mixQueue.async {
                guard self.isRunning else { return }
                guard let converted = AudioMixerEngine.convert(
                    buffer: buffer,
                    to: canonicalFormat
                ) else {
                    return
                }

                let level = AudioMixerEngine.levelFromPCMBuffer(converted) * max(0.05, self.micVolume)
                Task { @MainActor in
                    self.liveLevel = self.liveLevel * 0.65 + min(1, level) * 0.35
                }

                guard let sampleBuffer = AudioMixerEngine.makeSampleBuffer(
                    from: converted,
                    presentationFrame: self.nextAudioFrame,
                    sampleRate: self.sampleRate,
                    gain: self.micVolume
                ) else {
                    return
                }

                self.nextAudioFrame += Int64(converted.frameLength)
                Task { @MainActor in
                    self.appendSampleBuffer?(sampleBuffer)
                }
            }
        }

        do {
            engine.prepare()
            try engine.start()
            self.audioEngine = engine
        } catch {
            statusMessage = "Could not start microphone capture. Recording will continue with available audio sources."
        }
    }
}

enum AudioMixerEngine {
    static func canonicalPCMFormat(sampleRate: Double) -> AVAudioFormat {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 2,
            interleaved: true
        )!
    }

    static func convert(buffer: AVAudioPCMBuffer, to outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        if buffer.format == outputFormat {
            return buffer
        }

        guard let converter = AVAudioConverter(from: buffer.format, to: outputFormat) else {
            return nil
        }

        let ratio = outputFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(max(1, Int(Double(buffer.frameLength) * ratio + 16)))
        guard let converted = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
            return nil
        }

        var hasProvidedInput = false
        var conversionError: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            if hasProvidedInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            hasProvidedInput = true
            outStatus.pointee = .haveData
            return buffer
        }

        let status = converter.convert(to: converted, error: &conversionError, withInputFrom: inputBlock)
        guard status == .haveData || status == .inputRanDry else {
            return nil
        }
        return converted
    }

    static func makeSampleBuffer(
        from pcmBuffer: AVAudioPCMBuffer,
        presentationFrame: Int64,
        sampleRate: Double,
        gain: Float
    ) -> CMSampleBuffer? {
        guard let data = interleavedFloatData(from: pcmBuffer) else {
            return nil
        }

        var scaled = data
        if gain != 1 {
            for i in 0..<scaled.count {
                scaled[i] *= gain
            }
        }

        let streamDescription = pcmBuffer.format.streamDescription

        var formatDescription: CMAudioFormatDescription?
        let formatStatus = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: streamDescription,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        guard formatStatus == noErr, let formatDescription else {
            return nil
        }

        let dataLength = scaled.count * MemoryLayout<Float>.size
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
            // IMPORTANT: duration must match `frameLength/sampleRate` so RecordingEngine can retime accurately.
            duration: CMTime(
                value: CMTimeValue(frameLength),
                timescale: CMTimeScale(sampleRate)
            ),
            presentationTimeStamp: CMTime(
                value: presentationFrame,
                timescale: CMTimeScale(sampleRate)
            ),
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        let sampleCount = CMItemCount(pcmBuffer.frameLength)
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
}
