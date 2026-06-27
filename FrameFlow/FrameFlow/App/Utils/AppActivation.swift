//
//  AppActivation.swift
//  FrameFlow
//

import AppKit

enum AppActivation {
    static func bringToForeground() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.windows.first { $0.canBecomeKey }?.makeKeyAndOrderFront(nil)
    }
}
