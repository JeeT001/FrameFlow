//
//  EditorFilmstripClipView.swift
//  FrameFlow
//

import AppKit
import SwiftUI

struct EditorFilmstripClipView: View {
    let videoURL: URL
    let clipWidthPixels: CGFloat
    let trimStart: Double
    let trimEnd: Double
    var clipLabel: String = ""

    @State private var thumbnails: [(time: Double, image: NSImage)] = []
    @State private var isLoading = true

    private var thumbnailCount: Int {
        max(1, min(24, Int(ceil(clipWidthPixels / 56))))
    }

    private var waveformSeed: UInt64 {
        var hasher = Hasher()
        hasher.combine(trimStart)
        hasher.combine(trimEnd)
        hasher.combine(Int(clipWidthPixels.rounded()))
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }

    var body: some View {
        VStack(spacing: 0) {
            filmstripRow
                .frame(height: EditorTimelineDesign.filmstripHeight)

            EditorWaveformBar(
                width: max(clipWidthPixels, 1),
                barCount: max(8, Int(clipWidthPixels / 4)),
                seed: waveformSeed
            )
            .frame(height: EditorTimelineDesign.waveformBarHeight)
        }
        .frame(width: max(clipWidthPixels, 1))
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay {
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(
                    EditorTimelineDesign.clipBorderYellow,
                    lineWidth: EditorTimelineDesign.clipBorderWidth
                )
        }
        .overlay(alignment: .topLeading) {
            if clipWidthPixels > 80, !clipLabel.isEmpty {
                Text(clipLabel)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.45), in: Capsule())
                    .padding(6)
            }
        }
        .task(id: reloadToken) {
            await loadThumbnails()
        }
    }

    private var reloadToken: String {
        "\(videoURL.path)|\(trimStart)|\(trimEnd)|\(thumbnailCount)"
    }

    @ViewBuilder
    private var filmstripRow: some View {
        if thumbnails.isEmpty, isLoading {
            loadingPlaceholder
        } else if thumbnails.isEmpty {
            loadingPlaceholder
        } else {
            HStack(spacing: 0) {
                ForEach(Array(thumbnails.enumerated()), id: \.offset) { _, frame in
                    Image(nsImage: frame.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: max(clipWidthPixels / CGFloat(thumbnails.count), 1),
                            height: EditorTimelineDesign.filmstripHeight
                        )
                        .clipped()
                }
            }
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            Color.white.opacity(0.08)
            ProgressView()
                .controlSize(.small)
        }
    }

    private func loadThumbnails() async {
        isLoading = true
        let frames = await ThumbnailStripGenerator.generate(
            url: videoURL,
            count: thumbnailCount,
            startSeconds: trimStart,
            endSeconds: trimEnd
        )
        thumbnails = frames
        isLoading = false
    }
}

struct EditorWaveformBar: View {
    let width: CGFloat
    let barCount: Int
    let seed: UInt64

    var body: some View {
        GeometryReader { geometry in
            let count = max(1, barCount)
            let barWidth = max(1, (geometry.size.width - CGFloat(count - 1)) / CGFloat(count))
            HStack(spacing: 1) {
                ForEach(0..<count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color.white.opacity(0.35))
                        .frame(width: barWidth, height: barHeight(at: index))
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .background(Color.black.opacity(0.25))
    }

    private func barHeight(at index: Int) -> CGFloat {
        let maxHeight = EditorTimelineDesign.waveformBarHeight - 4
        let minHeight = maxHeight * 0.18
        var generator = SeededRandomNumberGenerator(seed: seed &+ UInt64(index))
        let normalized = Double.random(in: 0.22...1.0, using: &generator)
        return minHeight + CGFloat(normalized) * (maxHeight - minHeight)
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}
