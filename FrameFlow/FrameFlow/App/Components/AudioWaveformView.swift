//
//  AudioWaveformView.swift
//  FrameFlow
//

import SwiftUI

struct AudioWaveformView: View {
    let url: URL
    let width: CGFloat
    let height: CGFloat

    @State private var amplitudes: [Float] = []

    private var barCount: Int { max(20, Int(width / 3)) }

    var body: some View {
        Canvas { context, size in
            guard !amplitudes.isEmpty else { return }
            let barW = size.width / CGFloat(amplitudes.count)
            for (index, amp) in amplitudes.enumerated() {
                let barH = CGFloat(amp) * size.height
                let rect = CGRect(
                    x: CGFloat(index) * barW + 0.5,
                    y: (size.height - barH) / 2,
                    width: max(1, barW - 1),
                    height: max(1, barH)
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 1),
                    with: .color(Color(red: 0.0, green: 0.85, blue: 0.85).opacity(0.8))
                )
            }
        }
        .frame(width: width, height: height)
        .background(Color(red: 0.0, green: 0.15, blue: 0.15).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .task(id: "\(url.path)|\(barCount)") {
            amplitudes = await AudioWaveformGenerator.samples(url: url, count: barCount)
        }
    }
}
