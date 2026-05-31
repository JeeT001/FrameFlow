//
//  SettingsView.swift
//  FrameFlow
//

import AVFoundation
import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            permissionsSection
            recordingExportSection
            audioSection
            cursorZoomSection
            captionsNotificationsSection
            appearanceSection
            aboutSection
            debugSection
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
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

    private var permissionsSection: some View {
        Section("Permissions") {
            permissionRow(
                title: PermissionKind.screenRecording.title,
                status: viewModel.screenRecordingStatusLabel()
            ) {
                Task { await viewModel.refreshPermissions() }
            } openSettings: {
                PermissionManager.shared.openSystemSettings(for: .screenRecording)
            }

            permissionRow(
                title: PermissionKind.camera.title,
                status: viewModel.cameraStatusLabel()
            ) {
                Task {
                    if viewModel.cameraStatus == .notDetermined {
                        await viewModel.requestCameraAccess()
                    } else {
                        await viewModel.refreshPermissions()
                    }
                }
            } openSettings: {
                PermissionManager.shared.openSystemSettings(for: .camera)
            }

            permissionRow(
                title: PermissionKind.microphone.title,
                status: viewModel.microphoneStatusLabel()
            ) {
                Task {
                    if viewModel.microphoneStatus == .notDetermined {
                        await viewModel.requestMicrophoneAccess()
                    } else {
                        await viewModel.refreshPermissions()
                    }
                }
            } openSettings: {
                PermissionManager.shared.openSystemSettings(for: .microphone)
            }

            if viewModel.isRefreshing {
                ProgressView("Checking permissions…")
            }
        }
    }

    private var recordingExportSection: some View {
        Section("Recording & Export") {
            Picker("Default resolution", selection: Bindable(viewModel.settings).defaultResolution) {
                ForEach(viewModel.availableResolutions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }

            LabeledContent("Save folder") {
                HStack {
                    Text(viewModel.settings.expandedSaveFolder)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(AppColors.textSecondary)
                    Button("Choose…") {
                        viewModel.chooseSaveFolder()
                    }
                }
            }

            if viewModel.saveFolderNeedsReauthorization {
                Text("Choose… again to allow saving to this folder (required for Desktop and other locations outside the app).")
                    .font(.caption)
                    .foregroundStyle(AppColors.proGold)
            }

            Stepper(
                value: Bindable(viewModel.settings).countdownDuration,
                in: 0...5
            ) {
                Text("Countdown: \(viewModel.settings.countdownDuration)s")
            }
        }
    }

    private var audioSection: some View {
        Section("Audio") {
            Picker("Default audio mode", selection: Bindable(viewModel.settings).defaultAudioMode) {
                ForEach(SettingsViewModel.audioModeOptions, id: \.self) { mode in
                    Text(viewModel.audioModeLabel(for: mode)).tag(mode)
                }
            }

            Picker("Microphone device", selection: micDeviceSelection) {
                Text("System Default").tag(Optional<String>.none)
                ForEach(viewModel.audioInputDevices, id: \.uniqueID) { device in
                    Text(device.localizedName).tag(Optional(device.uniqueID))
                }
            }

            VStack(alignment: .leading) {
                Text("Microphone volume")
                Slider(
                    value: Bindable(viewModel.settings).defaultMicVolume,
                    in: 0...1
                )
            }

            VStack(alignment: .leading) {
                Text("System audio volume")
                Slider(
                    value: Bindable(viewModel.settings).defaultSystemVolume,
                    in: 0...1
                )
            }
        }
    }

    private var cursorZoomSection: some View {
        Section("Cursor & Zoom") {
            Toggle("Auto-focus on active window", isOn: Bindable(viewModel.settings).autoFocusEnabled)
            Toggle("Cursor highlight", isOn: Bindable(viewModel.settings).cursorHighlightEnabled)
            Toggle("Auto zoom on click", isOn: Bindable(viewModel.settings).autoZoomOnClick)

            Stepper(
                value: Bindable(viewModel.settings).zoomHoldDuration,
                in: 0.5...5.0,
                step: 0.5
            ) {
                Text("Zoom hold: \(viewModel.settings.zoomHoldDuration, specifier: "%.1f")s")
            }

            Picker("Cursor highlight color", selection: Bindable(viewModel.settings).cursorHighlightColor) {
                ForEach(SettingsViewModel.cursorColorOptions, id: \.self) { color in
                    Text(viewModel.cursorColorLabel(for: color)).tag(color)
                }
            }
        }
    }

    private var captionsNotificationsSection: some View {
        Section("Captions & Notifications") {
            Picker("Caption style", selection: Bindable(viewModel.settings).captionStyle) {
                ForEach(SettingsViewModel.captionStyleOptions, id: \.self) { style in
                    Text(viewModel.captionStyleLabel(for: style)).tag(style)
                }
            }

            Toggle("Export complete notifications", isOn: Bindable(viewModel.settings).notificationsEnabled)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Dark mode", selection: Bindable(viewModel.settings).darkModeOverride) {
                ForEach(SettingsViewModel.appearanceOptions, id: \.self) { option in
                    Text(viewModel.appearanceLabel(for: option)).tag(option)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version") {
                Text(viewModel.appVersionString)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Button("Check for Updates") {
                viewModel.showUpdatesAlert = true
            }
        }
    }

    private var debugSection: some View {
        Section("Device Capabilities (Debug)") {
            LabeledContent("Apple Silicon") {
                Text(viewModel.capabilities.isAppleSilicon ? "Yes" : "No")
            }
            LabeledContent("Max windows") {
                Text("\(viewModel.capabilities.maxWindows)")
            }
            LabeledContent("4K export") {
                Text(viewModel.capabilities.supports4K ? "Supported" : "Not supported")
            }
            LabeledContent("Composite FPS") {
                Text("\(viewModel.capabilities.compositeFrameRate)")
            }

            #if DEBUG
            Toggle("Show Lifetime plan on Subscription screen", isOn: Bindable(viewModel.settings).showLifetimeDeal)
            #endif
        }
    }

    private var micDeviceSelection: Binding<String?> {
        Binding(
            get: { viewModel.settings.defaultMicDevice },
            set: { viewModel.settings.defaultMicDevice = $0 }
        )
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        status: String,
        checkStatus: @escaping () -> Void,
        openSettings: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(status)
                    .foregroundStyle(AppColors.textSecondary)
            }

            HStack {
                Button("Check Status", action: checkStatus)
                Button("Open System Settings", action: openSettings)
            }
            .buttonStyle(.link)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
        .frame(width: 520, height: 800)
}
