//
//  ActiveWindowMonitor.swift
//  FrameFlow
//

import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

@Observable
final class ActiveWindowMonitor {
    private(set) var activeWindowID: CGWindowID?
    private(set) var statusMessage: String?

    private var selectedWindowIDs: Set<CGWindowID> = []
    private var visibleWindowIDs: Set<CGWindowID> = []
    private var workspaceObserver: NSObjectProtocol?

    @MainActor
    func startMonitoring(selectedWindowIDs: Set<CGWindowID>) {
        stopMonitoring()

        self.selectedWindowIDs = selectedWindowIDs
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleActivation(notification)
        }

        if let frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            updateActiveWindow(forBundleIdentifier: frontmostBundleID)
        }
    }

    @MainActor
    func stopMonitoring() {
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
        workspaceObserver = nil
        activeWindowID = nil
        statusMessage = nil
        selectedWindowIDs = []
        visibleWindowIDs = []
    }

    @MainActor
    func updateVisibleWindowIDs(_ ids: Set<CGWindowID>) {
        visibleWindowIDs = ids
    }

    deinit {
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
    }

    @MainActor
    private func handleActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else {
            statusMessage = "Could not read activated application bundle ID."
            activeWindowID = nil
            return
        }
        updateActiveWindow(forBundleIdentifier: bundleID)
    }

    @MainActor
    private func updateActiveWindow(forBundleIdentifier bundleID: String) {
        let matching = selectedWindowIDs.filter { id in
            WindowCaptureService.shared.scWindow(for: id)?.owningApplication?.bundleIdentifier == bundleID
        }

        guard !matching.isEmpty else {
            activeWindowID = nil
            statusMessage = "No selected window for active app: \(bundleID)"
            return
        }

        let visibleMatches = matching.filter { visibleWindowIDs.contains($0) }
        if let chosenVisible = visibleMatches.sorted().first {
            activeWindowID = chosenVisible
            statusMessage = nil
            return
        }

        activeWindowID = matching.sorted().first
        statusMessage = nil
    }
}
