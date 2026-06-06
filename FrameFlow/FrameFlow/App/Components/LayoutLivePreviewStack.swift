//
//  LayoutLivePreviewStack.swift
//  FrameFlow
//

import CoreImage
import SwiftUI

struct LayoutLivePreviewStack: View {
    let image: CGImage?
    let aspectRatio: CGFloat
    let referenceCanvasSize: CGSize
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
                    .onChange(of: windowPlacementController.placements) { _, _ in
                        onPlacementsChanged?()
                    }
                }

                if showPiPOverlay, pipController.isCameraEnabled {
                    PiPOverlayView(
                        controller: pipController,
                        cameraFrame: cameraFrame
                    )
                    .frame(width: referenceCanvasSize.width, height: referenceCanvasSize.height)
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
