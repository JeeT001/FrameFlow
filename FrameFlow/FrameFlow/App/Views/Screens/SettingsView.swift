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
            }

            Section("Preferences (Coming Soon)") {
                ForEach(AppRoute.settings.plannedElements, id: \.self) { element in
                    Button(element) {}
                        .disabled(true)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .task {
            await viewModel.refreshPermissions()
        }
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
                    .foregroundStyle(.secondary)
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
        .frame(width: 520, height: 640)
}
