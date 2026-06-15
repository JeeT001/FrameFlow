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
            "Screen recording permission is required to list windows. Enable \(AppBranding.name) in System Settings → Privacy & Security → Screen Recording."
        case .fetchFailed(let message):
            message
        }
    }
}

@MainActor
final class WindowCaptureService {
    static let shared = WindowCaptureService()

    static let frameFlowBundleIdentifier = "com.Simranjit.FrameFlow"
    private static let listFetchTimeoutSeconds: UInt64 = 10
    /// Picker listing — skip 1px system layers; still allow occluded windows when FrameFlow is fullscreen.
    private static let minimumPickerWindowDimension: CGFloat = 50

    private var scWindowsByID: [CGWindowID: SCWindow] = [:]

    private init() {}

    /// Uses `PermissionManager` so screen-recording checks stay in one place.
    func checkPermission() async -> Bool {
        await PermissionManager.shared.checkScreenRecordingPermission()
    }

    /// Phase 1 — fast window list for the picker (no thumbnails).
    /// Uses `onScreenWindowsOnly: false` so third-party windows remain listable when Drazlo is fullscreen.
    func fetchWindowList() async throws -> [WindowItem] {
        guard await checkPermission() else {
            throw WindowCaptureError.permissionDenied
        }

        let started = ContinuousClock.now
        let content: SCShareableContent
        do {
            content = try await Self.fetchShareableContentWithTimeout(
                timeoutSeconds: Self.listFetchTimeoutSeconds
            )
        } catch let error as WindowCaptureError {
            throw error
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

        let items = capturableWindows.map { window in
            windowItem(from: window, thumbnail: nil)
        }
        .sorted(by: sortWindowItems)

        #if DEBUG
        let offScreenIncluded = capturableWindows.filter { !$0.isOnScreen }.count
        let elapsed = started.duration(to: .now)
        print(
            "[WindowCaptureService] fetchWindowList: sc=\(content.windows.count) " +
            "included=\(capturableWindows.count) offScreenIncluded=\(offScreenIncluded) " +
            "elapsedMs=\(Int(elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000))"
        )
        #endif

        return items
    }

    /// Phase 2 — capture thumbnails for on-screen windows only; merges by ID on the caller side.
    func fetchThumbnails(for windowIDs: [CGWindowID]) async -> [CGWindowID: CGImage] {
        let windows = windowIDs.compactMap { scWindowsByID[$0] }
        guard !windows.isEmpty else { return [:] }

        let started = ContinuousClock.now
        let thumbnails = await WindowThumbnailCapture.captureThumbnails(for: windows)

        #if DEBUG
        let elapsed = started.duration(to: .now)
        print(
            "[WindowCaptureService] fetchThumbnails: attempted=\(windows.filter(\.isOnScreen).count) " +
            "succeeded=\(thumbnails.count) elapsedMs=\(Int(elapsed.components.seconds * 1000))"
        )
        #endif

        return thumbnails
    }

    /// Full fetch — list + thumbnails (debug / legacy callers).
    func fetchWindows() async throws -> [WindowItem] {
        var items = try await fetchWindowList()
        let thumbnails = await fetchThumbnails(for: items.map(\.id))
        items = items.map { item in
            guard let thumbnail = thumbnails[item.id] else { return item }
            return windowItem(from: item, thumbnail: thumbnail)
        }
        return items
    }

    /// Resolves the live `SCWindow` captured during the last successful list fetch.
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

    private static func fetchShareableContentWithTimeout(timeoutSeconds: UInt64) async throws -> SCShareableContent {
        try await withThrowingTaskGroup(of: SCShareableContent.self) { group in
            group.addTask {
                try await SCShareableContent.excludingDesktopWindows(
                    true,
                    onScreenWindowsOnly: false
                )
            }
            group.addTask {
                try await Task.sleep(nanoseconds: timeoutSeconds * 1_000_000_000)
                throw WindowCaptureError.fetchFailed(
                    "Timed out loading windows. Check Screen Recording permission and try Refresh."
                )
            }
            guard let content = try await group.next() else {
                throw WindowCaptureError.fetchFailed("Could not load windows.")
            }
            group.cancelAll()
            return content
        }
    }

    private func excludedBundleIdentifiers() -> Set<String> {
        var ids: Set<String> = [Self.frameFlowBundleIdentifier]
        if let mainBundleID = Bundle.main.bundleIdentifier {
            ids.insert(mainBundleID)
        }
        return ids
    }

    private func shouldInclude(window: SCWindow, excludedBundleIDs: Set<String>) -> Bool {
        let frame = window.frame
        guard frame.width >= Self.minimumPickerWindowDimension,
              frame.height >= Self.minimumPickerWindowDimension else {
            return false
        }

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

    private func windowItem(from window: SCWindow, thumbnail: CGImage?) -> WindowItem {
        WindowItem(
            id: window.windowID,
            title: normalizedTitle(for: window),
            appName: window.owningApplication?.applicationName ?? "Unknown",
            bundleIdentifier: window.owningApplication?.bundleIdentifier,
            thumbnail: thumbnail,
            appIcon: appIcon(for: window)
        )
    }

    private func windowItem(from item: WindowItem, thumbnail: CGImage) -> WindowItem {
        WindowItem(
            id: item.id,
            title: item.title,
            appName: item.appName,
            bundleIdentifier: item.bundleIdentifier,
            thumbnail: thumbnail,
            appIcon: item.appIcon
        )
    }

    private func sortWindowItems(_ lhs: WindowItem, _ rhs: WindowItem) -> Bool {
        if lhs.appName != rhs.appName {
            return lhs.appName.localizedCaseInsensitiveCompare(rhs.appName) == .orderedAscending
        }
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}

// MARK: - Off-main thumbnail capture

private enum WindowThumbnailCapture {
    static let maxConcurrent = 4
    static let thumbnailWidth = 320
    static let minimumThumbnailDimension: CGFloat = 120
    static let maxThumbnailCount = 24
    static let perThumbnailTimeoutNanoseconds: UInt64 = 4_000_000_000

    static func captureThumbnails(for windows: [SCWindow]) async -> [CGWindowID: CGImage] {
        let candidates = windows
            .filter { window in
                window.isOnScreen
                    && window.frame.width >= minimumThumbnailDimension
                    && window.frame.height >= minimumThumbnailDimension
            }
            .sorted { lhs, rhs in
                (lhs.frame.width * lhs.frame.height) > (rhs.frame.width * rhs.frame.height)
            }
            .prefix(maxThumbnailCount)

        var results: [CGWindowID: CGImage] = [:]
        let candidateArray = Array(candidates)

        for chunkStart in stride(from: 0, to: candidateArray.count, by: maxConcurrent) {
            if Task.isCancelled { break }
            let chunkEnd = min(chunkStart + maxConcurrent, candidateArray.count)
            let chunk = Array(candidateArray[chunkStart..<chunkEnd])

            await withTaskGroup(of: (CGWindowID, CGImage?).self) { group in
                for window in chunk {
                    group.addTask {
                        let image = await captureThumbnailWithTimeout(for: window)
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

    private static func captureThumbnailWithTimeout(for window: SCWindow) async -> CGImage? {
        await withTaskGroup(of: CGImage?.self) { group in
            group.addTask {
                await captureThumbnail(for: window)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: perThumbnailTimeoutNanoseconds)
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result ?? nil
        }
    }

    private static func captureThumbnail(for window: SCWindow) async -> CGImage? {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        configuration.showsCursor = false
        configuration.captureResolution = .best

        let frame = window.frame
        let width = max(frame.width, 1)
        let height = max(frame.height, 1)
        let scale = Double(thumbnailWidth) / Double(width)
        configuration.width = thumbnailWidth
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
