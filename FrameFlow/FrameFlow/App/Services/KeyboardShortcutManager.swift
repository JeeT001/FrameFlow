//
//  KeyboardShortcutManager.swift
//  FrameFlow
//

import AppKit
import Foundation

@MainActor
protocol RecordingKeyboardShortcutHandling: AnyObject {
    func shortcutTogglePauseResume()
    func shortcutStopRecording()
    func shortcutZoomIn()
    func shortcutZoomOut()
    func shortcutResetZoom()
    func shortcutToggleAutoFocus()
    func shortcutToggleCursorHighlight()
    func shortcutTogglePiPCamera()
    func shortcutDiscardRecording()
}

@MainActor
final class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()

    private weak var handler: RecordingKeyboardShortcutHandling?
    private var isEnabled = false
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private init() {}

    func start(handler: RecordingKeyboardShortcutHandling) {
        stop()
        self.handler = handler
        isEnabled = true

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleKeyDown(event)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return handleKeyDown(event, isLocal: true)
        }
    }

    func stop() {
        isEnabled = false
        handler = nil

        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }

        globalMonitor = nil
        localMonitor = nil
    }

    deinit {
        let globalMonitor = self.globalMonitor
        let localMonitor = self.localMonitor
        DispatchQueue.main.async {
            if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
            if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        }
    }

    @discardableResult
    private func handleKeyDown(_ event: NSEvent, isLocal: Bool = false) -> NSEvent? {
        guard isEnabled, !event.isARepeat else { return event }
        guard event.modifierFlags.contains(.command) else { return event }
        guard !event.modifierFlags.contains(.option), !event.modifierFlags.contains(.control) else { return event }

        let handled: Bool
        switch event.keyCode {
        case 15: // R
            handler?.shortcutStopRecording()
            handled = true
        case 35: // P
            handler?.shortcutTogglePauseResume()
            handled = true
        case 24: // = / +
            handler?.shortcutZoomIn()
            handled = true
        case 27: // -
            handler?.shortcutZoomOut()
            handled = true
        case 29: // 0
            handler?.shortcutResetZoom()
            handled = true
        case 3: // F
            handler?.shortcutToggleAutoFocus()
            handled = true
        case 4: // H
            handler?.shortcutToggleCursorHighlight()
            handled = true
        case 40: // K
            handler?.shortcutTogglePiPCamera()
            handled = true
        case 53: // Escape
            handler?.shortcutDiscardRecording()
            handled = true
        default:
            handled = false
        }

        if handled, isLocal {
            return nil
        }
        return event
    }
}
