//
//  RecordingEngine.swift
//  FrameFlow
//

import AVFoundation
import CoreGraphics
import CoreImage
import CoreMedia
import CoreVideo
import Foundation

enum RecordingEngineError: LocalizedError {
    case notRecording
    case alreadyRecording
    case writerSetupFailed(String)
    case appendFailed
    case finalizeFailed(String)
    case moveFailed(String)

    var errorDescription: String? {
        switch self {
        case .notRecording:
            "Recording is not running."
        case .alreadyRecording:
            "Recording is already running."
        case .writerSetupFailed(let message):
            message
        case .appendFailed:
            "Could not append a video frame."
        case .finalizeFailed(let message):
            message
        case .moveFailed(let message):
            message
        }
    }
}

@MainActor
@Observable
final class RecordingEngine: @unchecked Sendable {
    /// Must match `RecordingSessionCoordinator.recordFrameRate`.
    static let videoFrameRate: Int32 = 24
    static let audioSampleRate: Int32 = 48_000
    /// Max video lead over audio sample timeline when duplicating frames.
    private static let audioMasterLead = CMTime(value: 50, timescale: 1000)

    private(set) var isRecording = false
    private(set) var isPaused = false
    private(set) var formattedDuration = "00:00"
    private(set) var lastRecordedDurationSeconds = 0

    /// Serializes all writer appends and timeline mutations (safe from mic tap thread).
    private let writerQueue = DispatchQueue(label: "com.Simranjit.FrameFlow.recording.writer", qos: .userInitiated)

    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var durationTimer: Timer?
    private var startDate: Date?

    /// Video PTS follows audio sample timeline; frameIndex counts appends for diagnostics.
    private var videoFrameIndex: Int64 = 0
    private var hasStartedMediaTimeline = false
    private var lastVideoPTS: CMTime = .invalid
    private var lastAudioPTS: CMTime = .invalid
    private var nextAudioSamplePTS: CMTime?
    private var pendingAudioBuffers: [CMSampleBuffer] = []

    #if DEBUG
    private var didLogWaitingForFirstAudio = false
    private var audioDropNotReadyCount = 0
    private var audioQueuedCount = 0
    private var videoSkipNotReadyCount = 0
    private var duplicateFrameCount = 0
    private var maxPendingAudioDepth = 0
    private var lastPeriodicLogDate = Date.distantPast
    #endif

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private static let maxPendingAudioBuffers = 256

    func start(outputURL: URL, outputSize: CGSize) throws {
        guard !isRecording else { throw RecordingEngineError.alreadyRecording }
        try? FileManager.default.removeItem(at: outputURL)

        do {
            let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(outputSize.width),
                AVVideoHeightKey: Int(outputSize.height),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: suggestedBitrate(for: outputSize),
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                    AVVideoAllowFrameReorderingKey: false,
                ],
            ]

