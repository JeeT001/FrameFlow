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
        let probed = await probeFirstVideoSampleSeconds(asset: asset)
        guard let metadataLead, metadataLead > 0.001 else {
            return probed
        }

        // Recording metadata tracks audio muxed before the first video frame. The exported file
        // may still place the first video sample near `probed`. When metadata overshoots, trust
        // the file so captions and preview are not shifted minutes into the timeline.
        if probed > 0.001, metadataLead > probed + 1.0 {
            return probed
        }

        if probed <= 0.001, metadataLead > 5.0 {
            return 0
        }

        return max(metadataLead, probed)
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
