//
//  ThumbnailStripGenerator.swift
//  FrameFlow
//

import AppKit
import AVFoundation
import Foundation

actor ThumbnailStripGenerator {
    static let shared = ThumbnailStripGenerator()
    static let maxThumbnailSize = CGSize(width: 120, height: 80)

    private var cache: [String: [(time: Double, image: NSImage)]] = [:]

    static func generate(
        url: URL,
        count: Int,
        startSeconds: Double,
        endSeconds: Double
    ) async -> [(time: Double, image: NSImage)] {
        await shared.generate(
            url: url,
            count: count,
            startSeconds: startSeconds,
            endSeconds: endSeconds
        )
    }

    func generate(
        url: URL,
        count: Int,
        startSeconds: Double,
        endSeconds: Double
    ) async -> [(time: Double, image: NSImage)] {
        let safeCount = max(1, count)
        let lo = min(startSeconds, endSeconds)
        let hi = max(startSeconds, endSeconds)
        guard hi - lo > 0.01 else { return [] }

        let cacheKey = "\(url.path)|\(safeCount)|\(String(format: "%.3f", lo))|\(String(format: "%.3f", hi))"
        if let cached = cache[cacheKey] {
            return cached
        }

        guard FileManager.default.fileExists(atPath: url.path) || SecurityScopedFileAccess.canAccess(url) else {
            return []
        }

        let frames = await loadFrames(url: url, count: safeCount, startSeconds: lo, endSeconds: hi)
        if !frames.isEmpty {
            cache[cacheKey] = frames
        }
        return frames
    }

    private func loadFrames(
        url: URL,
        count: Int,
        startSeconds: Double,
        endSeconds: Double
    ) async -> [(time: Double, image: NSImage)] {
        do {
            return try await SecurityScopedFileAccess.withAccess(to: url) {
                let asset = AVURLAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = Self.maxThumbnailSize
                generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
                generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)

                let span = endSeconds - startSeconds
                let sampleTimes: [Double] = (0..<count).map { index in
                    if count == 1 {
                        return startSeconds + span * 0.5
                    }
                    return startSeconds + span * (Double(index) + 0.5) / Double(count)
                }

                return await withCheckedContinuation { continuation in
                    let cmTimes = sampleTimes.map { NSValue(time: CMTime(seconds: $0, preferredTimescale: 600)) }
                    var results: [(time: Double, image: NSImage)] = []
                    var completed = 0
                    let lock = NSLock()

                    generator.generateCGImagesAsynchronously(forTimes: cmTimes) { requestedTime, image, _, result, _ in
                        lock.lock()
                        if result == .succeeded, let image {
                            let seconds = CMTimeGetSeconds(requestedTime)
                            results.append((time: seconds, image: NSImage(cgImage: image, size: .zero)))
                        }
                        completed += 1
                        let isDone = completed == cmTimes.count
                        lock.unlock()

                        if isDone {
                            continuation.resume(returning: results.sorted { $0.time < $1.time })
                        }
                    }
                }
            }
        } catch {
            return []
        }
    }
}
