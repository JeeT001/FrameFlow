//
//  EditorSelection.swift
//  FrameFlow
//

import Foundation

enum EditorInspectorMode: String, CaseIterable, Identifiable {
    case edit = "Edit"
    case captions = "Captions"

    var id: String { rawValue }
}

enum EditorSelection: Equatable {
    case none
    case timeline
    case imageOverlay(UUID)
    case importedAudio(UUID)
    case captions
    case captionSegment(UUID)
}
