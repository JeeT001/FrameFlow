//
//  FilmoraPlayheadView.swift
//  FrameFlow
//

import SwiftUI

struct FilmoraPlayheadView: View {
    let playheadSeconds: Double
    let totalDuration: Double
    let pixelsPerSecond: CGFloat
    let totalHeight: CGFloat
    let onSeek: (Double) -> Void

    @GestureState private var isDragging = false

    private var xPosition: CGFloat { CGFloat(playheadSeconds) * pixelsPerSecond }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color(red: 0.95, green: 0.2, blue: 0.2))
                .frame(width: 1.5, height: totalHeight)
                .offset(x: xPosition)
                .allowsHitTesting(false)

            Circle()
                .fill(Color(red: 0.95, green: 0.3, blue: 0.3))
                .frame(width: 18, height: 18)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                .offset(x: xPosition - 9, y: -4)
                .scaleEffect(isDragging ? 1.2 : 1.0)
                .animation(.spring(response: 0.2), value: isDragging)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("timeline"))
                        .updating($isDragging) { _, state, _ in
                            state = true
                        }
                        .onChanged { value in
                            let time = Double(value.location.x / max(pixelsPerSecond, 0.001))
                                .clamped(to: 0...max(totalDuration, 0.001))
                            onSeek(time)
                        }
                )
                .onHover { inside in
                    if inside {
                        NSCursor.resizeLeftRight.push()
                    } else {
                        NSCursor.pop()
                    }
                }
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
