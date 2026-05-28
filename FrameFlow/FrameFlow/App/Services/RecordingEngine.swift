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
final class RecordingEngine {
    private(set) var isRecording = false
    private(set) var isPaused = false
    private(set) var formattedDuration = "00:00"
    private(set) var lastRecordedDurationSeconds = 0

    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var durationTimer: Timer?
    private var startDate: Date?

    /// Shared writer timeline (600 = common video timescale; audio retimed into same session).
    private let writerTimescale: CMTimeScale = 600
    private var recordingStartHostTime: CMTime = .invalid
    private var pauseStartHostTime: CMTime?
    private var totalPausedDuration: CMTime = .zero
    private var hasStartedVideoTimeline = false
    private var lastVideoPTS: CMTime = .invalid
    private var lastAudioPTS: CMTime = .invalid
    private var nextAudioTimelinePTS: CMTime?

    #if DEBUG
    private var debugTimestampLogCount = 0
    private var didLogAudioGatedUntilVideo = false
    #endif

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

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
                AVSampleRateKey: 48_000,
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

            // Video-led session clock: host time anchors on first appended video frame; audio is gated until then.
            recordingStartHostTime = .invalid
            pauseStartHostTime = nil
            totalPausedDuration = .zero
            isPaused = false
            hasStartedVideoTimeline = false
            lastVideoPTS = .invalid
            lastAudioPTS = .invalid
            nextAudioTimelinePTS = nil

