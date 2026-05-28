//
//  CaptionSegment.swift
//  FrameFlow
//

import Foundation

struct CaptionSegment: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var text: String
    var startTime: Double
    var endTime: Double

    init(id: UUID = UUID(), text: String, startTime: Double, endTime: Double) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
    }
}

struct CaptionSidecar: Codable, Sendable {
    let recordingID: UUID
    var segments: [CaptionSegment]
    let createdAt: Date
    var stylePreset: String?
}
