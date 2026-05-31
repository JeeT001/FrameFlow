//
//  RecordingStaging.swift
//  FrameFlow
//

import Foundation

enum RecordingStaging {
    private static let stagingFolderName = "Staging"

    static func directory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FrameFlow", isDirectory: true)
            .appendingPathComponent(stagingFolderName, isDirectory: true)
    }

    static func fileURL(recordingID: UUID) -> URL {
        directory().appendingPathComponent("\(recordingID.uuidString).mp4")
    }

    static func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(at: directory(), withIntermediateDirectories: true)
    }

    static func isStagingPath(_ path: String) -> Bool {
        path.contains("/FrameFlow/\(stagingFolderName)/")
    }

    /// App-container paths are readable/writable without security-scoped bookmarks.
    static func isAppContainerPath(_ url: URL) -> Bool {
        isStagingPath(url.path) || url.path.contains("/Application Support/FrameFlow/")
    }
}
