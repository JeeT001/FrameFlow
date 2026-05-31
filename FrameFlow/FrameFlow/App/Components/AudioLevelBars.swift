//
//  AudioLevelBars.swift
//  FrameFlow
//

import SwiftUI

struct AudioLevelBars: View {
    let level: Float

    private let barCount = 5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(AppColors.primary.opacity(0.85))
                        .frame(width: 10, height: barHeight(for: index))
                }
            }
            .frame(height: 52, alignment: .bottom)
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let minimum: CGFloat = 6
        let maximum: CGFloat = 52
        let threshold = Float(index + 1) / Float(barCount)
        let normalized = max(0, min(1, level))

        if normalized < threshold * 0.55 {
            return minimum
        }

        let barLevel = max(0, (normalized - (threshold - 0.2)) / 0.35)
        return minimum + CGFloat(barLevel) * (maximum - minimum)
    }
}

#Preview {
    AudioLevelBars(level: 0.6)
        .padding()
}
