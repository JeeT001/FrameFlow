//
//  ImageDisplayHelpers.swift
//  FrameFlow
//

import AppKit
import CoreGraphics
import SwiftUI

enum ImageDisplayHelpers {
    static func thumbnailImage(from cgImage: CGImage?) -> Image? {
        guard let cgImage else { return nil }
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        return Image(nsImage: nsImage)
    }

    static func appIconImage(from nsImage: NSImage?) -> Image? {
        guard let nsImage else { return nil }
        return Image(nsImage: nsImage)
    }
}

extension String {
    var truncatedWindowTitle: String {
        if count <= 42 { return self }
        return String(prefix(39)) + "…"
    }
}
