//
//  SettingsView.swift
//  FrameFlow
//

import AppKit
import AVFoundation
import SwiftUI

struct SettingsView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = SettingsViewModel()

    private let zoomHoldOptions: [Double] = stride(from: 0.5, through: 5.0, by: 0.5).map { $0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsPageHeader()

                permissionsCard
                recordingExportCard
                audioCard
                cursorZoomCard
                captionsNotificationsCard
                appearanceCard
                supportCreatorCard
                aboutCard
                debugCard
            }
            .padding(28)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(AppColors.background)
        .navigationTitle("")
        .task {
            await viewModel.refreshPermissions()
            viewModel.loadAudioDevices()
        }
        .alert("Updates Coming Soon", isPresented: $viewModel.showUpdatesAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Automatic update checks will be available in a future release.")
        }
    }

    private var permissionsCard: some View {
        SettingsSectionCard(title: "Permissions", icon: "shield.checkered") {
            VStack(alignment: .leading, spacing: 12) {
                SettingsPermissionRow(
                    icon: "display",
                    title: PermissionKind.screenRecording.title,
                    status: viewModel.screenRecordingStatusLabel(),
                    onCheckStatus: {
                        Task { await viewModel.refreshPermissions() }
                    },
                    onOpenSettings: {
                        PermissionManager.shared.openSystemSettings(for: .screenRecording)
                    }
                )

                Divider()

                SettingsPermissionRow(
                    icon: "camera",
                    title: PermissionKind.camera.title,
                    status: viewModel.cameraStatusLabel(),
                    onCheckStatus: {
                        Task {
                            if viewModel.cameraStatus == .notDetermined {
                                await viewModel.requestCameraAccess()
                            } else {
                                await viewModel.refreshPermissions()
                            }
                        }
                    },
                    onOpenSettings: {
                        PermissionManager.shared.openSystemSettings(for: .camera)
                    }
                )

                Divider()

                SettingsPermissionRow(
                    icon: "mic",
                    title: PermissionKind.microphone.title,
                    status: viewModel.microphoneStatusLabel(),
                    onCheckStatus: {
                        Task {
                            if viewModel.microphoneStatus == .notDetermined {
                                await viewModel.requestMicrophoneAccess()
                            } else {
                                await viewModel.refreshPermissions()
                            }
                        }
                    },
                    onOpenSettings: {
                        PermissionManager.shared.openSystemSettings(for: .microphone)
                    }
                )

                if viewModel.isRefreshing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking permissions…")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
    }

    private var recordingExportCard: some View {
        SettingsSectionCard(title: "Recording & Export", icon: "video") {
            VStack(alignment: .leading, spacing: 14) {
                SettingsPickerRow(
                    title: "Default resolution",
                    selection: Bindable(viewModel.settings).defaultResolution
                ) {
                    ForEach(viewModel.availableResolutions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                Divider()

                HStack(alignment: .center) {
                    Text("Save folder")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer(minLength: 12)

                    Text(viewModel.settings.expandedSaveFolder)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 220, alignment: .trailing)

                    Button("Choose…") {
                        viewModel.chooseSaveFolder()
                    }
                    .buttonStyle(.bordered)
                }

                if viewModel.saveFolderNeedsReauthorization {
                    Text("Choose… again to allow saving to this folder (required for Desktop and other locations outside the app).")
                        .font(.caption)
                        .foregroundStyle(AppColors.proGold)
                }

                Divider()

                SettingsPickerRow(
                    title: "Countdown",
                    selection: Bindable(viewModel.settings).countdownDuration
                ) {
                    ForEach(0...5, id: \.self) { seconds in
                        Text("\(seconds) sec").tag(seconds)
                    }
                }
            }
        }
    }

    private var audioCard: some View {
        SettingsSectionCard(title: "Audio", icon: "speaker.wave.2") {
            VStack(alignment: .leading, spacing: 14) {
                SettingsPickerRow(
                    title: "Default audio mode",
                    selection: Bindable(viewModel.settings).defaultAudioMode
                ) {
                    ForEach(SettingsViewModel.audioModeOptions, id: \.self) { mode in
                        Text(viewModel.audioModeLabel(for: mode)).tag(mode)
                    }
                }

                Divider()

                SettingsPickerRow(
                    title: "Microphone device",
                    selection: micDeviceSelection
                ) {
                    Text("System Default").tag(Optional<String>.none)
                    ForEach(viewModel.audioInputDevices, id: \.uniqueID) { device in
                        Text(device.localizedName).tag(Optional(device.uniqueID))
                    }
                }

                Divider()

                SettingsSliderRow(
                    title: "Microphone volume",
                    valueLabel: "\(Int(viewModel.settings.defaultMicVolume * 100))%",
                    sliderValue: Bindable(viewModel.settings).defaultMicVolume,
                    range: 0...1
                )

                SettingsSliderRow(
                    title: "System audio volume",
                    valueLabel: "\(Int(viewModel.settings.defaultSystemVolume * 100))%",
                    sliderValue: Bindable(viewModel.settings).defaultSystemVolume,
                    range: 0...1
                )
            }
        }
    }

    private var cursorZoomCard: some View {
        SettingsSectionCard(title: "Cursor & Zoom", icon: "cursorarrow.rays") {
            VStack(alignment: .leading, spacing: 14) {
                SettingsToggleRow(
                    title: "Auto-focus on active window",
                    isOn: Bindable(viewModel.settings).autoFocusEnabled
                )

                SettingsToggleRow(
                    title: "Cursor highlight",
                    isOn: Bindable(viewModel.settings).cursorHighlightEnabled
                )

                SettingsToggleRow(
                    title: "Auto zoom on click",
                    isOn: Bindable(viewModel.settings).autoZoomOnClick
                )

                Divider()

                SettingsSliderRow(
                    title: "Zoom strength",
                    valueLabel: "\(String(format: "%.0f", (1 + viewModel.settings.zoomStrength) * 100))%",
                    sliderValue: Bindable(viewModel.settings).zoomStrength,
                    range: 0...3,
                    step: 0.05
                )

                SettingsPickerRow(
                    title: "Zoom hold",
                    selection: Bindable(viewModel.settings).zoomHoldDuration
                ) {
                    ForEach(zoomHoldOptions, id: \.self) { seconds in
                        Text(String(format: "%.1f sec", seconds)).tag(seconds)
                    }
                }

                SettingsPickerRow(
                    title: "Cursor highlight color",
                    selection: Bindable(viewModel.settings).cursorHighlightColor
                ) {
                    ForEach(SettingsViewModel.cursorColorOptions, id: \.self) { color in
                        Text(viewModel.cursorColorLabel(for: color)).tag(color)
                    }
                }
            }
        }
    }

    private var captionsNotificationsCard: some View {
        SettingsSectionCard(title: "Captions & Notifications", icon: "captions.bubble") {
            VStack(alignment: .leading, spacing: 14) {
                SettingsPickerRow(
                    title: "Caption style",
                    selection: Bindable(viewModel.settings).captionStyle
                ) {
                    ForEach(SettingsViewModel.captionStyleOptions, id: \.self) { style in
                        Text(viewModel.captionStyleLabel(for: style)).tag(style)
                    }
                }

                Divider()

                SettingsToggleRow(
                    title: "Export complete notifications",
                    isOn: Bindable(viewModel.settings).notificationsEnabled
                )
            }
        }
    }

    private var appearanceCard: some View {
        SettingsSectionCard(title: "Appearance", icon: "circle.lefthalf.filled") {
            SettingsPickerRow(
                title: "Dark mode",
                selection: Bindable(viewModel.settings).darkModeOverride
            ) {
                ForEach(SettingsViewModel.appearanceOptions, id: \.self) { option in
                    Text(viewModel.appearanceLabel(for: option)).tag(option)
                }
            }
        }
    }

    private var supportCreatorCard: some View {
        SettingsSectionCard(title: "Support the Creator", icon: "heart.fill") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Enjoying \(AppBranding.name)? Subscribe on YouTube for tutorials, tips, and updates.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    if let url = URL(string: AppBranding.creatorYouTubeURL) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.rectangle.fill")
                        Text("Visit YouTube Channel")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var aboutCard: some View {
        SettingsSectionCard(title: "About", icon: "info.circle") {
            VStack(alignment: .leading, spacing: 14) {
                SettingsLabeledValueRow(
                    title: "Version",
                    value: viewModel.appVersionString
                )

                Divider()

                SettingsButtonRow(title: "Check for Updates") {
                    viewModel.showUpdatesAlert = true
                }

                SettingsButtonRow(title: "Help & Support") {
                    router.navigate(to: .help)
                }

                HStack(spacing: 20) {
                    Button("Privacy Policy") {
                        router.navigateToLegal(.privacyPolicy, returningTo: .settings)
                    }
                    .buttonStyle(.plain)
                    .font(.callout)
                    .foregroundStyle(AppColors.primary)

                    Button("Terms of Service") {
                        router.navigateToLegal(.termsOfService, returningTo: .settings)
                    }
                    .buttonStyle(.plain)
                    .font(.callout)
                    .foregroundStyle(AppColors.primary)
                }
            }
        }
    }

    private var debugCard: some View {
        SettingsSectionCard(title: "Device Capabilities (Debug)", icon: "cpu") {
            VStack(alignment: .leading, spacing: 14) {
                SettingsLabeledValueRow(
                    title: "Apple Silicon",
                    value: viewModel.capabilities.isAppleSilicon ? "Yes" : "No"
                )
                SettingsLabeledValueRow(
                    title: "Max windows",
                    value: "\(viewModel.capabilities.maxWindows)"
                )
                SettingsLabeledValueRow(
                    title: "4K export",
                    value: viewModel.capabilities.supports4K ? "Supported" : "Not supported"
                )
                SettingsLabeledValueRow(
                    title: "Composite FPS",
                    value: "\(viewModel.capabilities.compositeFrameRate)"
                )

                #if DEBUG
                Divider()

                SettingsToggleRow(
                    title: "Show Lifetime plan on Subscription screen",
                    isOn: Bindable(viewModel.settings).showLifetimeDeal
                )
                #endif
            }
        }
    }

    private var micDeviceSelection: Binding<String?> {
        Binding(
            get: { viewModel.settings.defaultMicDevice },
            set: { viewModel.settings.defaultMicDevice = $0 }
        )
    }
}

#Preview {
    SettingsView()
        .frame(width: 720, height: 900)
}
