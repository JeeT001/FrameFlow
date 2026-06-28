//
//  WindowPickerView.swift
//  FrameFlow
//

import AppKit
import CoreGraphics
import SwiftUI

struct WindowPickerView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = WindowPickerViewModel()
    @State private var showProGate = false
    @State private var proGateFeature = ""
    @State private var proGateDescription = ""
    @State private var searchText = ""
    @State private var showOtherWindows = false

    private let gridColumns = [
        GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 20),
    ]

    private static let systemNoisePatterns = [
        "windowmanager",
        "gesture blocking",
        "app icon window",
        "overlay",
        "menubar",
        "dock",
    ]

    var body: some View {
        Group {
            if viewModel.permissionDenied {
                permissionDeniedView
            } else if viewModel.isLoading && viewModel.windows.isEmpty {
                loadingView
            } else if let errorMessage = viewModel.errorMessage, viewModel.windows.isEmpty {
                errorView(message: errorMessage)
            } else if viewModel.windows.isEmpty {
                emptyWindowsView
            } else {
                pickerContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("")
        .toolbar { toolbarContent }
        .task {
            await viewModel.loadWindows(isPro: appState.isPro)
        }
        .onDisappear {
            viewModel.cancelThumbnailRefresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            Task { await viewModel.refresh(isPro: appState.isPro) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            Task { await viewModel.refresh(isPro: appState.isPro) }
        }
        .proUpgradeSheet(
            isPresented: $showProGate,
            feature: proGateFeature,
            description: proGateDescription
        )
        .onChange(of: viewModel.showUpgradeSheet) { _, show in
            if show {
                proGateFeature = "Multiple Windows"
                proGateDescription = "Free accounts can select up to 2 windows. Pro unlocks up to 4 windows on supported Macs."
                showProGate = true
                viewModel.showUpgradeSheet = false
            }
        }
    }

    private var pickerContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    WindowPickerHeader()

                    WindowPickerSearchField(searchText: $searchText)

                    WindowPickerStageManagerTip()

                    if viewModel.isRefreshingThumbnails {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Refreshing thumbnails…")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }

                    if searchText.isEmpty == false && searchFilteredWindows.isEmpty {
                        noSearchResultsView
                    } else {
                        LazyVGrid(columns: gridColumns, spacing: 20) {
                            ForEach(searchFilteredWindows) { window in
                                WindowPickerCard(
                                    window: window,
                                    isSelected: viewModel.selectedIDs.contains(window.id)
                                ) {
                                    viewModel.toggleSelection(window.id, isPro: appState.isPro)
                                }
                            }
                        }

                        if showsOtherWindowsToggle {
                            showOtherWindowsButton
                        }
                    }
                }
                .padding(28)
            }

            Divider()

            WindowPickerFooterBar(
                selectedCount: viewModel.selectedCount,
                selectionLimit: viewModel.selectionLimit(isPro: appState.isPro),
                canProceed: viewModel.canProceed,
                isLoading: viewModel.isLoading,
                onNext: proceedToLayoutPicker,
                onRefresh: {
                    Task { await viewModel.refresh(isPro: appState.isPro) }
                }
            )
        }
    }

    private var catalogWindows: [WindowItem] {
        let primary = viewModel.windows.filter {
            ImageDisplayHelpers.hasDisplayableThumbnail($0.thumbnail) && !isHiddenSystemNoise($0)
        }

        if !primary.isEmpty {
            let primaryIDs = Set(primary.map(\.id))
            let secondary = viewModel.windows.filter { !primaryIDs.contains($0.id) && !isHiddenSystemNoise($0) }

            let selectedInSecondary = secondary.contains { viewModel.selectedIDs.contains($0.id) }
            if showOtherWindows || selectedInSecondary {
                return primary + secondary
            }
            return primary
        }

        let withoutNoise = viewModel.windows.filter { !isHiddenSystemNoise($0) }
        return withoutNoise.isEmpty ? viewModel.windows : withoutNoise
    }

    private var searchFilteredWindows: [WindowItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return catalogWindows }
        return catalogWindows.filter {
            $0.appName.lowercased().contains(query) || $0.title.lowercased().contains(query)
        }
    }

    private var hiddenSecondaryCount: Int {
        let primary = viewModel.windows.filter {
            ImageDisplayHelpers.hasDisplayableThumbnail($0.thumbnail) && !isHiddenSystemNoise($0)
        }
        guard !primary.isEmpty else { return 0 }
        let primaryIDs = Set(primary.map(\.id))
        return viewModel.windows.filter { !primaryIDs.contains($0.id) && !isHiddenSystemNoise($0) }.count
    }

    private var showsOtherWindowsToggle: Bool {
        !showOtherWindows && hiddenSecondaryCount > 0 && searchText.isEmpty
    }

    private var showOtherWindowsButton: some View {
        Button {
            showOtherWindows = true
        } label: {
            Label("Show \(hiddenSecondaryCount) other windows", systemImage: "chevron.down")
                .font(.subheadline)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }

    private var noSearchResultsView: some View {
        ContentUnavailableView(
            "No matches",
            systemImage: "magnifyingglass",
            description: Text("Try a different search term.")
        )
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    private func isHiddenSystemNoise(_ window: WindowItem) -> Bool {
        let title = window.title.lowercased()
        return Self.systemNoisePatterns.contains { title.contains($0) }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView("Loading windows…")
                .controlSize(.large)

            Text("Finding open windows on your Mac.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary)

            Text("Screen Recording Permission Required")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("\(AppBranding.name) needs screen recording access to list your open windows.")
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button("Open System Settings") {
                PermissionManager.shared.openSystemSettings(for: .screenRecording)
            }
            .buttonStyle(.borderedProminent)

            Button("Try Again") {
                Task { await viewModel.refresh(isPro: appState.isPro) }
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.textSecondary)

            Text("Could Not Load Windows")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text(message)
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button("Try Again") {
                Task { await viewModel.refresh(isPro: appState.isPro) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyWindowsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "macwindow.on.rectangle")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.textSecondary)

            Text("No Windows Found")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Open an app with a visible window, then refresh.")
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button("Refresh") {
                Task { await viewModel.refresh(isPro: appState.isPro) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button("Refresh") {
                Task { await viewModel.refresh(isPro: appState.isPro) }
            }
            .disabled(viewModel.isLoading)
        }
    }

    private func proceedToLayoutPicker() {
        appState.selectedWindowIDs = viewModel.selectedIDs
        router.navigate(to: .layoutPicker)
    }
}

#Preview {
    WindowPickerView()
        .environment(AppState())
        .environment(AppRouter())
        .frame(width: 900, height: 600)
}
