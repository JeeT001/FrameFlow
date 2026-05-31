//
//  RecordingDetailViewModel.swift
//  FrameFlow
//

import AppKit
import AVFoundation
import Foundation

@MainActor
@Observable
final class RecordingDetailViewModel {
    private(set) var recording: RecordingMetadata?
    var draftName: String = ""
    var thumbnail: NSImage?
    var errorMessage: String?
    var isSavingRename = false
    var isDeleting = false
    var showDeleteConfirmation = false

    private var thumbnailSourcePath: String?

    var videoURL: URL? {
        guard let recording else { return nil }
        return URL(fileURLWithPath: recording.filePath)
    }

    var fileExistsOnDisk: Bool {
        guard let url = videoURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    func load(recordingID: UUID?) {
        guard let recordingID else {
            recording = nil
            draftName = ""
            thumbnail = nil
            errorMessage = "No recording selected."
            return
        }

        guard let found = RecordingStore.shared.recordings.first(where: { $0.id == recordingID }) else {
            recording = nil
            draftName = ""
            thumbnail = nil
            errorMessage = "Recording was not found."
            return
        }

        recording = found
        draftName = found.name
        errorMessage = nil

        if !fileExistsOnDisk {
            errorMessage = "The video file is missing from disk. You can delete this entry."
            thumbnail = nil
            return
        }

        Task { await loadThumbnailIfNeeded() }
    }

    func saveRename() async {
        guard var metadata = recording, let sourceURL = videoURL else { return }
        guard fileExistsOnDisk else {
            errorMessage = "Cannot rename — file is missing."
            return
        }

        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Name cannot be empty."
            draftName = metadata.name
            return
        }

        let sanitized = Self.sanitizedFilename(from: trimmed)
        guard sanitized != metadata.name else { return }

        isSavingRename = true
        errorMessage = nil
        defer { isSavingRename = false }

        let directory = sourceURL.deletingLastPathComponent()
        let destinationURL = directory.appendingPathComponent("\(sanitized).mp4")

        if FileManager.default.fileExists(atPath: destinationURL.path),
           destinationURL.path != sourceURL.path {
            errorMessage = "A file named \"\(sanitized).mp4\" already exists."
            return
        }

        do {
            if destinationURL.path != sourceURL.path {
                try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            }
            metadata.name = sanitized
            metadata.filePath = destinationURL.path
            try RecordingStore.shared.update(metadata)
            recording = metadata
            draftName = sanitized
            await loadThumbnailIfNeeded(force: true)
        } catch {
            errorMessage = "Rename failed: \(error.localizedDescription)"
            draftName = metadata.name
        }
    }

    func deleteRecording() async -> Bool {
        guard let metadata = recording else { return false }

        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        deleteRelatedFiles(for: metadata)

        do {
            try RecordingStore.shared.remove(id: metadata.id)
            recording = nil
            thumbnail = nil
            return true
        } catch {
            errorMessage = "Could not remove recording: \(error.localizedDescription)"
            return false
        }
    }

    func playInSystemPlayer() {
        guard let url = videoURL, fileExistsOnDisk else {
            errorMessage = "Video file is not available."
            return
        }
        NSWorkspace.shared.open(url)
    }

    func revealInFinder() {
        guard let url = videoURL, fileExistsOnDisk else {
            errorMessage = "Video file is not available."
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func loadThumbnailIfNeeded(force: Bool = false) async {
        guard let url = videoURL, fileExistsOnDisk else {
            thumbnail = nil
            return
        }

        if !force, thumbnailSourcePath == url.path, thumbnail != nil {
            return
        }

        thumbnailSourcePath = url.path
        thumbnail = await Self.generateThumbnail(for: url)
    }

    private func deleteRelatedFiles(for metadata: RecordingMetadata) {
        RecordingFileCleanup.deleteExportedRecordingFiles(for: metadata)
    }

    private static func sanitizedFilename(from name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "-")
            .replacingOccurrences(of: "\u{0000}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutExtension = (cleaned as NSString).deletingPathExtension
        return withoutExtension.isEmpty ? "Recording" : withoutExtension
    }

    private static func generateThumbnail(for url: URL) async -> NSImage? {
        let asset = AVURLAsset(url: url)

        guard let duration = try? await asset.load(.duration) else { return nil }
        let seconds = min(1.0, max(0, CMTimeGetSeconds(duration) * 0.05))
        let time = CMTime(seconds: seconds, preferredTimescale: 600)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 360)

        return await withCheckedContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
                if let image {
                    continuation.resume(returning: NSImage(cgImage: image, size: .zero))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
