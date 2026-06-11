//
//  TimelineGeometry.swift
//  FrameFlow
//

import CoreGraphics
import Foundation

enum TimelineGeometry {
    static func xPosition(for time: Double, duration: Double, width: CGFloat) -> CGFloat {
        guard duration > 0, width > 0 else { return 0 }
        let fraction = min(1, max(0, time / duration))
        return CGFloat(fraction) * width
    }

    static func timeAt(x: CGFloat, duration: Double, width: CGFloat) -> Double {
        guard width > 0, duration > 0 else { return 0 }
        let fraction = min(1, max(0, Double(x / width)))
        return fraction * duration
    }

    /// Absolute x in the tracks panel (label gutter + time position).
    static func absoluteX(
        for time: Double,
        duration: Double,
        trackWidth: CGFloat,
        labelWidth: CGFloat = EditorTimelineLayout.laneLabelWidth
    ) -> CGFloat {
        labelWidth + xPosition(for: time, duration: duration, width: trackWidth)
    }
}
