//
//  WindowCaptureService.swift
//  FrameFlow
//

import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

enum WindowCaptureError: LocalizedError {
    case permissionDenied
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Screen recording permission is required to list windows. Enable FrameFlow in System Settings → Privacy & Security → Screen Recording."
        case .fetchFailed(let message):
            message
        }
    }
}

@MainActor
final class WindowCaptureService {
    static let shared = WindowCaptureService()

    static let frameFlowBundleIdentifier = "com.Simranjit.FrameFlow"
    private static let maxConcurrentThumbnails = 4
    private static let thumbnailWidth = 320
    private static let minimumThumbnailDimension: CGFloat = 120

    private var scWindowsByID: [CGWindowID: SCWindow] = [:]

    private init() {}

    /// Uses `PermissionManager` so screen-recording checks stay in one place.
    func checkPermission() async -> Bool {
        await PermissionManager.shared.checkScreenRecordingPermission()
    }

    /// Returns capturable on-screen windows with optional thumbnails. Retains `SCWindow` references internally for Day 16.
    func fetchWindows() async throws -> [WindowItem] {
        guard await checkPermission() else {
            throw WindowCaptureError.permissionDenied
        }

        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(
                true,
                onScreenWindowsOnly: true
            )
        } catch {
            throw WindowCaptureError.permissionDenied
        }

        let excludedBundleIDs = excludedBundleIdentifiers()
        let capturableWindows = content.windows.filter { window in
            shouldInclude(window: window, excludedBundleIDs: excludedBundleIDs)
        }

        scWindowsByID = Dictionary(
            uniqueKeysWithValues: capturableWindows.map { ($0.windowID, $0) }
        )

        let thumbnails = await captureThumbnails(for: capturableWindows)

        let items = capturableWindows.map { window in
            let bundleID = window.owningApplication?.bundleIdentifier
            return WindowItem(
                id: window.windowID,
                title: normalizedTitle(for: window),
                appName: window.owningApplication?.applicationName ?? "Unknown",
                bundleIdentifier: bundleID,
                thumbnail: thumbnails[window.windowID] ?? nil,
                appIcon: appIcon(for: window)
            )
        }
        .sorted { lhs, rhs in
            if lhs.appName != rhs.appName {
                return lhs.appName.localizedCaseInsensitiveCompare(rhs.appName) == .orderedAscending
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }

        print("[WindowCaptureService] fetchWindows: \(items.count) window(s)")
        return items
    }

    /// Resolves the live `SCWindow` captured during the last successful `fetchWindows()` call.
    func scWindow(for id: CGWindowID) -> SCWindow? {
        scWindowsByID[id]
    }

    #if DEBUG
    func debugLogWindowFetch() async {
        do {
            let windows = try await fetchWindows()
            let withThumbs = windows.filter { $0.thumbnail != nil }.count
            print(
                "[WindowCaptureService] fetchWindows: \(windows.count) window(s), \(withThumbs) thumbnail(s)"
            )
            for item in windows.prefix(8) {
                print("  - \(item.appName): \(item.title) (id: \(item.id))")
            }
            if windows.count > 8 {
                print("  … and \(windows.count - 8) more")
            }
        } catch {
            print("[WindowCaptureService] fetchWindows failed: \(error.localizedDescription)")
        }
    }
    #endif

    private func excludedBundleIdentifiers() -> Set<String> {
        var ids: Set<String> = [Self.frameFlowBundleIdentifier]
        if let mainBundleID = Bundle.main.bundleIdentifier {
            ids.insert(mainBundleID)
        }
        return ids
    }

    private func shouldInclude(window: SCWindow, excludedBundleIDs: Set<String>) -> Bool {
        guard window.isOnScreen else { return false }

        let rawTitle = window.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawTitle.isEmpty else {
            return false
        }

        if let bundleID = window.owningApplication?.bundleIdentifier,
           excludedBundleIDs.contains(bundleID) {
            return false
        }

        if let owningApp = window.owningApplication,
           owningApp.processID == ProcessInfo.processInfo.processIdentifier {
            return false
        }

        if rawTitle == "Desktop", window.owningApplication?.bundleIdentifier == nil {
            return false
        }

        if rawTitle.hasPrefix("Wallpaper-") {
            return false
        }

        return true
    }

    private func normalizedTitle(for window: SCWindow) -> String {
        let raw = window.title ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Window" : trimmed
    }

    private func appIcon(for window: SCWindow) -> NSImage? {
        guard let bundleID = window.owningApplication?.bundleIdentifier else {
            return nil
        }

        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }

        if let pid = window.owningApplication?.processID,
           let app = NSRunningApplication(processIdentifier: pid) {
            return app.icon
        }

        return nil
    }

    private func captureThumbnails(for windows: [SCWindow]) async -> [CGWindowID: CGImage] {
        let windowsForThumbnails = windows.filter { window in
            window.frame.width >= Self.minimumThumbnailDimension
                && window.frame.height >= Self.minimumThumbnailDimension
        }

        var results: [CGWindowID: CGImage] = [:]

        for chunkStart in stride(from: 0, to: windowsForThumbnails.count, by: Self.maxConcurrentThumbnails) {
            let chunkEnd = min(chunkStart + Self.maxConcurrentThumbnails, windowsForThumbnails.count)
            let chunk = Array(windowsForThumbnails[chunkStart..<chunkEnd])

            await withTaskGroup(of: (CGWindowID, CGImage?).self) { group in
                for window in chunk {
                    group.addTask {
                        let image = await self.captureThumbnail(for: window)
                        return (window.windowID, image)
                    }
                }

                for await (windowID, image) in group {
                    if let image {
                        results[windowID] = image
                    }
                }
            }
        }

        return results
    }

    private func captureThumbnail(for window: SCWindow) async -> CGImage? {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        configuration.showsCursor = false
        configuration.captureResolution = .best

        let frame = window.frame
        let width = max(frame.width, 1)
        let height = max(frame.height, 1)
        let scale = Double(Self.thumbnailWidth) / Double(width)
        configuration.width = Self.thumbnailWidth
        configuration.height = max(1, Int(Double(height) * scale))

        do {
            return try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
        } catch {
            return nil
        }
    }
}
