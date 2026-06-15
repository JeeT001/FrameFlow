//
//  LayoutPickerView.swift
//  FrameFlow
//

import AVFoundation
import SwiftUI

struct LayoutPickerView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = LayoutPickerViewModel()
    @State private var showProGate = false
    @State private var proGateFeature = ""
    @State private var proGateDescription = ""

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.selectedWindowCount(from: appState) == 0 {
                noWindowsBanner
            }

            LayoutPickerHeader()
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 8)

            HStack(alignment: .top, spacing: 0) {
                leftPanel
                    .frame(width: 360)

                Divider()

                rightPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(24)
            }

            Divider()

            LayoutPickerBottomBar(
                windowCount: viewModel.selectedWindowCount(from: appState),
                windowLabels: viewModel.windowLabels(from: appState),
                startDisabled: viewModel.selectedWindowCount(from: appState) == 0,
                onAddWindows: {
                    router.navigate(to: .windowPicker)
                },
                onStartRecording: startRecording
            )
        }
        .frame(minWidth: 900, minHeight: 600)
        .navigationTitle("")
        .task {
            viewModel.loadCameras()
            viewModel.loadSessionState(from: appState)
            viewModel.syncPiPState()
            if appState.isPro {
                TranscriptionService.shared.prepareModelInBackground()
            }
            await viewModel.startLivePreview(appState: appState)
            await viewModel.startCameraPreviewIfNeeded()
        }
        .onDisappear {
            Task { await viewModel.stopLivePreview() }
        }
        .onChange(of: viewModel.format) { old, new in
            viewModel.handleFormatChange(from: old, to: new, appState: appState)
        }
        .onChange(of: viewModel.layoutPreset) { old, new in
            viewModel.handleLayoutPresetChange(from: old, to: new, appState: appState)
        }
        .onChange(of: viewModel.settings.autoFocusEnabled) { _, _ in
            viewModel.updateLivePreviewLayout(appState: appState)
        }
        .onChange(of: appState.selectedWindowIDs) { _, _ in
            Task { await viewModel.refreshLivePreview(appState: appState) }
        }
        .onChange(of: viewModel.cameraEnabled) { _, enabled in
            viewModel.setCameraEnabled(enabled)
            Task { await viewModel.startCameraPreviewIfNeeded() }
        }
        .onChange(of: viewModel.selectedCameraID) { _, newID in
            viewModel.setSelectedCameraID(newID)
            Task { await viewModel.startCameraPreviewIfNeeded() }
        }
        .sheet(isPresented: $viewModel.showAudioSheet) {
            AudioModePickerView(settings: viewModel.settings, isPro: appState.isPro) {
                viewModel.showAudioSheet = false
            }
        }
        .proUpgradeSheet(
            isPresented: $showProGate,
            feature: proGateFeature,
            description: proGateDescription
        )
        .alert("No Windows Selected", isPresented: $viewModel.showNoWindowsAlert) {
            Button("Back to Window Picker") {
                router.navigate(to: .windowPicker)
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Select at least one window before starting a recording.")
        }
    }

    private var noWindowsBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.proGold)
            Text("No windows selected. Go back to the Window Picker to choose sources.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Button("Window Picker") {
                router.navigate(to: .windowPicker)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(AppColors.proGold.opacity(0.12))
    }

    private var leftPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                formatSection
                layoutSection
                cameraSection
                audioSection
                recordingOptionsSection
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
        }
    }

    private var formatSection: some View {
        LayoutPickerNumberedSection(number: 1, title: "Format") {
            LayoutFormatToggle(selection: formatBinding, isPro: appState.isPro)

            if viewModel.format == .nineBySixteen {
                platformGuideCallout
            }
        }
    }

    private var platformGuideCallout: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("9:16 is optimized for YouTube Shorts, Instagram Reels, and TikTok.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Platform guide", selection: Bindable(viewModel).platformPreviewOverlay) {
                ForEach(PlatformPreviewOverlay.allCases) { platform in
                    Text(platform.pickerTitle).tag(platform)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()

            Text("Guide only — not included in your video")
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppColors.primary.opacity(0.2))
        }
    }

    private var formatBinding: Binding<RecordingFormat> {
        Binding(
            get: { viewModel.format },
            set: { newValue in
                ProGate.perform(
                    isPro: appState.isPro,
                    feature: "Vertical Format (9:16)",
                    description: "9:16 exports for TikTok, Reels, and Shorts are included with \(AppBranding.proName).",
                    present: presentProGate,
                    action: {
                        viewModel.format = newValue
                    }
                )
            }
        )
    }

    private var activePlatformOverlay: PlatformPreviewOverlay {
        guard viewModel.format == .nineBySixteen else { return .none }
        return viewModel.platformPreviewOverlay
    }

    private var layoutSection: some View {
        LayoutPickerNumberedSection(number: 2, title: "Layout") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(LayoutPreset.allCases) { preset in
                    LayoutPresetCard(
                        preset: preset,
                        isSelected: viewModel.layoutPreset == preset
                    ) {
                        let old = viewModel.layoutPreset
                        viewModel.handleLayoutPresetChange(from: old, to: preset, appState: appState)
                    }
                }
            }
        }
    }

    private var cameraSection: some View {
        LayoutPickerNumberedSection(number: 3, title: "Camera") {
            Toggle("Enable camera (PiP)", isOn: cameraEnabledBinding)

            if viewModel.cameraEnabled {
                Picker("Camera source", selection: cameraSelection) {
                    if viewModel.availableCameras.isEmpty {
                        Text("No camera found").tag(Optional<String>.none)
                    }
                    ForEach(viewModel.availableCameras, id: \.uniqueID) { device in
                        Text(device.localizedName).tag(Optional(device.uniqueID))
                    }
                }
                .disabled(viewModel.availableCameras.isEmpty)

                Picker("PiP preset", selection: presetSelection) {
                    ForEach(viewModel.pipPresets) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
            }
        }
    }

    private var cameraEnabledBinding: Binding<Bool> {
        Binding(
            get: { viewModel.cameraEnabled },
            set: { newValue in
                ProGate.perform(
                    isPro: appState.isPro,
                    feature: "Camera PiP",
                    description: "Overlay your webcam in the recording with a draggable picture-in-picture window.",
                    present: presentProGate,
                    action: {
                        viewModel.setCameraEnabled(newValue)
                        Task { await viewModel.startCameraPreviewIfNeeded() }
                    }
                )
            }
        )
    }

    private func presentProGate(feature: String, description: String) {
        proGateFeature = feature
        proGateDescription = description
        showProGate = true
    }

    private var cameraSelection: Binding<String?> {
        Binding(
            get: { viewModel.selectedCameraID },
            set: { viewModel.setSelectedCameraID($0) }
        )
    }

    private var presetSelection: Binding<PiPPreset> {
        Binding(
            get: { viewModel.pipController.selectedPreset },
            set: { viewModel.applyPiPPreset($0, appState: appState) }
        )
    }

    private var audioSection: some View {
        LayoutPickerNumberedSection(number: 4, title: "Audio") {
            Button {
                viewModel.showAudioSheet = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: AudioModeOption(rawValue: viewModel.settings.defaultAudioMode)?.systemImage ?? "mic.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.audioModeLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppColors.textPrimary)
                        Text("High quality audio recording")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(14)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppColors.border)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var recordingOptionsSection: some View {
        LayoutPickerNumberedSection(number: 5, title: "Recording options") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Auto-focus on active window", isOn: Bindable(viewModel.settings).autoFocusEnabled)
                Toggle("Cursor highlight", isOn: Bindable(viewModel.settings).cursorHighlightEnabled)
                Toggle("Auto-zoom on click", isOn: Bindable(viewModel.settings).autoZoomOnClick)

                HStack {
                    Text("Countdown")
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Picker("Countdown", selection: Bindable(viewModel.settings).countdownDuration) {
                        ForEach(0...5, id: \.self) { seconds in
                            Text("\(seconds) sec").tag(seconds)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 100)
                }
            }
        }
    }

    private var rightPanel: some View {
        LayoutPreviewChrome(
            isLive: viewModel.isLivePreviewActive,
            format: viewModel.format
        ) {
            previewContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var previewContent: some View {
        if appState.selectedWindowIDs.isEmpty {
            LayoutPreviewCanvas(
                format: viewModel.format,
                preset: viewModel.layoutPreset,
                windowLabels: viewModel.windowLabels(from: appState),
                cameraEnabled: viewModel.cameraEnabled,
                platformOverlay: activePlatformOverlay
            )
        } else if viewModel.isStartingLivePreview && viewModel.previewImage == nil {
            VStack(spacing: 12) {
                ProgressView("Starting live preview…")
                Text("Capturing window streams. This may take a few seconds.")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.isLivePreviewActive, let previewImage = viewModel.previewImage {
            LayoutLivePreviewStack(
                image: previewImage,
                aspectRatio: viewModel.format.aspectRatio,
                referenceCanvasSize: CompositeEngine.shared.outputSize(for: viewModel.format),
                layoutPreset: viewModel.layoutPreset,
                windowIDs: appState.selectedWindowIDs.sorted(),
                pipController: viewModel.pipController,
                windowPlacementController: viewModel.windowPlacementController,
                showPiPOverlay: viewModel.cameraEnabled,
                platformOverlay: activePlatformOverlay,
                onPlacementsChanged: {
                    viewModel.syncWindowPlacements(to: appState)
                },
                onPiPChanged: {
                    viewModel.notifyPiPChanged(appState: appState)
                }
            )
        } else {
            VStack(spacing: 10) {
                LayoutPreviewCanvas(
                    format: viewModel.format,
                    preset: viewModel.layoutPreset,
                    windowLabels: viewModel.windowLabels(from: appState),
                    cameraEnabled: viewModel.cameraEnabled,
                    platformOverlay: activePlatformOverlay
                )

                if let message = viewModel.previewErrorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                }
            }
        }
    }

    private func startRecording() {
        guard viewModel.validateWindowsSelected(from: appState) else { return }
        viewModel.syncSessionState(to: appState)
        router.navigate(to: .recording)
    }
}

#Preview {
    LayoutPickerView()
        .environment(AppState())
        .environment(AppRouter())
        .frame(width: 1000, height: 700)
}
