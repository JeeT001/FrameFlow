//
//  LayoutLivePreviewStack.swift
//  FrameFlow
//

import SwiftUI

struct LayoutLivePreviewStack: View {
    let image: CGImage?
    let aspectRatio: CGFloat
    let referenceCanvasSize: CGSize
    let layoutPreset: LayoutPreset
    let windowIDs: [CGWindowID]
    @Bindable var pipController: PiPController
    @Bindable var windowPlacementController: WindowPlacementController
    var showPiPOverlay: Bool = true
    var platformOverlay: PlatformPreviewOverlay = .none
    var onPlacementsChanged: (() -> Void)?
    var onPiPChanged: (() -> Void)?

    private let cornerRadius: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            let fittedSize = PreviewCanvasFitting.fittedSize(
                in: geometry.size,
                aspectRatio: aspectRatio
            )
            let scale = min(
                fittedSize.width / referenceCanvasSize.width,
                fittedSize.height / referenceCanvasSize.height
            )

            ZStack {
                CompositePreviewRepresentable(image: image, contentMode: .fit)
                    .frame(width: referenceCanvasSize.width, height: referenceCanvasSize.height)

                if layoutPreset == .freeForm {
                    WindowPlacementsOverlayView(
                        controller: windowPlacementController,
                        windowIDs: windowIDs,
                        canvasSize: referenceCanvasSize,
                        interactionOnly: true
                    )
                    .frame(width: referenceCanvasSize.width, height: referenceCanvasSize.height)
                    .clipped()
                    .onChange(of: windowPlacementController.placements) { _, _ in
                        onPlacementsChanged?()
                    }
                }

                if showPiPOverlay, pipController.isCameraEnabled {
                    PiPOverlayView(
                        controller: pipController,
                        cameraFrame: nil,
                        canvasSize: referenceCanvasSize,
                        interactionOnly: true,
                        onChanged: onPiPChanged
                    )
                    .frame(width: referenceCanvasSize.width, height: referenceCanvasSize.height)
                }

                if platformOverlay != .none {
                    PlatformSafeZoneOverlayView(
                        platform: platformOverlay,
                        canvasSize: referenceCanvasSize
                    )
                }
            }
            .frame(width: referenceCanvasSize.width, height: referenceCanvasSize.height)
            .scaleEffect(scale, anchor: .center)
            .frame(width: fittedSize.width, height: fittedSize.height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.border)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
