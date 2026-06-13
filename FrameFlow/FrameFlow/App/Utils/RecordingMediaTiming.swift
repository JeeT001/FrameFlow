//
//  RecordingMediaTiming.swift
//  FrameFlow
//

import AVFoundation
import Foundation

enum RecordingMediaTiming {
    /// Leading seconds before the first decodable video sample (audio may start earlier).
    static func leadingVideoGapSeconds(
        asset: AVAsset,
        metadataLead: Double?
    ) async -> Double {
        if let metadataLead, metadataLead > 0.001 {
            return metadataLead
        }
        return await probeFirstVideoSampleSeconds(asset: asset)
    }

    static func probeFirstVideoSampleSeconds(asset: AVAsset) async -> Double {
        guard let track = try? await asset.loadTracks(withMediaType: .video).first else {
            return 0
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let reader: AVAssetReader
                do {
                    reader = try AVAssetReader(asset: asset)
                } catch {
                    continuation.resume(returning: 0)
                    return
                }

                let output = AVAssetReaderTrackOutput(
                    track: track,
                    outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                )
                output.alwaysCopiesSampleData = false
                guard reader.canAdd(output) else {
                    continuation.resume(returning: 0)
                    return
                }
                reader.add(output)
                guard reader.startReading() else {
                    continuation.resume(returning: 0)
                    return
                }

                defer { reader.cancelReading() }

                guard let sample = output.copyNextSampleBuffer() else {
                    continuation.resume(returning: 0)
                    return
                }

                let pts = CMSampleBufferGetPresentationTimeStamp(sample)
                let seconds = CMTimeGetSeconds(pts)
                continuation.resume(returning: seconds.isFinite && seconds > 0.001 ? seconds : 0)
            }
        }
    }

    static func adjustedKeptRanges(
        _ ranges: [KeptSourceRange],
        leadingGap: Double,
        sourceDuration: Double
    ) -> [KeptSourceRange] {
        guard leadingGap > 0.001 else { return ranges }

        return ranges.compactMap { range in
            let start = max(range.start, leadingGap)
            let end = min(range.end, sourceDuration)
            guard end - start > 0.001 else { return nil }
            return KeptSourceRange(start: start, end: end)
        }
    }
}
