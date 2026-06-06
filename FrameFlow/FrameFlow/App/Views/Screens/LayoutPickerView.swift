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

            HStack(alignment: .top, spacing: 0) {
                leftPanel
                    .frame(width: 340)
                    .padding(20)

                Divider()

                rightPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(20)
            }

            Divider()

            bottomBar
                .padding(20)
        }
        .frame(minWidth: 900, minHeight: 600)
        .navigationTitle("Layout")
        .task {
            viewModel.loadCameras()
            viewModel.loadSessionState(from: appState)
            viewModel.syncPiPState()
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
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.proGold)
            Text("No windows selected. Go back to the Window Picker to choose sources.")
                .font(.subheadline)
            Spacer()
            Button("Window Picker") {
                router.navigate(to: .windowPicker)
            }
        }
        .padding(12)
        .background(AppColors.proGold.opacity(0.12))
    }

    private var leftPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                formatSection
                layoutSection
                cameraSection
                audioSection
                togglesSection
                countdownSection
            }
        }
    }

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Format")
                .font(.headline)

            Picker("Format", selection: formatBinding) {
                ForEach(RecordingFormat.allCases) { format in
                    HStack {
                        Text(format.title)
                        if format == .nineBySixteen && !appState.isPro {
                            Text("Pro")
                                .font(.caption2)
                                .padding(.horizontal, 5)
                                .background(AppColors.primary.opacity(0.15), in: Capsule())
                        }
                    }
                    .tag(format)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var formatBinding: Binding<RecordingFormat> {
        Binding(
            get: { viewModel.format },
            set: { newValue in
                ProGate.perform(
                    isPro: appState.isPro,
                    feature: "Vertical Format (9:16)",
                    description: "9:16 exports for TikTok, Reels, and Shorts are included with FrameFlow Pro.",
                    present: presentProGate,
                    action: {
                        viewModel.format = newValue
                    }
                )
            }
        )
    }

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Layout")
                .font(.headline)

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
        VStack(alignment: .leading, spacing: 8) {
            Text("Camera")
                .font(.headline)

            Toggle("Enable camera (PiP)", isOn: cameraEnabledBinding)

            if viewModel.cameraEnabled {
                Picker("Camera source", selection: cameraSelection) {
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
            set: { viewModel.selectedCameraID = $0 }
        )
    }

    private var presetSelection: Binding<PiPPreset> {
        Binding(
            get: { viewModel.pipController.selectedPreset },
            set: { viewModel.applyPiPPreset($0) }
        )
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Audio")
                .font(.headline)

            Button {
                viewModel.showAudioSheet = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.audioModeLabel)
                            .font(.body)
                        Text("Tap to change")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(12)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    private var togglesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recording")
                .font(.headline)

            Toggle("Auto-focus on active window", isOn: Bindable(viewModel.settings).autoFocusEnabled)
            Toggle("Cursor highlight", isOn: Bindable(viewModel.settings).cursorHighlightEnabled)
        }
    }

    private var countdownSection: some View {
        Stepper(
            value: Bindable(viewModel.settings).countdownDuration,
            in: 0...5
        ) {
            Text("Countdown: \(viewModel.settings.countdownDuration)s")
        }
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)

            ZStack {
                if appState.selectedWindowIDs.isEmpty {
                    LayoutPreviewCanvas(
                        format: viewModel.format,
                        preset: viewModel.layoutPreset,
                        windowLabels: viewModel.windowLabels(from: appState),
                        cameraEnabled: viewModel.cameraEnabled
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
                        cameraFrame: viewModel.latestCameraFrame,
                        showPiPOverlay: viewModel.cameraEnabled,
                        onPlacementsChanged: {
                            viewModel.syncWindowPlacements(to: appState)
                        }
                    )
                } else {
                    VStack(spacing: 10) {
                        LayoutPreviewCanvas(
                            format: viewModel.format,
                            preset: viewModel.layoutPreset,
                            windowLabels: viewModel.windowLabels(from: appState),
                            cameraEnabled: viewModel.cameraEnabled
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var bottomBar: some View {
        HStack {
            Text("\(viewModel.selectedWindowCount(from: appState)) window(s) selected")
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Button("Start Recording") {
                startRecording()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.selectedWindowCount(from: appState) == 0)
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
