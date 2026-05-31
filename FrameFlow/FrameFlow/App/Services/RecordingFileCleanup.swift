//
//  RecordingFileCleanup.swift
//  FrameFlow
//

import Foundation

enum RecordingFileCleanup {
    static func deleteStagingAndSidecars(for metadata: RecordingMetadata) {
        let fileManager = FileManager.default
        let videoURL = URL(fileURLWithPath: metadata.filePath)
        let engine = CaptionEngine.shared

        var urls: [URL] = [
            engine.sidecarURLAdjacent(to: videoURL),
            engine.srtURL(for: videoURL),
            engine.burnedInURL(for: videoURL),
            appSupportCaptionSidecar(recordingID: metadata.id)
        ]

        if RecordingStaging.isStagingPath(metadata.filePath) {
            urls.insert(videoURL, at: 0)
        }

        for url in urls {
            guard fileManager.fileExists(atPath: url.path) else { continue }
            try? fileManager.removeItem(at: url)
        }
    }

    static func deleteExportedRecordingFiles(for metadata: RecordingMetadata) {
        let fileManager = FileManager.default
        let videoURL = URL(fileURLWithPath: metadata.filePath)
        let engine = CaptionEngine.shared

        let urls: [URL] = [
            videoURL,
            engine.sidecarURLAdjacent(to: videoURL),
            engine.srtURL(for: videoURL),
            appSupportCaptionSidecar(recordingID: metadata.id)
        ]

        for url in urls {
            guard fileManager.fileExists(atPath: url.path) else { continue }
            try? fileManager.removeItem(at: url)
        }
    }

    static func appSupportCaptionSidecar(recordingID: UUID) -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FrameFlow/Captions/\(recordingID.uuidString).json")
    }
}
