//
//  SettingsStore.swift
//  FrameFlow
//

import Foundation

@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    var defaultResolution: String {
        didSet { defaults.set(defaultResolution, forKey: Keys.defaultResolution) }
    }

    var defaultSaveFolder: String {
        didSet { defaults.set(defaultSaveFolder, forKey: Keys.defaultSaveFolder) }
    }

    var defaultSaveFolderBookmarkData: Data? {
        didSet {
            if let defaultSaveFolderBookmarkData {
                defaults.set(defaultSaveFolderBookmarkData, forKey: Keys.defaultSaveFolderBookmarkData)
            } else {
                defaults.removeObject(forKey: Keys.defaultSaveFolderBookmarkData)
            }
        }
    }

    var defaultAudioMode: String {
        didSet { defaults.set(defaultAudioMode, forKey: Keys.defaultAudioMode) }
    }

    var defaultMicDevice: String? {
        didSet {
            if let defaultMicDevice {
                defaults.set(defaultMicDevice, forKey: Keys.defaultMicDevice)
            } else {
                defaults.removeObject(forKey: Keys.defaultMicDevice)
            }
        }
    }

    var defaultMicVolume: Float {
        didSet { defaults.set(defaultMicVolume, forKey: Keys.defaultMicVolume) }
    }

    var defaultSystemVolume: Float {
        didSet { defaults.set(defaultSystemVolume, forKey: Keys.defaultSystemVolume) }
    }

    var autoFocusEnabled: Bool {
        didSet { defaults.set(autoFocusEnabled, forKey: Keys.autoFocusEnabled) }
    }

    var cursorHighlightEnabled: Bool {
        didSet { defaults.set(cursorHighlightEnabled, forKey: Keys.cursorHighlightEnabled) }
    }

    var autoZoomOnClick: Bool {
        didSet { defaults.set(autoZoomOnClick, forKey: Keys.autoZoomOnClick) }
    }

    var zoomStrength: Float {
        didSet { defaults.set(zoomStrength, forKey: Keys.zoomStrength) }
    }

    var zoomHoldDuration: Double {
        didSet { defaults.set(zoomHoldDuration, forKey: Keys.zoomHoldDuration) }
    }

    var cursorHighlightColor: String {
        didSet { defaults.set(cursorHighlightColor, forKey: Keys.cursorHighlightColor) }
    }

    var countdownDuration: Int {
        didSet { defaults.set(countdownDuration, forKey: Keys.countdownDuration) }
    }

    var captionStyle: String {
        didSet { defaults.set(captionStyle, forKey: Keys.captionStyle) }
    }

    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    var darkModeOverride: String {
        didSet { defaults.set(darkModeOverride, forKey: Keys.darkModeOverride) }
    }

    var expandedSaveFolder: String {
        (defaultSaveFolder as NSString).expandingTildeInPath
    }

    private init() {
        defaultResolution = defaults.string(forKey: Keys.defaultResolution) ?? "1080p"
        defaultSaveFolder = defaults.string(forKey: Keys.defaultSaveFolder) ?? "~/Desktop"
        defaultSaveFolderBookmarkData = defaults.data(forKey: Keys.defaultSaveFolderBookmarkData)
        defaultAudioMode = defaults.string(forKey: Keys.defaultAudioMode) ?? "combined"
        defaultMicDevice = defaults.string(forKey: Keys.defaultMicDevice)
        defaultMicVolume = defaults.object(forKey: Keys.defaultMicVolume) as? Float ?? 1.0
        defaultSystemVolume = defaults.object(forKey: Keys.defaultSystemVolume) as? Float ?? 0.8
        autoFocusEnabled = defaults.object(forKey: Keys.autoFocusEnabled) as? Bool ?? true
        cursorHighlightEnabled = defaults.object(forKey: Keys.cursorHighlightEnabled) as? Bool ?? true
        autoZoomOnClick = defaults.object(forKey: Keys.autoZoomOnClick) as? Bool ?? true
        zoomStrength = defaults.object(forKey: Keys.zoomStrength) as? Float ?? 0.75
        zoomHoldDuration = defaults.object(forKey: Keys.zoomHoldDuration) as? Double ?? 1.0
        cursorHighlightColor = defaults.string(forKey: Keys.cursorHighlightColor) ?? "white"
        countdownDuration = defaults.object(forKey: Keys.countdownDuration) as? Int ?? 3
        captionStyle = defaults.string(forKey: Keys.captionStyle) ?? "classic"
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        darkModeOverride = defaults.string(forKey: Keys.darkModeOverride) ?? "system"
    }

    private enum Keys {
        static let defaultResolution = "defaultResolution"
        static let defaultSaveFolder = "defaultSaveFolder"
        static let defaultSaveFolderBookmarkData = "defaultSaveFolderBookmarkData"
        static let defaultAudioMode = "defaultAudioMode"
        static let defaultMicDevice = "defaultMicDevice"
        static let defaultMicVolume = "defaultMicVolume"
        static let defaultSystemVolume = "defaultSystemVolume"
        static let autoFocusEnabled = "autoFocusEnabled"
        static let cursorHighlightEnabled = "cursorHighlightEnabled"
        static let autoZoomOnClick = "autoZoomOnClick"
        static let zoomStrength = "zoomStrength"
        static let zoomHoldDuration = "zoomHoldDuration"
        static let cursorHighlightColor = "cursorHighlightColor"
        static let countdownDuration = "countdownDuration"
        static let captionStyle = "captionStyle"
        static let notificationsEnabled = "notificationsEnabled"
        static let darkModeOverride = "darkModeOverride"
    }
}
