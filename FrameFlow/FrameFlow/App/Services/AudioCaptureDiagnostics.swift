//
//  AudioCaptureDiagnostics.swift
//  FrameFlow
//

import AVFoundation
import Foundation

/// Thread-safe mic capture counters for DEBUG sync investigation.
enum AudioCaptureDiagnostics {
    private static let lock = NSLock()
    private static var tapCount = 0
    private static var copyFailCount = 0
    private static var convertFailCount = 0
    private static var makeBufferFailCount = 0
    private static var appendCount = 0
    private static var skippedNotRunningCount = 0
    private static var mixQueueEnterCount = 0
    private static var lastLogDate = Date.distantPast
    private static var sessionStartedAt: Date?
    private static var didLogConvertFail = false

    static func resetForRecording() {
        lock.lock()
        defer { lock.unlock() }
        tapCount = 0
        copyFailCount = 0
        convertFailCount = 0
        makeBufferFailCount = 0
        appendCount = 0
        skippedNotRunningCount = 0
        mixQueueEnterCount = 0
        lastLogDate = Date.distantPast
        sessionStartedAt = Date()
        didLogConvertFail = false
    }

    static func recordTap() {
        lock.lock()
        tapCount += 1
        lock.unlock()
    }

    static func recordCopyFail() {
        lock.lock()
        copyFailCount += 1
        lock.unlock()
    }

    static func recordConvertFail() {
        lock.lock()
        convertFailCount += 1
        lock.unlock()
    }

    static func logConvertFailOnce(stage: String, input: AVAudioFormat, output: AVAudioFormat) {
        lock.lock()
        let shouldLog = !didLogConvertFail
        if shouldLog {
            didLogConvertFail = true
        }
        lock.unlock()

        #if DEBUG
        guard shouldLog else { return }
        print(
            "[AudioCapture] convert fail: stage=\(stage) " +
            "in=\(Int(input.sampleRate))x\(input.channelCount) " +
            "out=\(Int(output.sampleRate))x\(output.channelCount)"
        )
        #endif
    }

    static func recordMakeBufferFail() {
        lock.lock()
        makeBufferFailCount += 1
        lock.unlock()
    }

    static func recordAppend() {
        lock.lock()
        appendCount += 1
        lock.unlock()
    }

    static func recordSkippedNotRunning() {
        lock.lock()
        skippedNotRunningCount += 1
        lock.unlock()
    }

    static func recordMixQueueEnter() {
        lock.lock()
        mixQueueEnterCount += 1
        lock.unlock()
    }

    static func snapshot() -> Snapshot {
        lock.lock()
        defer { lock.unlock() }
        let startedAt = sessionStartedAt
        let duration = startedAt.map { Date().timeIntervalSince($0) } ?? 0
        return Snapshot(
            tapCount: tapCount,
            copyFailCount: copyFailCount,
            convertFailCount: convertFailCount,
            makeBufferFailCount: makeBufferFailCount,
            appendCount: appendCount,
            skippedNotRunningCount: skippedNotRunningCount,
            mixQueueEnterCount: mixQueueEnterCount,
            sessionDurationSeconds: duration
        )
    }

    #if DEBUG
    static func logPeriodicIfNeeded() {
        let now = Date()
        lock.lock()
        let shouldLog = now.timeIntervalSince(lastLogDate) >= 1.0
        if shouldLog {
            lastLogDate = now
        }
        let snap = Snapshot(
            tapCount: tapCount,
            copyFailCount: copyFailCount,
            convertFailCount: convertFailCount,
            makeBufferFailCount: makeBufferFailCount,
            appendCount: appendCount,
            skippedNotRunningCount: skippedNotRunningCount,
            mixQueueEnterCount: mixQueueEnterCount,
            sessionDurationSeconds: sessionStartedAt.map { now.timeIntervalSince($0) } ?? 0
        )
        lock.unlock()

        guard shouldLog else { return }
        print(
            "[AudioCapture] taps=\(snap.tapCount) appends=\(snap.appendCount) " +
            "copyFail=\(snap.copyFailCount) convertFail=\(snap.convertFailCount) " +
            "makeFail=\(snap.makeBufferFailCount) skipped=\(snap.skippedNotRunningCount)"
        )
    }

    static func logStopSummaryIfNeeded() {
        let snap = snapshot()
        guard snap.tapCount > 0 || snap.appendCount > 0 else { return }

        let tapsPerSecond = snap.sessionDurationSeconds > 0
            ? Double(snap.tapCount) / snap.sessionDurationSeconds
            : 0
        let expectedTapsPerSecond = 48_000.0 / 4096.0

        print(
            "[AudioCapture] stop summary: taps=\(snap.tapCount) appends=\(snap.appendCount) " +
            "mixQueueEnter=\(snap.mixQueueEnterCount) " +
            "tapsPerSec=\(String(format: "%.1f", tapsPerSecond)) " +
            "expected≈\(String(format: "%.1f", expectedTapsPerSecond)) " +
            "copyFail=\(snap.copyFailCount) convertFail=\(snap.convertFailCount) " +
            "makeFail=\(snap.makeBufferFailCount) skipped=\(snap.skippedNotRunningCount)"
        )
        if snap.copyFailCount > 0 || snap.convertFailCount > 0 || snap.makeBufferFailCount > 0 {
            print(
                "[AudioCapture] WARNING: mic capture failures detected " +
                "(copyFail=\(snap.copyFailCount), convertFail=\(snap.convertFailCount), " +
                "makeFail=\(snap.makeBufferFailCount))"
            )
        }
    }
    #else
    static func logPeriodicIfNeeded() {}
    static func logStopSummaryIfNeeded() {}
    #endif

    struct Snapshot {
        let tapCount: Int
        let copyFailCount: Int
        let convertFailCount: Int
        let makeBufferFailCount: Int
        let appendCount: Int
        let skippedNotRunningCount: Int
        let mixQueueEnterCount: Int
        let sessionDurationSeconds: TimeInterval
    }
}
