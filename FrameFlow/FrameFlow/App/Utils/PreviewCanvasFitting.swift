//
//  PreviewCanvasFitting.swift
//  FrameFlow
//

import CoreGraphics

enum PreviewCanvasFitting {
    static func fittedSize(in available: CGSize, aspectRatio: CGFloat) -> CGSize {
        var width = available.width
        var height = width / aspectRatio
        if height > available.height {
            height = available.height
            width = height * aspectRatio
        }
        return CGSize(width: width, height: height)
    }
}
