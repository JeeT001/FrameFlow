//
//  LayoutLivePreviewStack.swift
//  FrameFlow
//

import CoreImage
import SwiftUI

struct LayoutLivePreviewStack: View {
    let image: CGImage?
    let aspectRatio: CGFloat
    let layoutPreset: LayoutPreset
    let windowIDs: [CGWindowID]
    @Bindable var pipController: PiPController
    @Bindable var windowPlacementController: WindowPlacementController
    let cameraFrame: CIImage?
    var showPiPOverlay: Bool = true
    var onPlacementsChanged: (() -> Void)?

    private let cornerRadius: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            let canvasSize = PreviewCanvasFitting.fittedSize(
                in: geometry.size,
                aspectRatio: aspectRatio
            )

            ZStack {
                previewImage(canvasSize: canvasSize)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                if layoutPreset == .freeForm {
                    WindowPlacementsOverlayView(
                        controller: windowPlacementController,
                        windowIDs: windowIDs,
                        interactionOnly: true
                    )
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .onChange(of: windowPlacementController.placements) { _, _ in
                        onPlacementsChanged?()
                    }
                }

                if showPiPOverlay, pipController.isCameraEnabled {
                    PiPOverlayView(
                        controller: pipController,
                        cameraFrame: cameraFrame
                    )
                    .frame(width: canvasSize.width, height: canvasSize.height)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.border)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func previewImage(canvasSize: CGSize) -> some View {
        if let image {
            Image(decorative: image, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(width: canvasSize.width, height: canvasSize.height)
        } else {
            Color.black.opacity(0.85)
                .frame(width: canvasSize.width, height: canvasSize.height)
        }
    }
}
