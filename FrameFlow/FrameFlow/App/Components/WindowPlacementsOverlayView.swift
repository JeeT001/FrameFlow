//
//  WindowPlacementsOverlayView.swift
//  FrameFlow
//

import SwiftUI

struct WindowPlacementsOverlayView: View {
    @Bindable var controller: WindowPlacementController
    let windowIDs: [CGWindowID]
    var interactionOnly: Bool = true

    @State private var dragStartCenters: [CGWindowID: CGPoint] = [:]
    @State private var resizeStartSizes: [CGWindowID: CGFloat] = [:]
    @State private var frontWindowID: CGWindowID?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.clear

                ForEach(windowIDs, id: \.self) { windowID in
                    if let rect = controller.canvasRect(
                        for: windowID,
                        canvasSize: geometry.size,
                        coordinateSpace: .swiftUI
                    ) {
                        windowChrome(for: windowID, rect: rect, canvasSize: geometry.size)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(true)
    }

    @ViewBuilder
    private func windowChrome(
        for windowID: CGWindowID,
        rect: CGRect,
        canvasSize: CGSize
    ) -> some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.clear)
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(AppColors.primary.opacity(0.85), lineWidth: 2)

            resizeHandle
                .padding(4)
                .gesture(resizeGesture(for: windowID, in: canvasSize))
        }
        .frame(width: rect.width, height: rect.height)
        .offset(x: rect.minX, y: rect.minY)
        .zIndex(windowID == frontWindowID ? 1 : 0)
        .onTapGesture {
            frontWindowID = windowID
        }
        .gesture(dragGesture(for: windowID, in: canvasSize))
    }

    private var resizeHandle: some View {
        Circle()
            .fill(Color.white.opacity(0.95))
            .frame(width: 18, height: 18)
            .overlay {
                Circle().stroke(Color.black.opacity(0.3), lineWidth: 1)
            }
            .shadow(radius: 2, y: 1)
    }

    private func dragGesture(for windowID: CGWindowID, in canvasSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                frontWindowID = windowID
                if dragStartCenters[windowID] == nil {
                    dragStartCenters[windowID] = controller.placements[windowID]?.center
                }
                guard let start = dragStartCenters[windowID] else { return }
                let dx = value.translation.width / canvasSize.width
                let dy = value.translation.height / canvasSize.height
                let newCenter = CGPoint(x: start.x + dx, y: start.y - dy)
                controller.updatePosition(windowID: windowID, center: newCenter, canvasSize: canvasSize)
            }
            .onEnded { _ in
                dragStartCenters[windowID] = nil
            }
    }

    private func resizeGesture(for windowID: CGWindowID, in canvasSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if resizeStartSizes[windowID] == nil {
                    resizeStartSizes[windowID] = controller.placements[windowID]?.widthFraction
                }
                guard let start = resizeStartSizes[windowID] else { return }
                let delta = value.translation.width / canvasSize.width
                controller.updateSize(
                    windowID: windowID,
                    widthFraction: start + delta,
                    canvasSize: canvasSize
                )
            }
            .onEnded { _ in
                resizeStartSizes[windowID] = nil
            }
    }
}
