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

    init(center: CGPoint, widthFraction: CGFloat, heightFraction: CGFloat) {
        self.center = center
        self.widthFraction = widthFraction
        self.heightFraction = heightFraction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        center = try container.decode(CGPoint.self, forKey: .center)
        widthFraction = try container.decode(CGFloat.self, forKey: .widthFraction)
        heightFraction = try container.decodeIfPresent(CGFloat.self, forKey: .heightFraction) ?? 0
    }

    var hasValidCropFrame: Bool {
        widthFraction > 0 && heightFraction > 0
    }

    private enum CodingKeys: String, CodingKey {
        case center
        case widthFraction
        case heightFraction
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(center, forKey: .center)
        try container.encode(widthFraction, forKey: .widthFraction)
        try container.encode(heightFraction, forKey: .heightFraction)
    }
}
