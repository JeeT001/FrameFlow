//
//  RecordingMetadata.swift
//  FrameFlow
//

import CoreGraphics
import Foundation

struct RecordingMetadata: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var filePath: String
    var durationSeconds: Int
    var resolution: String
    var format: String
    var layout: String
    var windowCount: Int
    var hasCaptions: Bool
    var hasCamera: Bool
    var audioMode: String
    var createdAt: Date
    var fileSizeBytes: Int
    /// Audio timeline lead (seconds) when the first video frame was written; aligns Whisper captions to video playback.
    var captionAudioLeadSeconds: Double = 0

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case filePath = "file_path"
        case durationSeconds = "duration_seconds"
        case resolution
        case format
        case layout
        case windowCount = "window_count"
        case hasCaptions = "has_captions"
        case hasCamera = "has_camera"
        case audioMode = "audio_mode"
        case createdAt = "created_at"
        case fileSizeBytes = "file_size_bytes"
        case captionAudioLeadSeconds = "caption_audio_lead_seconds"
    }

    init(
        id: UUID,
        name: String,
        filePath: String,
        durationSeconds: Int,
        resolution: String,
        format: String,
        layout: String,
        windowCount: Int,
        hasCaptions: Bool,
        hasCamera: Bool,
        audioMode: String,
        createdAt: Date,
        fileSizeBytes: Int,
        captionAudioLeadSeconds: Double = 0
    ) {
        self.id = id
        self.name = name
        self.filePath = filePath
        self.durationSeconds = durationSeconds
        self.resolution = resolution
        self.format = format
        self.layout = layout
        self.windowCount = windowCount
        self.hasCaptions = hasCaptions
        self.hasCamera = hasCamera
        self.audioMode = audioMode
        self.createdAt = createdAt
        self.fileSizeBytes = fileSizeBytes
        self.captionAudioLeadSeconds = captionAudioLeadSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        filePath = try container.decode(String.self, forKey: .filePath)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        resolution = try container.decode(String.self, forKey: .resolution)
        format = try container.decode(String.self, forKey: .format)
        layout = try container.decode(String.self, forKey: .layout)
        windowCount = try container.decode(Int.self, forKey: .windowCount)
        hasCaptions = try container.decode(Bool.self, forKey: .hasCaptions)
        hasCamera = try container.decode(Bool.self, forKey: .hasCamera)
        audioMode = try container.decode(String.self, forKey: .audioMode)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        fileSizeBytes = try container.decode(Int.self, forKey: .fileSizeBytes)
        captionAudioLeadSeconds = try container.decodeIfPresent(Double.self, forKey: .captionAudioLeadSeconds) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(filePath, forKey: .filePath)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(resolution, forKey: .resolution)
        try container.encode(format, forKey: .format)
        try container.encode(layout, forKey: .layout)
        try container.encode(windowCount, forKey: .windowCount)
        try container.encode(hasCaptions, forKey: .hasCaptions)
        try container.encode(hasCamera, forKey: .hasCamera)
        try container.encode(audioMode, forKey: .audioMode)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(fileSizeBytes, forKey: .fileSizeBytes)
        if captionAudioLeadSeconds > 0.001 {
            try container.encode(captionAudioLeadSeconds, forKey: .captionAudioLeadSeconds)
        }
    }

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        Self.displayDateFormatter.string(from: createdAt)
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSizeBytes), countStyle: .file)
    }

    var resolutionBadge: String {
        if resolution.contains("3840") || resolution.lowercased().contains("4k") {
            return "4K"
        }
        if resolution.contains("1920") || resolution.lowercased().contains("1080") {
            return "1080p"
        }
        return "720p"
    }

    var previewAspectRatio: CGFloat {
        format == "9:16" ? 9.0 / 16.0 : 16.0 / 9.0
    }

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#if DEBUG
extension RecordingMetadata {
    static func mock(
        name: String,
        resolution: String = "1920x1080",
        format: String = "16:9",
        daysAgo: Int = 0
    ) -> RecordingMetadata {
        RecordingMetadata(
            id: UUID(),
            name: name,
            filePath: "/tmp/\(name.replacingOccurrences(of: " ", with: "_")).mp4",
            durationSeconds: 125,
            resolution: resolution,
            format: format,
            layout: "side_by_side",
            windowCount: 2,
            hasCaptions: false,
            hasCamera: true,
            audioMode: "combined",
            createdAt: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date(),
            fileSizeBytes: 48_200_000
        )
    }
}
#endif
