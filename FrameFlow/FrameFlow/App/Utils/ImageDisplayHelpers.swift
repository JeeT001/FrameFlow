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

    static func hasDisplayableThumbnail(_ cgImage: CGImage?) -> Bool {
        guard let cgImage else { return false }
        return !isLikelyBlankThumbnail(cgImage)
    }

    /// Samples a downscaled center region; treats near-black captures as failed thumbnails.
    static func isLikelyBlankThumbnail(_ cgImage: CGImage, luminanceThreshold: Double = 0.08) -> Bool {
        let sampleSize = 32
        var pixelData = [UInt8](repeating: 0, count: sampleSize * sampleSize * 4)

        guard let context = CGContext(
            data: &pixelData,
            width: sampleSize,
            height: sampleSize,
            bitsPerComponent: 8,
            bytesPerRow: sampleSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return true
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        var totalLuminance = 0.0
        let pixelCount = sampleSize * sampleSize
        for index in 0..<pixelCount {
            let base = index * 4
            let red = Double(pixelData[base]) / 255.0
            let green = Double(pixelData[base + 1]) / 255.0
            let blue = Double(pixelData[base + 2]) / 255.0
            totalLuminance += 0.2126 * red + 0.7152 * green + 0.0722 * blue
        }

        return (totalLuminance / Double(pixelCount)) < luminanceThreshold
    }
}

extension String {
    var truncatedWindowTitle: String {
        if count <= 42 { return self }
        return String(prefix(39)) + "…"
    }
}
