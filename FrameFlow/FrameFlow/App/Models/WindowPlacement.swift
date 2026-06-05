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
}
