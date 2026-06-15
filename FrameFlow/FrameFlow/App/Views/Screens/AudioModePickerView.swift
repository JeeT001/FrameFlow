//
//  AudioModePickerView.swift
//  FrameFlow
//

import SwiftUI

struct AudioModePickerView: View {
    @Environment(AppRouter.self) private var router
    @Bindable var settings: SettingsStore
    let isPro: Bool
    let onConfirm: () -> Void

    @State private var draftMode: String
    @State private var draftMicVolumePercent: Double
    @State private var draftSystemVolumePercent: Double
    @State private var showProGate = false
    @State private var proGateFeature = "Pro Audio"
    @State private var proGateDescription = "System and combined audio capture require \(AppBranding.proName)."
    @State private var levelMonitor = AudioLevelMonitor()

    init(
        settings: SettingsStore = .shared,
        isPro: Bool,
        onConfirm: @escaping () -> Void
    ) {
        self.settings = settings
        self.isPro = isPro
        self.onConfirm = onConfirm
        _draftMode = State(initialValue: settings.defaultAudioMode)
        _draftMicVolumePercent = State(initialValue: Double(settings.defaultMicVolume) * 100)
        _draftSystemVolumePercent = State(initialValue: Double(settings.defaultSystemVolume) * 100)
    }

    private var includesMic: Bool {
        draftMode == AudioModeOption.mic.rawValue || draftMode == AudioModeOption.combined.rawValue
    }

    private var includesSystem: Bool {
        draftMode == AudioModeOption.system.rawValue || draftMode == AudioModeOption.combined.rawValue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Audio Mode")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Choose how \(AppBranding.name) captures sound for your recording.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

                VStack(spacing: 12) {
                    ForEach(AudioModeOption.allCases) { option in
                        audioModeCard(option)
                    }
                }

                volumeAndMeterSection

                Button("Confirm") {
                    confirmSelection()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .frame(minWidth: 420, minHeight: 480)
        .proUpgradeSheet(
            isPresented: $showProGate,
            feature: proGateFeature,
            description: proGateDescription
        )
        .onAppear {
            syncDraftVolumesFromStore()
            updateMeterForCurrentMode()
        }
        .onDisappear {
            levelMonitor.stopMonitoring()
        }
        .onChange(of: draftMode) { _, _ in
            updateMeterForCurrentMode()
        }
    }

    @ViewBuilder
    private var volumeAndMeterSection: some View {
        if includesMic || includesSystem {
            VStack(alignment: .leading, spacing: 16) {
                if includesMic {
                    micVolumeSection
                }

                if includesSystem {
                    systemVolumeSection
                }
            }
            .padding(.top, 4)
        }
    }

    private var micVolumeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Microphone volume")
                    .font(.headline)
                Spacer()
                Text("\(Int(draftMicVolumePercent.rounded()))%")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .monospacedDigit()
            }

            Slider(value: $draftMicVolumePercent, in: 0...100, step: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text("Input level")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                AudioLevelBars(level: meterLevelForDisplay)

                if levelMonitor.permissionDenied, let message = levelMonitor.statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private var systemVolumeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("System audio volume")
                    .font(.headline)
                Spacer()
                Text("\(Int(draftSystemVolumePercent.rounded()))%")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .monospacedDigit()
            }

            Slider(value: $draftSystemVolumePercent, in: 0...100, step: 1)
        }
    }

    private var meterLevelForDisplay: Float {
        if levelMonitor.permissionDenied { return 0 }
        return levelMonitor.level * Float(draftMicVolumePercent / 100)
    }

    private func audioModeCard(_ option: AudioModeOption) -> some View {
        let isSelected = draftMode == option.rawValue
        let showProBadge = option.requiresPro && !isPro

        return Button {
            selectMode(option)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.systemImage)
                    .font(.title2)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(option.title)
                            .font(.headline)
                        if showProBadge {
                            Text("Pro")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.primary.opacity(0.15), in: Capsule())
                        }
                    }
                    Text(audioModeSubtitle(for: option))
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(14)
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

    private func selectMode(_ option: AudioModeOption) {
        if option.requiresPro && !isPro {
            showProGate = true
            return
        }
        draftMode = option.rawValue
    }

    private func confirmSelection() {
        settings.defaultAudioMode = draftMode
        settings.defaultMicVolume = Float(draftMicVolumePercent / 100)
        settings.defaultSystemVolume = Float(draftSystemVolumePercent / 100)
        levelMonitor.stopMonitoring()
        onConfirm()
    }

    private func syncDraftVolumesFromStore() {
        draftMicVolumePercent = Double(settings.defaultMicVolume) * 100
        draftSystemVolumePercent = Double(settings.defaultSystemVolume) * 100
    }

    private func updateMeterForCurrentMode() {
        if includesMic {
            Task {
                await levelMonitor.startMonitoring(
                    preferredDeviceUniqueID: settings.defaultMicDevice
                )
            }
        } else {
            levelMonitor.stopMonitoring()
        }
    }

    private func audioModeSubtitle(for option: AudioModeOption) -> String {
        switch option {
        case .mic: "Record your voice from the selected microphone."
        case .system: "Capture app and system sounds (macOS 14+)."
        case .combined: "Mix microphone and system audio."
        case .none: "Video only, no audio track."
        }
    }
}

/// Standalone route placeholder when opened from toolbar.
struct AudioModePickerStandaloneView: View {
    var body: some View {
        ContentUnavailableView(
            "Audio Mode",
            systemImage: "waveform",
            description: Text("Open the Layout Picker and tap Audio to change your recording mode.")
        )
        .navigationTitle("Audio Mode")
    }
}

#Preview {
    AudioModePickerView(isPro: false) {}
        .environment(AppRouter())
}