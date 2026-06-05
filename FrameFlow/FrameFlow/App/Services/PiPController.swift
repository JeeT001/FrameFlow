//
//  PiPController.swift
//  FrameFlow
//

import CoreGraphics
import Foundation

enum PiPShape: String, CaseIterable {
    case roundedRect
    case circle
}

enum PiPBorderStyle: String, CaseIterable {
    case white
    case blue
    case black
}

struct PiPConfig: Equatable {
    var position: CGPoint // normalized center: x 0=left 1=right; y 0=bottom 1=top
    var size: CGFloat // normalized width fraction
    var shape: PiPShape
    var borderColor: PiPBorderStyle
    var borderWidth: CGFloat
}

enum PiPPreset: String, CaseIterable, Identifiable {
    case bottomRight
    case bottomLeft
    case topRight
    case faceTop
    case faceLeft
    case noCamera

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bottomRight: "Bottom-Right"
        case .bottomLeft: "Bottom-Left"
        case .topRight: "Top-Right"
        case .faceTop: "Face-Top (9:16)"
        case .faceLeft: "Face-Left"
        case .noCamera: "No Camera"
        }
    }
}

@MainActor
@Observable
final class PiPController {
    static let shared = PiPController()

    var isCameraEnabled = false
    var selectedCameraID: String?
    var selectedPreset: PiPPreset = .bottomRight
    var config: PiPConfig = PiPController.config(for: .bottomRight)
    var allowsOverflow: Bool = false

    private init() {}

    func applyPreset(_ preset: PiPPreset) {
        selectedPreset = preset
        if preset == .noCamera {
            isCameraEnabled = false
        } else {
            isCameraEnabled = true
            config = Self.config(for: preset)
        }
    }

    func updatePosition(_ centerPoint: CGPoint, canvasSize: CGSize) {
        if allowsOverflow {
            config.position = centerPoint
        } else {
            let clamped = PiPLayoutMath.clampedPosition(centerPoint, size: config.size, canvasSize: canvasSize)
            config.position = snapped(position: clamped, canvasSize: canvasSize)
        }
    }

    func updateSize(_ normalizedWidth: CGFloat, canvasSize: CGSize) {
        let minSize: CGFloat = 0.12
        let maxSize: CGFloat = allowsOverflow ? 2.5 : 0.5
        config.size = min(max(normalizedWidth, minSize), maxSize)
        if !allowsOverflow {
            config.position = PiPLayoutMath.clampedPosition(config.position, size: config.size, canvasSize: canvasSize)
            config.position = snapped(position: config.position, canvasSize: canvasSize)
        }
    }

    func normalizePositionForCanvas(format: RecordingFormat) {
        guard isCameraEnabled, !allowsOverflow else { return }
        let refSize = CompositeEngine.shared.outputSize(for: format)
        config.position = PiPLayoutMath.clampedPosition(config.position, size: config.size, canvasSize: refSize)
    }

    private func snapped(position: CGPoint, canvasSize: CGSize) -> CGPoint {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return position }
        let thresholdX = 20 / canvasSize.width
        let thresholdY = 20 / canvasSize.height
        let halfWidth = config.size / 2
        let halfHeight = (config.size * 9.0 / 16.0) / 2

        var x = position.x
        var y = position.y
        if abs(position.x - halfWidth) < thresholdX { x = halfWidth }
        if abs(position.x - (1 - halfWidth)) < thresholdX { x = 1 - halfWidth }
        if abs(position.y - halfHeight) < thresholdY { y = halfHeight }
        if abs(position.y - (1 - halfHeight)) < thresholdY { y = 1 - halfHeight }

        return CGPoint(x: x, y: y)
    }

    static func config(for preset: PiPPreset) -> PiPConfig {
        switch preset {
        case .bottomRight:
            return PiPConfig(position: CGPoint(x: 0.84, y: 0.18), size: 0.24, shape: .roundedRect, borderColor: .white, borderWidth: 2)
        case .bottomLeft:
            return PiPConfig(position: CGPoint(x: 0.16, y: 0.18), size: 0.24, shape: .roundedRect, borderColor: .white, borderWidth: 2)
        case .topRight:
            return PiPConfig(position: CGPoint(x: 0.84, y: 0.82), size: 0.24, shape: .roundedRect, borderColor: .white, borderWidth: 2)
        case .faceTop:
            return PiPConfig(position: CGPoint(x: 0.5, y: 0.82), size: 0.34, shape: .roundedRect, borderColor: .blue, borderWidth: 2)
        case .faceLeft:
            return PiPConfig(position: CGPoint(x: 0.2, y: 0.5), size: 0.3, shape: .circle, borderColor: .white, borderWidth: 2)
        case .noCamera:
            return PiPConfig(position: CGPoint(x: 0.84, y: 0.18), size: 0.24, shape: .roundedRect, borderColor: .white, borderWidth: 2)
        }
    }
}
