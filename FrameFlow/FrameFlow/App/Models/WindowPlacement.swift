//
//  WindowPlacement.swift
//  FrameFlow
//

import CoreGraphics
import Foundation

struct WindowPlacement: Codable, Equatable {
    /// Normalized center: x 0=left, 1=right; y 0=bottom, 1=top (matches PiPController).
    var center: CGPoint
    /// Fraction of canvas width (0.12...3.0 in free-form overflow mode).
    var widthFraction: CGFloat
    /// Fraction of canvas height — independent crop frame height (not derived from window aspect).
    var heightFraction: CGFloat
    /// Scale of captured content inside the frame (1.0 = default fit/fill). Does not resize the frame.
    var contentScale: CGFloat
    /// Normalized focal point in source content (0–1), used when contentScale > 1. Default center.
    var contentFocalPoint: CGPoint

    init(
        center: CGPoint,
        widthFraction: CGFloat,
        heightFraction: CGFloat,
        contentScale: CGFloat = 1.0,
        contentFocalPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    ) {
        self.center = center
        self.widthFraction = widthFraction
        self.heightFraction = heightFraction
        self.contentScale = contentScale
        self.contentFocalPoint = contentFocalPoint
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        center = try container.decode(CGPoint.self, forKey: .center)
        widthFraction = try container.decode(CGFloat.self, forKey: .widthFraction)
        heightFraction = try container.decodeIfPresent(CGFloat.self, forKey: .heightFraction) ?? 0
        contentScale = try container.decodeIfPresent(CGFloat.self, forKey: .contentScale) ?? 1.0
        contentFocalPoint = try container.decodeIfPresent(CGPoint.self, forKey: .contentFocalPoint)
            ?? CGPoint(x: 0.5, y: 0.5)
    }

    var hasValidCropFrame: Bool {
        widthFraction > 0 && heightFraction > 0
    }

    private enum CodingKeys: String, CodingKey {
        case center
        case widthFraction
        case heightFraction
        case contentScale
        case contentFocalPoint
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(center, forKey: .center)
        try container.encode(widthFraction, forKey: .widthFraction)
        try container.encode(heightFraction, forKey: .heightFraction)
        try container.encode(contentScale, forKey: .contentScale)
        try container.encode(contentFocalPoint, forKey: .contentFocalPoint)
    }
}
