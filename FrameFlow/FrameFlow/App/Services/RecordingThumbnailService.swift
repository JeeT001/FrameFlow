//
//  RecordingThumbnailService.swift
//  FrameFlow
//

import AppKit
import AVFoundation
import Foundation

@MainActor
enum RecordingThumbnailService {
    private static var cache: [String: NSImage] = [:]

    static let gridMaximumSize = CGSize(width: 480, height: 270)
    static let detailMaximumSize = CGSize(width: 640, height: 360)

    static func thumbnail(
        for recording: RecordingMetadata,
        maxSize: CGSize = gridMaximumSize
    ) async -> NSImage? {
        await thumbnail(for: URL(fileURLWithPath: recording.filePath), maxSize: maxSize)
    }

    static func thumbnail(
        for url: URL,
        maxSize: CGSize = gridMaximumSize
    ) async -> NSImage? {
        let cacheKey = "\(url.path)|\(Int(maxSize.width))x\(Int(maxSize.height))"
        if let cached = cache[cacheKey] {
            return cached
        }

        guard FileManager.default.fileExists(atPath: url.path) || SecurityScopedFileAccess.canAccess(url) else {
            return nil
        }

        guard let image = await generateThumbnail(for: url, maxSize: maxSize) else {
            return nil
        }

        cache[cacheKey] = image
        return image
    }

    static func removeCached(forFilePath path: String) {
        cache.keys.filter { $0.hasPrefix(path + "|") }.forEach { cache.removeValue(forKey: $0) }
    }

    static func clearCache() {
        cache.removeAll()
    }

    private static func generateThumbnail(for url: URL, maxSize: CGSize) async -> NSImage? {
        do {
            return try await SecurityScopedFileAccess.withAccess(to: url) {
                let asset = AVURLAsset(url: url)

                guard let duration = try? await asset.load(.duration) else { return nil }
                let seconds = min(1.0, max(0, CMTimeGetSeconds(duration) * 0.05))
                let time = CMTime(seconds: seconds, preferredTimescale: 600)

                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = maxSize

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
        } catch {
            return nil
        }
    }
}