            let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            input.expectsMediaDataInRealTime = true

            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: Self.audioSampleRate,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128_000,
            ]
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput.expectsMediaDataInRealTime = true

            let sourceAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: Int(outputSize.width),
                kCVPixelBufferHeightKey as String: Int(outputSize.height),
                kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            ]

            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: sourceAttributes
            )

            guard writer.canAdd(input) else {
                throw RecordingEngineError.writerSetupFailed("Cannot add video input to writer.")
            }
            writer.add(input)
            guard writer.canAdd(audioInput) else {
                throw RecordingEngineError.writerSetupFailed("Cannot add audio input to writer.")
            }
            writer.add(audioInput)

            self.writer = writer
            self.videoInput = input
            self.audioInput = audioInput
            self.pixelBufferAdaptor = adaptor

            isPaused = false
            hasStartedMediaTimeline = false
            videoFrameIndex = 0
            lastVideoPTS = .invalid
            lastAudioPTS = .invalid
            nextAudioSamplePTS = nil
            pendingAudioBuffers.removeAll()

            #if DEBUG
            didLogWaitingForFirstAudio = false
            audioDropNotReadyCount = 0
            audioQueuedCount = 0
            videoSkipNotReadyCount = 0
            duplicateFrameCount = 0
            maxPendingAudioDepth = 0
            lastPeriodicLogDate = Date.distantPast
            #endif

            guard writer.startWriting() else {
                throw RecordingEngineError.writerSetupFailed(
                    writer.error?.localizedDescription ?? "Failed to start writing."
                )
            }
            writer.startSession(atSourceTime: .zero)

            isRecording = true
            startDate = Date()
            formattedDuration = "00:00"
            startDurationTimer()
        } catch {
            throw RecordingEngineError.writerSetupFailed(error.localizedDescription)
        }
    }

    func pauseRecording() {
        writerQueue.sync {
            guard isRecording, !isPaused else { return }
            isPaused = true
        }
    }

    func resumeRecording() {
        writerQueue.sync {
            guard isRecording, isPaused else { return }
            isPaused = false
        }
    }

    func appendFrame(ciImage: CIImage, outputSize: CGSize) throws {
        try performOnWriterQueue {
            try self.drainPendingAudioBuffersOnWriterQueue()
            try self.appendFrameOnWriterQueue(ciImage: ciImage, outputSize: outputSize)
        }
    }

    func appendAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer, captureHostTime: CMTime) throws {
        try performOnWriterQueue {
            try self.enqueueOrAppendAudioOnWriterQueue(sampleBuffer: sampleBuffer)
        }
    }

    func stop() async throws {
        guard isRecording else { throw RecordingEngineError.notRecording }

        let finalize: (AVAssetWriter, AVAssetWriterInput, CMTime?) = try performOnWriterQueue {
            isRecording = false

            #if DEBUG
            let audioSnap = AudioCaptureDiagnostics.snapshot()
            let videoSeconds = self.lastVideoPTS.isValid ? self.lastVideoPTS.seconds : 0
            let audioSeconds = self.currentAudioEndPTSOnWriterQueue().seconds
            let recordingDuration = self.startDate.map { Date().timeIntervalSince($0) } ?? 0
            let tapsPerSec = recordingDuration > 0 ? Double(audioSnap.tapCount) / recordingDuration : 0
            print(
                "[RecordingEngine] stop summary: frames=\(self.videoFrameIndex) " +
                "videoSkips=\(self.videoSkipNotReadyCount) duplicateFrames=\(self.duplicateFrameCount) " +
                "audioNotReady=\(self.audioDropNotReadyCount) audioEnqueued=\(self.audioQueuedCount) " +
                "maxPendingAudio=\(self.maxPendingAudioDepth) " +
                "lastVideoPTS=\(String(format: "%.3f", videoSeconds))s " +
                "lastAudioPTS=\(String(format: "%.3f", audioSeconds))s " +
                "Δ=\(String(format: "%+.0f", (audioSeconds - videoSeconds) * 1000))ms " +
                "micTaps=\(audioSnap.tapCount) micAppends=\(audioSnap.appendCount) " +
                "tapsPerSec=\(String(format: "%.1f", tapsPerSec))"
            )
            #endif

            pendingAudioBuffers.removeAll()

            guard let writer = self.writer, let input = self.videoInput else {
                throw RecordingEngineError.notRecording
            }

            input.markAsFinished()
            self.audioInput?.markAsFinished()

            let lastPTS = self.lastVideoPTS.isValid ? self.lastVideoPTS : nil
            return (writer, input, lastPTS)
        }

        stopDurationTimer()

        await withCheckedContinuation { continuation in
            finalize.0.finishWriting {
                continuation.resume()
            }
        }

        if finalize.0.status == .failed {
            throw RecordingEngineError.finalizeFailed(
                finalize.0.error?.localizedDescription ?? "Writer failed."
            )
        }

        if let lastPTS = finalize.2 {
            lastRecordedDurationSeconds = max(0, Int(lastPTS.seconds.rounded()))
        } else {
            lastRecordedDurationSeconds = currentDurationSeconds()
        }

        writer = nil
        videoInput = nil
        audioInput = nil
        pixelBufferAdaptor = nil
        startDate = nil

        writerQueue.sync {
            isPaused = false
            hasStartedMediaTimeline = false
            videoFrameIndex = 0
            lastVideoPTS = .invalid
            lastAudioPTS = .invalid
            nextAudioSamplePTS = nil
        }
    }

    // MARK: - Writer queue

    private func performOnWriterQueue<T>(_ work: () throws -> T) throws -> T {
        var outcome: Result<T, Error>?
        writerQueue.sync {
            outcome = Result { try work() }
        }
        return try outcome!.get()
    }

    private func appendFrameOnWriterQueue(ciImage: CIImage, outputSize: CGSize) throws {
        guard isRecording,
              let writer,
              let input = videoInput,
              let adaptor = pixelBufferAdaptor else {
            throw RecordingEngineError.notRecording
        }
        guard !isPaused else { return }
        guard writer.status == .writing else {
            throw RecordingEngineError.appendFailed
        }
        guard input.isReadyForMoreMediaData else {
            #if DEBUG
            videoSkipNotReadyCount += 1
            logPeriodicSyncDiagnosticsIfNeeded()
            #endif
            return
        }
        guard let pool = adaptor.pixelBufferPool else {
            throw RecordingEngineError.appendFailed
        }

        let audioEnd = currentAudioEndPTSOnWriterQueue()
        guard CMTimeCompare(audioEnd, .zero) > 0 else {
            #if DEBUG
            if !didLogWaitingForFirstAudio {
                didLogWaitingForFirstAudio = true
                print("[RecordingEngine] Waiting for first audio buffer before video append.")
            }
            #endif
            return
        }

        let pts = videoPresentationTimeOnWriterQueue(audioEnd: audioEnd)

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer else {
            throw RecordingEngineError.appendFailed
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        ciContext.render(
            ciImage,
            to: pixelBuffer,
            bounds: CGRect(origin: .zero, size: outputSize),
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        if !adaptor.append(pixelBuffer, withPresentationTime: pts) {
            throw RecordingEngineError.appendFailed
        }

        videoFrameIndex += 1
        lastVideoPTS = pts
        hasStartedMediaTimeline = true

        #if DEBUG
        logPeriodicSyncDiagnosticsIfNeeded()
        #endif
    }

    private func enqueueOrAppendAudioOnWriterQueue(sampleBuffer: CMSampleBuffer) throws {
        guard isRecording,
              let writer,
              audioInput != nil else {
            throw RecordingEngineError.notRecording
        }
        guard !isPaused else { return }
        guard writer.status == .writing else {
            throw RecordingEngineError.appendFailed
        }

        pendingAudioBuffers.append(sampleBuffer)
        #if DEBUG
        maxPendingAudioDepth = max(maxPendingAudioDepth, pendingAudioBuffers.count)
        audioQueuedCount += 1
        #endif
        if pendingAudioBuffers.count > Self.maxPendingAudioBuffers {
            pendingAudioBuffers.removeFirst()
            #if DEBUG
            audioDropNotReadyCount += 1
            #endif
        }
        try drainPendingAudioBuffersOnWriterQueue()
        #if DEBUG
        logPeriodicSyncDiagnosticsIfNeeded()
        #endif
    }

    private func drainPendingAudioBuffersOnWriterQueue() throws {
        guard let audioInput else { return }

        while !pendingAudioBuffers.isEmpty {
            guard audioInput.isReadyForMoreMediaData else {
                #if DEBUG
                audioDropNotReadyCount += 1
                #endif
                break
            }

            let sampleBuffer = pendingAudioBuffers.removeFirst()
            guard let retimedBuffer = retimedAudioSampleBuffer(sampleBuffer) else {
                continue
            }
            guard audioInput.append(retimedBuffer) else {
                throw RecordingEngineError.appendFailed
            }
        }
    }

    /// Sample-count audio timeline: each buffer follows the previous by its duration (handles HAL dropouts).
    private func retimedAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
        let duration = audioBufferDuration(sampleBuffer)

        if nextAudioSamplePTS == nil {
            nextAudioSamplePTS = .zero
            hasStartedMediaTimeline = true
        }
        guard var pts = nextAudioSamplePTS else { return nil }

        pts = monotonicPresentationTime(pts, last: lastAudioPTS)
        lastAudioPTS = pts
        nextAudioSamplePTS = CMTimeAdd(pts, duration)

        var timing = CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: pts,
            decodeTimeStamp: .invalid
        )

        var retimed: CMSampleBuffer?
        let status = CMSampleBufferCreateCopyWithNewTiming(
            allocator: kCFAllocatorDefault,
            sampleBuffer: sampleBuffer,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleBufferOut: &retimed
        )
        guard status == noErr else { return nil }
        return retimed
    }

    private func audioBufferDuration(_ sampleBuffer: CMSampleBuffer) -> CMTime {
        let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
        if sampleCount > 0 {
            return CMTime(value: CMTimeValue(sampleCount), timescale: Self.audioSampleRate)
        }

        let duration = CMSampleBufferGetDuration(sampleBuffer)
        if duration.isValid, duration.value > 0 {
            return duration
        }

        return CMTime(value: 1, timescale: Self.audioSampleRate)
    }

    private func monotonicPresentationTime(_ pts: CMTime, last: CMTime) -> CMTime {
        guard last.isValid else { return pts }
        if CMTimeCompare(pts, last) > 0 { return pts }
        return CMTimeAdd(last, CMTime(value: 1, timescale: Self.audioSampleRate))
    }

    private func currentAudioEndPTSOnWriterQueue() -> CMTime {
        if let next = nextAudioSamplePTS, next.isValid {
            return next
        }
        if lastAudioPTS.isValid {
            return lastAudioPTS
        }
        return .zero
    }

    /// Audio-master PTS: follow `audioEnd`, duplicate with +1/frame when audio hasn't advanced.
    private func videoPresentationTimeOnWriterQueue(audioEnd: CMTime) -> CMTime {
        let frameStep = CMTime(value: 1, timescale: Self.videoFrameRate)
        let maxPTS = CMTimeAdd(audioEnd, Self.audioMasterLead)

        var pts = audioEnd
        if lastVideoPTS.isValid, CMTimeCompare(pts, lastVideoPTS) <= 0 {
            pts = CMTimeAdd(lastVideoPTS, frameStep)
            #if DEBUG
            duplicateFrameCount += 1
            #endif
        }

        if CMTimeCompare(pts, maxPTS) > 0 {
            pts = maxPTS
            if lastVideoPTS.isValid, CMTimeCompare(pts, lastVideoPTS) <= 0 {
                pts = CMTimeAdd(lastVideoPTS, frameStep)
                #if DEBUG
                duplicateFrameCount += 1
                #endif
            }
        }

        return pts
    }

    #if DEBUG
    private func logPeriodicSyncDiagnosticsIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastPeriodicLogDate) >= 1.0 else { return }
        lastPeriodicLogDate = now

        let videoSeconds = lastVideoPTS.isValid ? lastVideoPTS.seconds : 0
        let audioSeconds = currentAudioEndPTSOnWriterQueue().seconds
        let avDeltaMs = (audioSeconds - videoSeconds) * 1000
        let audioSnap = AudioCaptureDiagnostics.snapshot()

        print(
            "[RecordingEngine] sync @ \(String(format: "%.1f", videoSeconds))s " +
            "frameIndex=\(videoFrameIndex) videoPTS=\(String(format: "%.3f", videoSeconds))s " +
            "audioEnd=\(String(format: "%.3f", audioSeconds))s " +
            "Δ=\(String(format: "%+.0f", avDeltaMs))ms " +
            "pendingAudio=\(pendingAudioBuffers.count) videoSkips=\(videoSkipNotReadyCount) " +
            "duplicateFrames=\(duplicateFrameCount) " +
            "micTaps=\(audioSnap.tapCount) micAppends=\(audioSnap.appendCount)"
        )
    }
    #endif

    func currentDurationSeconds() -> Int {
        guard isRecording else { return lastRecordedDurationSeconds }
        let elapsed = writerQueue.sync {
            let videoSec = lastVideoPTS.isValid ? lastVideoPTS.seconds : 0
            let audioSec = currentAudioEndPTSOnWriterQueue().seconds
            return min(videoSec, audioSec > 0 ? audioSec : videoSec)
        }
        if elapsed > 0 {
            return max(0, Int(elapsed.rounded()))
        }
        guard let startDate else { return lastRecordedDurationSeconds }
        return max(0, Int(Date().timeIntervalSince(startDate).rounded()))
    }

    private func startDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.formattedDuration = Self.formatDuration(self.currentDurationSeconds())
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    private static func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }

    private func suggestedBitrate(for size: CGSize) -> Int {
        let pixels = size.width * size.height
        if pixels >= 3840 * 2160 { return 28_000_000 }
        if pixels >= 1920 * 1080 { return 12_000_000 }
        return 6_000_000
    }
}

extension RecordingEngine {
    func appendAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) throws {
        try appendAudioSampleBuffer(sampleBuffer, captureHostTime: .invalid)
    }
}
