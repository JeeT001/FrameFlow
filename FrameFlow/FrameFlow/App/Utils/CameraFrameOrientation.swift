//
//  CameraFrameOrientation.swift
//  FrameFlow
//

import CoreImage

enum CameraFrameOrientation {
    /// Normalize webcam CIImage for display (SwiftUI) and CI compositing.
    /// Apply once at capture — nowhere else.
    static func normalize(_ frame: CIImage, mirrored: Bool = false) -> CIImage {
        var image = frame
        let extent = image.extent

        // macOS FaceTime buffers: no vertical flip needed (toggle here only if still wrong).
        let flipVertical = false
        if flipVertical {
            image = image.transformed(
                by: CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -extent.height)
            )
        }

        if mirrored {
            let mirroredExtent = image.extent
            image = image.transformed(
                by: CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: mirroredExtent.width, y: 0)
            )
        }

        return image
    }
}
