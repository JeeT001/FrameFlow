//
//  AudioWaveformGenerator.swift
//  FrameFlow
//

import AVFoundation
import Foundation

actor AudioWaveformGenerator {
    static let shared = AudioWaveformGenerator()

    private var cache: [String: [Float]] = [:]

    static func samples(url: URL, count: Int) async -> [Float] {
        await shared.samples(url: url, count: count)
    }

    func samples(url: URL, count: Int) async -> [Float] {
        let safeCount = max(1, count)
        let cacheKey = "\(url.path)|\(safeCount)"
        if let cached = cache[cacheKey] {
            return cached
        }

        let generated = await loadSamples(url: url, count: safeCount)
        if !generated.isEmpty {
            cache[cacheKey] = generated
        }
        return generated
    }

    private func loadSamples(url: URL, count: Int) async -> [Float] {
        do {
            return try await SecurityScopedFileAccess.withAccess(to: url) {
                let asset = AVURLAsset(url: url)
                guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
                    return Array(repeating: 0, count: count)
                }

                guard let reader = try? AVAssetReader(asset: asset) else {
                    return Array(repeating: 0, count: count)
                }

                let settings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false
                ]
                let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
                guard reader.canAdd(output) else {
                    return Array(repeating: 0, count: count)
                }
                reader.add(output)
                guard reader.startReading() else {
                    return Array(repeating: 0, count: count)
                }

                var rawSamples: [Float] = []
                while let buffer = output.copyNextSampleBuffer(),
                      let block = CMSampleBufferGetDataBuffer(buffer) {
                    let length = CMBlockBufferGetDataLength(block)
                    var data = Data(count: length)
                    data.withUnsafeMutableBytes { ptr in
                        guard let base = ptr.baseAddress else { return }
                        CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length, destination: base)
                    }
                    let int16s = data.withUnsafeBytes {
                        Array($0.bindMemory(to: Int16.self))
                    }
                    rawSamples.append(contentsOf: int16s.map { abs(Float($0) / Float(Int16.max)) })
                }

                guard !rawSamples.isEmpty else {
                    return Array(repeating: 0, count: count)
                }

                let bucketSize = max(1, rawSamples.count / count)
                let buckets = (0..<count).map { index -> Float in
                    let start = index * bucketSize
                    let end = min((index + 1) * bucketSize, rawSamples.count)
                    guard start < end else { return 0 }
                    return rawSamples[start..<end].max() ?? 0
                }
                return buckets
            }
        } catch {
            return Array(repeating: 0, count: count)
        }
    }
}
