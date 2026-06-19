//
//  AuthFocus.swift
//  FrameFlow
//

import AppKit

enum AuthFocus {
    /// Resigns first responder so macOS Passwords / Keychain autofill UI dismisses when leaving auth.
    @MainActor
    static func dismiss() {
        NSApp.keyWindow?.makeFirstResponder(nil)
        NSApp.mainWindow?.makeFirstResponder(nil)
    }
}