            #if DEBUG
            debugTimestampLogCount = 0
            didLogAudioGatedUntilVideo = false
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
        guard isRecording, !isPaused else { return }
        isPaused = true
        pauseStartHostTime = CMClockGetTime(CMClockGetHostTimeClock())
    }

    func resumeRecording() {
        guard isRecording, isPaused, let pauseStart = pauseStartHostTime, pauseStart.isValid else { return }
        let now = CMClockGetTime(CMClockGetHostTimeClock())
        var pauseDuration = CMTimeSubtract(now, pauseStart)
        pauseDuration = CMTimeConvertScale(pauseDuration, timescale: writerTimescale, method: .default)
        totalPausedDuration = CMTimeAdd(totalPausedDuration, pauseDuration)
        pauseStartHostTime = nil
        isPaused = false
    }

    func appendFrame(ciImage: CIImage, outputSize: CGSize) throws {
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
        guard input.isReadyForMoreMediaData else { return }
        guard let pool = adaptor.pixelBufferPool else {
            throw RecordingEngineError.appendFailed
        }

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

        if !recordingStartHostTime.isValid {
            recordingStartHostTime = CMClockGetTime(CMClockGetHostTimeClock())
            hasStartedVideoTimeline = true
        }

        let pts = monotonicPresentationTime(sessionElapsedTime(), last: lastVideoPTS)
        lastVideoPTS = pts
        logTimestampDiagnosticsIfNeeded(videoPTS: pts, audioPTS: nil, audioFrameLength: nil, audioDuration: nil)

        if !adaptor.append(pixelBuffer, withPresentationTime: pts) {
            throw RecordingEngineError.appendFailed
        }
    }

    func appendAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) throws {
        guard isRecording,
              let writer,
              let audioInput else {
            throw RecordingEngineError.notRecording
        }
        guard !isPaused else { return }
        guard writer.status == .writing else {
            throw RecordingEngineError.appendFailed
        }
        guard audioInput.isReadyForMoreMediaData else { return }

        guard hasStartedVideoTimeline else {
            #if DEBUG
            if !didLogAudioGatedUntilVideo {
                didLogAudioGatedUntilVideo = true
                print("[RecordingEngine] Dropping audio until first video frame is appended.")
            }
            #endif
            return
        }

        guard let retimedBuffer = retimedAudioSampleBuffer(sampleBuffer) else { return }
        guard audioInput.append(retimedBuffer) else {
            throw RecordingEngineError.appendFailed
        }
    }

    func stop() async throws {
        guard isRecording else { throw RecordingEngineError.notRecording }
        isRecording = false
        stopDurationTimer()

        guard let writer, let input = videoInput else { return }

        input.markAsFinished()
        audioInput?.markAsFinished()

        await withCheckedContinuation { continuation in
            writer.finishWriting {
                continuation.resume()
            }
        }

        if writer.status == .failed {
            throw RecordingEngineError.finalizeFailed(
                writer.error?.localizedDescription ?? "Writer failed."
            )
        }

        if lastVideoPTS.isValid {
            lastRecordedDurationSeconds = max(0, Int(lastVideoPTS.seconds.rounded()))
        } else {
            lastRecordedDurationSeconds = currentDurationSeconds()
        }

        self.writer = nil
        self.videoInput = nil
        self.audioInput = nil
        self.pixelBufferAdaptor = nil
        self.startDate = nil

        recordingStartHostTime = .invalid
        pauseStartHostTime = nil
        totalPausedDuration = .zero
        isPaused = false
        hasStartedVideoTimeline = false
        lastVideoPTS = .invalid
        lastAudioPTS = .invalid
        nextAudioTimelinePTS = nil
    }

    /// Writer timeline position: host elapsed minus accumulated pause (and active pause while paused).
    private func activeRecordingElapsedTime() -> CMTime {
        guard recordingStartHostTime.isValid else { return .zero }
        let now = CMClockGetTime(CMClockGetHostTimeClock())
        var elapsed = CMTimeSubtract(now, recordingStartHostTime)
        elapsed = CMTimeConvertScale(elapsed, timescale: writerTimescale, method: .default)

        var effective = CMTimeSubtract(elapsed, totalPausedDuration)

        if isPaused, let pauseStart = pauseStartHostTime, pauseStart.isValid {
            var currentPause = CMTimeSubtract(now, pauseStart)
            currentPause = CMTimeConvertScale(currentPause, timescale: writerTimescale, method: .default)
            effective = CMTimeSubtract(effective, currentPause)
        }

        if CMTimeCompare(effective, .zero) < 0 { return .zero }
        return effective
    }

    /// Presentation timeline for appends (excludes paused intervals).
    private func sessionElapsedTime() -> CMTime {
        activeRecordingElapsedTime()
    }

    private func monotonicPresentationTime(_ pts: CMTime, last: CMTime) -> CMTime {
        guard last.isValid else { return pts }
        if CMTimeCompare(pts, last) > 0 { return pts }
        return CMTimeAdd(last, CMTime(value: 1, timescale: writerTimescale))
    }

    private func retimedAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
        let duration = audioBufferDuration(sampleBuffer)

        if nextAudioTimelinePTS == nil {
            nextAudioTimelinePTS = monotonicPresentationTime(sessionElapsedTime(), last: lastAudioPTS)
        }
        guard var pts = nextAudioTimelinePTS else { return nil }

        pts = monotonicPresentationTime(pts, last: lastAudioPTS)
        lastAudioPTS = pts
        nextAudioTimelinePTS = CMTimeAdd(pts, duration)

        let frameLength = CMSampleBufferGetNumSamples(sampleBuffer)
        logTimestampDiagnosticsIfNeeded(
            videoPTS: nil,
            audioPTS: pts,
            audioFrameLength: Int(frameLength),
            audioDuration: duration
        )

        var timing = CMSampleTimingInfo(
            duration: CMTimeConvertScale(duration, timescale: writerTimescale, method: .default),
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
        // Sometimes CMSampleBufferGetDuration() can be suspiciously small (e.g. 1/sampleRate),
        // which collapses the timeline and causes drift. Prefer frame-count derived duration.
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        if duration.isValid, duration.value > 0, duration.seconds >= 0.001 {
            return duration
        }

        let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
        if sampleCount > 0 {
            return CMTime(value: CMTimeValue(sampleCount), timescale: 48_000)
        }

        if duration.isValid, duration.value > 0 {
            return duration
        }

        return CMTime(value: 1, timescale: 48_000)
    }

    #if DEBUG
    private func logTimestampDiagnosticsIfNeeded(
        videoPTS: CMTime?,
        audioPTS: CMTime?,
        audioFrameLength: Int?,
        audioDuration: CMTime?
    ) {
        guard debugTimestampLogCount < 10 else { return }
        debugTimestampLogCount += 1

        let wallSeconds = sessionElapsedTime().seconds

        if let videoPTS, videoPTS.isValid {
            print(
                "[RecordingEngine] video PTS=\(String(format: "%.3f", videoPTS.seconds))s wall=\(String(format: "%.3f", wallSeconds))s"
            )
        }

        if let audioPTS, audioPTS.isValid {
            let durSeconds = (audioDuration?.seconds) ?? 0
            print(
                "[RecordingEngine] audio PTS=\(String(format: "%.3f", audioPTS.seconds))s wall=\(String(format: "%.3f", wallSeconds))s duration=\(String(format: "%.6f", durSeconds))s frames=\(audioFrameLength ?? 0)"
            )
        }
    }
    #else
    private func logTimestampDiagnosticsIfNeeded(
        videoPTS: CMTime?,
        audioPTS: CMTime?,
        audioFrameLength: Int?,
        audioDuration: CMTime?
    ) {
    }
    #endif

    func currentDurationSeconds() -> Int {
        guard isRecording else { return lastRecordedDurationSeconds }
        if recordingStartHostTime.isValid {
            return max(0, Int(activeRecordingElapsedTime().seconds.rounded()))
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
        // Conservative defaults to keep file sizes reasonable for MVP.
        let pixels = size.width * size.height
        if pixels >= 3840 * 2160 { return 28_000_000 }
        if pixels >= 1920 * 1080 { return 12_000_000 }
        return 6_000_000
    }
}

