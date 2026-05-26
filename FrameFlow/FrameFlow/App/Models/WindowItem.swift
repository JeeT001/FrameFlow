//
//  WindowItem.swift
//  FrameFlow
//

import AppKit
import CoreGraphics
import Foundation

/// UI-facing window descriptor for the picker (Day 13). Does not embed `SCWindow`.
struct WindowItem: Identifiable {
    let id: CGWindowID
    let title: String
    let appName: String
    let bundleIdentifier: String?
    let thumbnail: CGImage?
    let appIcon: NSImage?
}
