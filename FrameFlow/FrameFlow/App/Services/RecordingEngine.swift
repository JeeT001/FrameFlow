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

    private nonisolated(unsafe) var writerAudioSampleRate: Double = 48_000

    private(set) nonisolated(unsafe) var isRecording = false
    private(set) nonisolated(unsafe) var isPaused = false
    private(set) var formattedDuration = "00:00"
    private(set) var lastRecordedDurationSeconds = 0

    /// Serializes all writer appends and timeline mutations (safe from mic tap thread).
    private let writerQueue = DispatchQueue(label: "com.Simranjit.FrameFlow.recording.writer", qos: .userInitiated)

    /// Writer-queue state — accessed only inside `writerQueue.sync` (mic thread uses nonisolated append path).
    private nonisolated(unsafe) var writer: AVAssetWriter?
    private nonisolated(unsafe) var videoInput: AVAssetWriterInput?
    private nonisolated(unsafe) var audioInput: AVAssetWriterInput?
    private nonisolated(unsafe) var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var durationTimer: Timer?
    private var startDate: Date?

    /// Video PTS follows audio sample timeline; frameIndex counts appends for diagnostics.
    private nonisolated(unsafe) var videoFrameIndex: Int64 = 0
    private nonisolated(unsafe) var hasStartedMediaTimeline = false
    private nonisolated(unsafe) var lastVideoPTS: CMTime = .invalid
    private nonisolated(unsafe) var lastAudioPTS: CMTime = .invalid
    private nonisolated(unsafe) var nextAudioSamplePTS: CMTime?
    private nonisolated(unsafe) var pendingAudioBuffers: [CMSampleBuffer] = []
    private nonisolated(unsafe) var waitForAudioBeforeVideo = true
    private nonisolated(unsafe) var expectsMicAudio = false
    private nonisolated(unsafe) var videoOnlyFallbackActive = false
    private nonisolated(unsafe) var firstVideoAppendAttemptDate: Date?
    private static let videoOnlyFallbackDelay: TimeInterval = 1.0

    #if DEBUG
    private nonisolated(unsafe) var didLogWaitingForFirstAudio = false
    private nonisolated(unsafe) var audioDropNotReadyCount = 0
    private nonisolated(unsafe) var audioQueuedCount = 0
    private nonisolated(unsafe) var audioWriterAppends = 0
    private nonisolated(unsafe) var videoSkipNotReadyCount = 0
    private nonisolated(unsafe) var duplicateFrameCount = 0
    private nonisolated(unsafe) var maxPendingAudioDepth = 0
    private nonisolated(unsafe) var lastPeriodicLogDate = Date.distantPast
    #endif

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private static let maxPendingAudioBuffers = 256

    func start(outputURL: URL, outputSize: CGSize, audioSampleRate: Double = 48_000) throws {
        guard !isRecording else { throw RecordingEngineError.alreadyRecording }
        try? FileManager.default.removeItem(at: outputURL)

        writerAudioSampleRate = audioSampleRate
        let writerAudioRate = Int(audioSampleRate.rounded())

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
                AVSampleRateKey: writerAudioRate,
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
            waitForAudioBeforeVideo = true
            expectsMicAudio = false
            videoOnlyFallbackActive = false
            firstVideoAppendAttemptDate = nil

            #if DEBUG
            didLogWaitingForFirstAudio = false
            audioDropNotReadyCount = 0
            audioQueuedCount = 0
            audioWriterAppends = 0
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

    func configureAudioTimeline(waitForAudioBeforeVideo: Bool) {
        writerQueue.sync {
            self.waitForAudioBeforeVideo = waitForAudioBeforeVideo
            self.expectsMicAudio = waitForAudioBeforeVideo
            if waitForAudioBeforeVideo {
                self.videoOnlyFallbackActive = false
                self.firstVideoAppendAttemptDate = nil
            }
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
        let pool: CVPixelBufferPool? = try performOnWriterQueue {
            guard self.isRecording,
                  let writer = self.writer,
                  let adaptor = self.pixelBufferAdaptor,
                  let pool = adaptor.pixelBufferPool else {
                throw RecordingEngineError.notRecording
            }
            guard !self.isPaused, writer.status == .writing else { return nil }

            if self.firstVideoAppendAttemptDate == nil {
                self.firstVideoAppendAttemptDate = Date()
            }
            self.updateVideoOnlyFallbackIfNeededOnWriterQueue()

            if self.shouldWaitForAudioOnWriterQueue() {
                guard CMTimeCompare(self.currentAudioEndPTSOnWriterQueue(), .zero) > 0 else {
                    #if DEBUG
                    if !self.didLogWaitingForFirstAudio {
                        self.didLogWaitingForFirstAudio = true
                        print("[RecordingEngine] Waiting for first audio buffer before video append.")
                    }
                    #endif
                    return nil
                }
            }
            return pool
        }

        guard let pool else { return }

        var pixelBuffer: CVPixelBuffer?
        let poolStatus = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
        guard poolStatus == kCVReturnSuccess, let pixelBuffer else {
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

        try performOnWriterQueue {
            try self.drainPendingAudioBuffersOnWriterQueue()
            try self.appendPreparedPixelBufferOnWriterQueue(pixelBuffer)
        }
    }

    nonisolated func appendAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer, captureHostTime: CMTime) throws {
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
                "audioWriterAppends=\(self.audioWriterAppends) " +
                "maxPendingAudio=\(self.maxPendingAudioDepth) " +
                "lastVideoPTS=\(String(format: "%.3f", videoSeconds))s " +
                "lastAudioPTS=\(String(format: "%.3f", audioSeconds))s " +
                "Δ=\(String(format: "%+.0f", (audioSeconds - videoSeconds) * 1000))ms " +
                "micTaps=\(audioSnap.tapCount) micAppends=\(audioSnap.appendCount) " +
                "convertFail=\(audioSnap.convertFailCount) makeFail=\(audioSnap.makeBufferFailCount) " +
                "tapsPerSec=\(String(format: "%.1f", tapsPerSec))"
            )
            if self.expectsMicAudio && self.audioWriterAppends == 0 {
                print(
                    "[RecordingEngine] WARNING: mic expected but no audio samples written to writer " +
                    "(micAppends=\(audioSnap.appendCount), convertFail=\(audioSnap.convertFailCount))"
                )
            }
            if self.audioDropNotReadyCount > 0
                || audioSnap.convertFailCount > 0
                || self.maxPendingAudioDepth > 32 {
                print(
                    "[RecordingEngine] WARNING: audio backpressure detected " +
                    "(audioNotReady=\(self.audioDropNotReadyCount), " +
                    "maxPendingAudio=\(self.maxPendingAudioDepth), " +
                    "convertFail=\(audioSnap.convertFailCount))"
                )
            }
            if self.videoFrameIndex == 0 {
                print(
                    "[RecordingEngine] ERROR: no video frames written — check audio convert path " +
                    "(convertFail=\(audioSnap.convertFailCount), micAppends=\(audioSnap.appendCount))"
                )
            }
            #endif

            while !pendingAudioBuffers.isEmpty {
                let pendingBefore = pendingAudioBuffers.count
                try drainPendingAudioBuffersOnWriterQueue()
                if pendingAudioBuffers.isEmpty {
                    break
                }
                if pendingAudioBuffers.count == pendingBefore {
                    break
                }
            }

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

    nonisolated private func performOnWriterQueue<T>(_ work: () throws -> T) throws -> T {
        var outcome: Result<T, Error>?
        writerQueue.sync {
            outcome = Result { try work() }
        }
        return try outcome!.get()
    }

    private func appendPreparedPixelBufferOnWriterQueue(_ pixelBuffer: CVPixelBuffer) throws {
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

        updateVideoOnlyFallbackIfNeededOnWriterQueue()

        let audioEnd = currentAudioEndPTSOnWriterQueue()
        let pts: CMTime
        if CMTimeCompare(audioEnd, .zero) > 0 {
            pts = videoPresentationTimeOnWriterQueue(audioEnd: audioEnd)
        } else if !waitForAudioBeforeVideo || videoOnlyFallbackActive {
            pts = CMTime(value: videoFrameIndex, timescale: Self.videoFrameRate)
            hasStartedMediaTimeline = true
        } else {
            return
        }

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

    private func shouldWaitForAudioOnWriterQueue() -> Bool {
        waitForAudioBeforeVideo && !videoOnlyFallbackActive
    }

    private func updateVideoOnlyFallbackIfNeededOnWriterQueue() {
        guard waitForAudioBeforeVideo,
              !videoOnlyFallbackActive,
              CMTimeCompare(currentAudioEndPTSOnWriterQueue(), .zero) <= 0,
              let firstAttempt = firstVideoAppendAttemptDate,
              Date().timeIntervalSince(firstAttempt) >= Self.videoOnlyFallbackDelay else {
            return
        }
        videoOnlyFallbackActive = true
        #if DEBUG
        print(
            "[RecordingEngine] WARNING: no audio after \(Self.videoOnlyFallbackDelay)s — " +
            "using video-only timeline fallback."
        )
        #endif
    }

    nonisolated private func enqueueOrAppendAudioOnWriterQueue(sampleBuffer: CMSampleBuffer) throws {
        guard self.isRecording,
              let writer = self.writer,
              self.audioInput != nil else {
            throw RecordingEngineError.notRecording
        }
        guard !self.isPaused else { return }
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

    nonisolated private func drainPendingAudioBuffersOnWriterQueue() throws {
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
            #if DEBUG
            audioWriterAppends += 1
            #endif
        }
    }

    /// Sample-count audio timeline: each buffer follows the previous by its duration (handles HAL dropouts).
    nonisolated private func retimedAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
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

    nonisolated private func audioBufferDuration(_ sampleBuffer: CMSampleBuffer) -> CMTime {
        let sampleRate = CMTimeScale(writerAudioSampleRate.rounded())
        let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
        if sampleCount > 0 {
            return CMTime(value: CMTimeValue(sampleCount), timescale: sampleRate)
        }

        let duration = CMSampleBufferGetDuration(sampleBuffer)
        if duration.isValid, duration.value > 0 {
            return duration
        }

        return CMTime(value: 1, timescale: sampleRate)
    }

    nonisolated private func monotonicPresentationTime(_ pts: CMTime, last: CMTime) -> CMTime {
        let sampleRate = CMTimeScale(writerAudioSampleRate.rounded())
        guard last.isValid else { return pts }
        if CMTimeCompare(pts, last) > 0 { return pts }
        return CMTimeAdd(last, CMTime(value: 1, timescale: sampleRate))
    }

    nonisolated private func currentAudioEndPTSOnWriterQueue() -> CMTime {
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
    nonisolated private func logPeriodicSyncDiagnosticsIfNeeded() {
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
    nonisolated func appendAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) throws {
        try appendAudioSampleBuffer(sampleBuffer, captureHostTime: .invalid)
    }
}
