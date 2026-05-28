//
//  RecordingLayout.swift
//  FrameFlow
//

import CoreGraphics
import Foundation

enum RecordingFormat: String, CaseIterable, Identifiable {
    case nineBySixteen = "9:16"
    case sixteenByNine = "16:9"

    var id: String { rawValue }

    var title: String { rawValue }

    var aspectRatio: CGFloat {
        switch self {
        case .nineBySixteen: 9.0 / 16.0
        case .sixteenByNine: 16.0 / 9.0
        }
    }
}

enum LayoutPreset: String, CaseIterable, Identifiable {
    case stacked
    case sideBySide
    case pipBottomRight
    case pipFaceTop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stacked: "Stacked"
        case .sideBySide: "Side-by-Side"
        case .pipBottomRight: "PiP Bottom-Right"
        case .pipFaceTop: "PiP Face-Top"
        }
    }
}

enum AudioModeOption: String, CaseIterable, Identifiable {
    case mic
    case system
    case combined
    case none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mic: "Microphone Only"
        case .system: "System Audio Only"
        case .combined: "Microphone + System Audio"
        case .none: "No Audio"
        }
    }

    var systemImage: String {
        switch self {
        case .mic: "mic.fill"
        case .system: "speaker.wave.2.fill"
        case .combined: "mic.and.signal.meter.fill"
        case .none: "speaker.slash.fill"
        }
    }

    var requiresPro: Bool {
        self == .system || self == .combined
    }
}
