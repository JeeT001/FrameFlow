//
//  RenderingCIContext.swift
//  FrameFlow
//

import CoreImage

/// Single GPU-backed CIContext for composite + writer pixel-buffer renders (Day 45).
enum RenderingCIContext {
    static let shared = CIContext(options: [.useSoftwareRenderer: false])
}
