//
//  PiPOverlayView.swift
//  FrameFlow
//

import CoreImage
import SwiftUI

struct PiPOverlayView: View {
    @Bindable var controller: PiPController
    let cameraFrame: CIImage?
    let canvasSize: CGSize
    var interactionOnly: Bool = false
    var onChanged: (() -> Void)?

    @State private var dragStartCenter: CGPoint?
    @State private var resizeStartSize: CGFloat?

    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    var body: some View {
        if controller.isCameraEnabled {
            let rect = controller.allowsOverflow
                ? PiPLayoutMath.pipRectUnclamped(
                    config: controller.config,
                    canvasSize: canvasSize,
                    coordinateSpace: .swiftUI
                )
                : PiPLayoutMath.pipRect(
                    config: controller.config,
                    canvasSize: canvasSize,
                    coordinateSpace: .swiftUI
                )

            ZStack(alignment: .bottomTrailing) {
                if interactionOnly {
                    shapePath(in: rect)
                        .fill(Color.clear)
                        .contentShape(shapePath(in: rect))
                        .overlay { shapeStroke }
                } else {
                    cameraContent(in: rect)
                        .overlay { shapeStroke }
                        .clipShape(shapePath(in: rect))
                }

                resizeHandle
                    .padding(4)
                    .gesture(resizeGesture)
            }
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .gesture(dragGesture)
        }
    }

    @ViewBuilder
    private func cameraContent(in rect: CGRect) -> some View {
        if let frame = cameraFrame,
           let cgImage = Self.ciContext.createCGImage(frame, from: frame.extent) {
            Image(decorative: cgImage, scale: 1.0)
                .resizable()
                .scaledToFill()
                .frame(width: rect.width, height: rect.height)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
                Image(systemName: "video.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var shapeStroke: some View {
        Group {
            switch controller.config.shape {
            case .roundedRect:
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: controller.config.borderWidth)
            case .circle:
                Circle()
                    .stroke(borderColor, lineWidth: controller.config.borderWidth)
            }
        }
    }

    private var resizeHandle: some View {
        Circle()
            .fill(Color.white.opacity(0.95))
            .frame(width: 20, height: 20)
            .overlay {
                Circle().stroke(Color.black.opacity(0.3), lineWidth: 1)
            }
            .shadow(radius: 2, y: 1)
    }

    private var borderColor: Color {
        switch controller.config.borderColor {
        case .white: .white
        case .blue: .blue
        case .black: .black
        }
    }

    private func shapePath(in rect: CGRect) -> some Shape {
        switch controller.config.shape {
        case .roundedRect:
            return AnyShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        case .circle:
            return AnyShape(Circle())
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if dragStartCenter == nil {
                    dragStartCenter = controller.config.position
                }
                guard let start = dragStartCenter else { return }
                let dx = value.translation.width / canvasSize.width
                let dy = value.translation.height / canvasSize.height
                let newCenter = CGPoint(x: start.x + dx, y: start.y - dy)
                controller.updatePosition(newCenter, canvasSize: canvasSize)
                onChanged?()
            }
            .onEnded { _ in
                dragStartCenter = nil
                onChanged?()
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if resizeStartSize == nil {
                    resizeStartSize = controller.config.size
                }
                guard let start = resizeStartSize else { return }
                let delta = value.translation.width / canvasSize.width
                controller.updateSize(start + delta, canvasSize: canvasSize)
                onChanged?()
            }
            .onEnded { _ in
                resizeStartSize = nil
                onChanged?()
            }
    }
}

private struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}
