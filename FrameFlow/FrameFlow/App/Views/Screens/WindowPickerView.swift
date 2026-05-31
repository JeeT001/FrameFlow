//
//  WindowPickerView.swift
//  FrameFlow
//

import CoreGraphics
import SwiftUI

struct WindowPickerView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = WindowPickerViewModel()
    @State private var showProGate = false
    @State private var proGateFeature = ""
    @State private var proGateDescription = ""

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
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
                windowGrid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Select Windows")
        .toolbar { toolbarContent }
        .task {
            await viewModel.loadWindows(isPro: appState.isPro)
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

    private var windowGrid: some View {
        ScrollView {
            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Refreshing thumbnails…")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            }

            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(viewModel.windows) { window in
                    WindowPickerCell(
                        window: window,
                        isSelected: viewModel.selectedIDs.contains(window.id)
                    ) {
                        viewModel.toggleSelection(window.id, isPro: appState.isPro)
                    }
                }
            }
            .padding(20)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView("Loading windows…")
                .controlSize(.large)

            Text("Fetching window thumbnails can take 30–60 seconds.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Text("You can continue once the grid appears.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary)

            Text("Screen Recording Permission Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("FrameFlow needs screen recording access to list your open windows.")
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
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.textSecondary)

            Text("Could Not Load Windows")
                .font(.title2)
                .fontWeight(.semibold)

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
    }

    private var emptyWindowsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "macwindow.on.rectangle")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.textSecondary)

            Text("No Windows Found")
                .font(.title2)
                .fontWeight(.semibold)

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
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Text(selectionLabel)
                .foregroundStyle(AppColors.textSecondary)
        }

        ToolbarItem(placement: .automatic) {
            Button("Refresh") {
                Task { await viewModel.refresh(isPro: appState.isPro) }
            }
            .disabled(viewModel.isLoading)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Next") {
                proceedToLayoutPicker()
            }
            .disabled(!viewModel.canProceed || viewModel.isLoading)
        }
    }

    private var selectionLabel: String {
        let count = viewModel.selectedCount
        let limit = viewModel.selectionLimit(isPro: appState.isPro)
        return "\(count) selected (max \(limit))"
    }

    private func proceedToLayoutPicker() {
        appState.selectedWindowIDs = viewModel.selectedIDs
        router.navigate(to: .layoutPicker)
    }
}

private struct WindowPickerCell: View {
    let window: WindowItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    thumbnailArea

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, AppColors.primary)
                            .padding(8)
                    }
                }

                Text(window.title.truncatedWindowTitle)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColors.primary : AppColors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var thumbnailArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppColors.surface)
                .aspectRatio(16 / 10, contentMode: .fit)

            if let image = ImageDisplayHelpers.thumbnailImage(from: window.thumbnail) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 10, contentMode: .fill)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: "macwindow")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .overlay(alignment: .bottomLeading) {
            appIconBadge
                .padding(6)
        }
    }

    @ViewBuilder
    private var appIconBadge: some View {
        if let icon = ImageDisplayHelpers.appIconImage(from: window.appIcon) {
            icon
                .resizable()
                .frame(width: 20, height: 20)
        } else {
            Image(systemName: "app")
                .font(.caption)
                .frame(width: 20, height: 20)
        }
    }
}

#Preview {
    WindowPickerView()
        .environment(AppState())
        .environment(AppRouter())
        .frame(width: 900, height: 600)
}
