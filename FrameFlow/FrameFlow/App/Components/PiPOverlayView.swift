//
//  PiPOverlayView.swift
//  FrameFlow
//

import CoreImage
import SwiftUI

struct PiPOverlayView: View {
    @Bindable var controller: PiPController
    let cameraFrame: CIImage?

    @State private var dragStartCenter: CGPoint?
    @State private var resizeStartSize: CGFloat?

    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    var body: some View {
        GeometryReader { geometry in
            if controller.isCameraEnabled {
                let rect = pipRect(in: geometry.size)
                ZStack(alignment: .bottomTrailing) {
                    cameraContent(in: rect)
                        .overlay {
                            shapeStroke
                        }
                        .clipShape(shapePath(in: rect))
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .gesture(dragGesture(in: geometry.size))

                    resizeHandle
                        .position(x: rect.maxX - 10, y: rect.maxY - 10)
                        .gesture(resizeGesture(in: geometry.size))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .allowsHitTesting(controller.isCameraEnabled)
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

    private func pipRect(in size: CGSize) -> CGRect {
        let width = size.width * controller.config.size
        let height = width * 9.0 / 16.0
        let center = CGPoint(
            x: controller.config.position.x * size.width,
            y: (1 - controller.config.position.y) * size.height
        )
        return CGRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        )
    }

    private func dragGesture(in canvasSize: CGSize) -> some Gesture {
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
            }
            .onEnded { _ in
                dragStartCenter = nil
            }
    }

    private func resizeGesture(in canvasSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if resizeStartSize == nil {
                    resizeStartSize = controller.config.size
                }
                guard let start = resizeStartSize else { return }
                let delta = value.translation.width / canvasSize.width
                controller.updateSize(start + delta, canvasSize: canvasSize)
            }
            .onEnded { _ in
                resizeStartSize = nil
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
