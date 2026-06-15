//
//  WindowPickerViewModel.swift
//  FrameFlow
//

import CoreGraphics
import Foundation

@Observable
@MainActor
final class WindowPickerViewModel {
    var windows: [WindowItem] = []
    var selectedIDs: Set<CGWindowID> = []
    var isLoading = false
    var isRefreshingThumbnails = false
    var errorMessage: String?
    var permissionDenied = false
    var showUpgradeSheet = false

    private var thumbnailTask: Task<Void, Never>?

    func selectionLimit(isPro: Bool) -> Int {
        if isPro {
            return min(4, DeviceCapabilityManager.shared.maxWindows)
        }
        return 2
    }

    func loadWindows(isPro: Bool) async {
        thumbnailTask?.cancel()
        thumbnailTask = nil

        isLoading = true
        isRefreshingThumbnails = false
        errorMessage = nil
        permissionDenied = false

        guard await WindowCaptureService.shared.checkPermission() else {
            permissionDenied = true
            windows = []
            isLoading = false
            return
        }

        do {
            windows = try await WindowCaptureService.shared.fetchWindowList()
            let validIDs = Set(windows.map(\.id))
            selectedIDs = selectedIDs.intersection(validIDs)
        } catch let error as WindowCaptureError {
            if case .permissionDenied = error {
                permissionDenied = true
            } else {
                errorMessage = error.localizedDescription
            }
            windows = []
            isLoading = false
            return
        } catch {
            errorMessage = error.localizedDescription
            windows = []
            isLoading = false
            return
        }

        isLoading = false
        await refreshThumbnails()
    }

    func refresh(isPro: Bool) async {
        await loadWindows(isPro: isPro)
    }

    func cancelThumbnailRefresh() {
        thumbnailTask?.cancel()
        thumbnailTask = nil
        isRefreshingThumbnails = false
    }

    private func refreshThumbnails() async {
        let windowIDs = windows.map(\.id)
        guard !windowIDs.isEmpty else { return }

        thumbnailTask?.cancel()
        let task = Task { @MainActor in
            isRefreshingThumbnails = true
            defer {
                isRefreshingThumbnails = false
                thumbnailTask = nil
            }

            let thumbnails = await WindowCaptureService.shared.fetchThumbnails(for: windowIDs)
            guard !Task.isCancelled else { return }
            applyThumbnails(thumbnails)
        }
        thumbnailTask = task
        await task.value
    }

    private func applyThumbnails(_ thumbnails: [CGWindowID: CGImage]) {
        guard !thumbnails.isEmpty else { return }
        windows = windows.map { item in
            guard let thumbnail = thumbnails[item.id] else { return item }
            return WindowItem(
                id: item.id,
                title: item.title,
                appName: item.appName,
                bundleIdentifier: item.bundleIdentifier,
                thumbnail: thumbnail,
                appIcon: item.appIcon
            )
        }
    }

    func toggleSelection(_ id: CGWindowID, isPro: Bool) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
            return
        }

        let limit = selectionLimit(isPro: isPro)
        guard selectedIDs.count < limit else {
            if !isPro {
                AnalyticsService.trackFeatureBlocked(feature: "four_windows")
                showUpgradeSheet = true
            }
            return
        }

        selectedIDs.insert(id)
    }

    var canProceed: Bool {
        !selectedIDs.isEmpty
    }

    var selectedCount: Int {
        selectedIDs.count
    }
}
