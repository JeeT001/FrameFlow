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
