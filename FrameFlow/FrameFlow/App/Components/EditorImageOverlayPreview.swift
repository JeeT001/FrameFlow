//
//  EditorImageOverlayPreview.swift
//  FrameFlow
//

import SwiftUI

struct EditorImageOverlayPreview: View {
    let overlay: EditorImageOverlay
    let containerAspect: Double
    let currentPlayhead: Double
    var isEditable: Bool = false
    var onPositionChange: ((Double, Double) -> Void)? = nil
    var onSizeChange: ((Double) -> Void)? = nil
    var onSelect: (() -> Void)? = nil

    @State private var dragStartCenterX: Double?
    @State private var dragStartCenterY: Double?
    @State private var dragStartWidth: Double?

    var body: some View {
        GeometryReader { geometry in
            if overlay.contains(playhead: currentPlayhead),
               let nsImage = NSImage(contentsOf: overlay.fileURL) {
                let imageAspect = nsImage.size.height / max(nsImage.size.width, 1)
                let width = geometry.size.width * overlay.normalizedWidth
                let height = width * imageAspect
                let x = geometry.size.width * overlay.normalizedCenterX
                let y = geometry.size.height * (1 - overlay.normalizedCenterY)

                ZStack {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: width, height: height)
                        .opacity(overlay.opacity)
                        .overlay {
                            if isEditable {
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(
                                        AppColors.proGold.opacity(0.9),
                                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                                    )
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            if isEditable {
                                resizeHandle(containerWidth: geometry.size.width)
                            }
                        }
                        .position(x: x, y: y)
                        .gesture(positionDragGesture(
                            containerSize: geometry.size,
                            imageAspect: imageAspect
                        ))
                        .onTapGesture {
                            onSelect?()
                        }
                }
            }
        }
        .clipped()
        .allowsHitTesting(isEditable)
    }

    private func resizeHandle(containerWidth: CGFloat) -> some View {
        Circle()
            .fill(AppColors.proGold)
            .frame(width: 12, height: 12)
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
            }
            .offset(x: 6, y: 6)
            .highPriorityGesture(resizeDragGesture(containerWidth: containerWidth))
    }

    private func positionDragGesture(containerSize: CGSize, imageAspect: Double) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard isEditable else { return }
                if dragStartCenterX == nil {
                    dragStartCenterX = overlay.normalizedCenterX
                    dragStartCenterY = overlay.normalizedCenterY
                }
                guard containerSize.width > 0, containerSize.height > 0 else { return }

                let startX = dragStartCenterX ?? overlay.normalizedCenterX
                let startY = dragStartCenterY ?? overlay.normalizedCenterY
                let deltaX = Double(value.translation.width / containerSize.width)
                let deltaY = -Double(value.translation.height / containerSize.height)

                let proposedX = startX + deltaX
                let proposedY = startY + deltaY
                let clamped = overlay.clampedCenter(
                    x: proposedX,
                    y: proposedY,
                    containerAspect: containerAspect,
                    imageAspect: imageAspect
                )
                onPositionChange?(clamped.x, clamped.y)
            }
            .onEnded { _ in
                dragStartCenterX = nil
                dragStartCenterY = nil
            }
    }

    private func resizeDragGesture(containerWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard isEditable, containerWidth > 0 else { return }
                if dragStartWidth == nil {
                    dragStartWidth = overlay.normalizedWidth
                }
                guard let startWidth = dragStartWidth else { return }

                let delta = Double(value.translation.width / containerWidth)
                let proposed = overlay.clampedWidth(startWidth + delta)
                onSizeChange?(proposed)
            }
            .onEnded { _ in
                dragStartWidth = nil
            }
    }
}
