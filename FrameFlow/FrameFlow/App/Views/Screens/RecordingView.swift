//
//  RecordingView.swift
//  FrameFlow
//

import SwiftUI

struct RecordingView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = RecordingViewModel()
    @State private var showProGate = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            previewArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if viewModel.phase == .recording, viewModel.coordinator.isRecording {
                VStack(spacing: 0) {
                    RecordingHUDView(
                        isPaused: viewModel.isPaused,
                        isRecording: viewModel.coordinator.isRecording,
                        formattedDuration: viewModel.coordinator.engine.formattedDuration,
                        zoomLabel: viewModel.zoomLabel,
                        audioMode: viewModel.audioMode,
                        onPauseResume: { viewModel.togglePauseResume() },
                        onStop: { stopRecording() },
                        isPauseEnabled: !viewModel.isStopping && !viewModel.coordinator.isStarting,
                        isStopEnabled: !viewModel.isStopping && !viewModel.coordinator.isStarting
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .opacity(viewModel.isHUDVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isHUDVisible)
                    .allowsHitTesting(viewModel.isHUDVisible)

                    Spacer()

                    RecordingBottomBar(
                        windowCount: appState.selectedWindowIDs.count,
                        layoutPreset: appState.selectedLayoutPreset,
                        format: appState.selectedFormat,
                        autoFocusEnabled: SettingsStore.shared.autoFocusEnabled,
                        audioMode: viewModel.audioMode,
                        cameraEnabled: PiPController.shared.isCameraEnabled
                    )
                }
            }

            if viewModel.phase == .countdown, let value = viewModel.countdownValue {
                countdownOverlay(value: value)
            }

            if let message = viewModel.coordinator.errorMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7), in: Capsule())
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("")
        .task {
            configureShortcutHandlers()
            await viewModel.runRecordingFlow(appState: appState)
        }
        .onChange(of: viewModel.phase) { _, phase in
            updateKeyboardShortcuts(for: phase)
        }
        .onChange(of: viewModel.coordinator.isRecording) { _, isRecording in
            if isRecording, viewModel.phase == .recording {
                startKeyboardShortcuts()
            } else if !isRecording {
                KeyboardShortcutManager.shared.stop()
            }
        }
        .onDisappear {
            KeyboardShortcutManager.shared.stop()
            Task { await viewModel.abandonActiveRecordingIfNeeded() }
        }
        .proUpgradeSheet(
            isPresented: $showProGate,
            feature: "Camera PiP",
            description: "Overlay your webcam in the recording with a draggable picture-in-picture window."
        )
        .onContinuousHover { phase in
            switch phase {
            case .active, .ended:
                viewModel.previewInteraction()
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var previewArea: some View {
        if let cgImage = viewModel.coordinator.previewImage {
            CompositePreviewView(
                image: cgImage,
                aspectRatio: appState.selectedFormat.aspectRatio,
                fillsWindow: true
            )
        } else if viewModel.coordinator.isStarting || viewModel.phase == .countdown {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text(viewModel.phase == .countdown ? "Get ready…" : "Starting capture…")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        } else {
            ContentUnavailableView(
                "No preview",
                systemImage: "video.slash",
                description: Text("Return to Window Picker and try again.")
            )
        }
    }

    private func countdownOverlay(value: Int) -> some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            CountdownNumberView(value: value)
        }
        .transition(.opacity)
    }

    private func configureShortcutHandlers() {
        viewModel.isPro = appState.isPro
        viewModel.onStopRecording = { stopRecording() }
        viewModel.onDiscardRecording = { discardRecording() }
        viewModel.onPiPUpgradeRequired = { showProGate = true }
    }

    private func updateKeyboardShortcuts(for phase: RecordingScreenPhase) {
        if phase == .recording, viewModel.coordinator.isRecording {
            startKeyboardShortcuts()
        } else {
            KeyboardShortcutManager.shared.stop()
        }
    }

    private func startKeyboardShortcuts() {
        KeyboardShortcutManager.shared.start(handler: viewModel)
    }

    private func discardRecording() {
        Task {
            await viewModel.stopWithoutSaving()
            router.navigate(to: .dashboard)
        }
    }

    private func stopRecording() {
        Task {
            do {
                let metadata = try await viewModel.stopAndStage(appState: appState)
                appState.pendingRecording = metadata
                appState.exportRecordingID = metadata.id

                if await shouldStartCaptionFlow(for: metadata) {
                    CaptionGenerationState.shared.begin(with: metadata)
                }

                router.navigate(to: .editor)
            } catch {
                viewModel.coordinator.errorMessage = error.localizedDescription
            }
        }
    }

    private func shouldStartCaptionFlow(for metadata: RecordingMetadata) async -> Bool {
        guard AppFeatureFlags.captionsEnabled else { return false }
        guard appState.isPro else { return false }
        guard metadata.audioMode.lowercased() != "none" else { return false }

        let videoURL = URL(fileURLWithPath: metadata.filePath)
        return await TranscriptionService.shared.videoHasAudioTrack(at: videoURL)
    }
}

private struct CountdownNumberView: View {
    let value: Int
    @State private var scale: CGFloat = 0.55

    var body: some View {
        Text("\(value)")
            .font(.system(size: 140, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
            .scaleEffect(scale)
            .onAppear { animateIn() }
            .onChange(of: value) { _, _ in animateIn() }
    }

    private func animateIn() {
        scale = 0.55
        withAnimation(.spring(response: 0.32, dampingFraction: 0.62)) {
            scale = 1.0
        }
    }
}

#Preview {
    RecordingView()
        .environment(AppState())
        .environment(AppRouter())
        .frame(width: 1000, height: 700)
}
