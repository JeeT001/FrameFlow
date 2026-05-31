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
    var errorMessage: String?
    var permissionDenied = false
    var showUpgradeSheet = false

    func selectionLimit(isPro: Bool) -> Int {
        if isPro {
            return min(4, DeviceCapabilityManager.shared.maxWindows)
        }
        return 2
    }

    func loadWindows(isPro: Bool) async {
        isLoading = true
        errorMessage = nil
        permissionDenied = false
        defer { isLoading = false }

        guard await WindowCaptureService.shared.checkPermission() else {
            permissionDenied = true
            windows = []
            return
        }

        do {
            windows = try await WindowCaptureService.shared.fetchWindows()
            let validIDs = Set(windows.map(\.id))
            selectedIDs = selectedIDs.intersection(validIDs)
        } catch let error as WindowCaptureError {
            if case .permissionDenied = error {
                permissionDenied = true
            } else {
                errorMessage = error.localizedDescription
            }
            windows = []
        } catch {
            errorMessage = error.localizedDescription
            windows = []
        }
    }

    func refresh(isPro: Bool) async {
        await loadWindows(isPro: isPro)
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
