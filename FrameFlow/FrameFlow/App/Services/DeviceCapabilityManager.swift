//
//  DeviceCapabilityManager.swift
//  FrameFlow
//

import Foundation

/// MVP hardware capability defaults used for UI limits and recording caps in later phases.
/// Values are conservative on Intel to avoid overload during composite capture and export.
final class DeviceCapabilityManager {
    static let shared = DeviceCapabilityManager()

    let isAppleSilicon: Bool

    var maxWindows: Int {
        isAppleSilicon ? 4 : 2
    }

    var supports4K: Bool {
        isAppleSilicon
    }

    /// Layout Picker live preview — smooth SCStream delivery.
    var compositeFrameRate: Int {
        isAppleSilicon ? 60 : 30
    }

    /// Active recording capture — ≥ `RecordingEngine.videoFrameRate`, below layout-preview max.
    var recordingCaptureFrameRate: Int {
        isAppleSilicon ? 30 : 24
    }

    private init() {
        isAppleSilicon = Self.detectAppleSilicon()
    }

    private static func detectAppleSilicon() -> Bool {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        let result = sysctlbyname("hw.optional.arm64", &value, &size, nil, 0)
        return result == 0 && value == 1
    }
}
