//
//  AppUpdaterController.swift
//  FrameFlow
//

import Sparkle

/// Owns Sparkle's `SPUStandardUpdaterController` for the app lifetime (manual + automatic checks).
@MainActor
@Observable
final class AppUpdaterController {
    private let standardUpdaterController: SPUStandardUpdaterController

    var updater: SPUUpdater {
        standardUpdaterController.updater
    }

    init() {
        standardUpdaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        standardUpdaterController.checkForUpdates(nil)
    }
}
