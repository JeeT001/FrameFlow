//
//  RecordingView.swift
//  FrameFlow
//

import SwiftUI

struct RecordingView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = RecordingViewModel()
    @State private var lastSavedMetadata: RecordingMetadata?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            previewArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if viewModel.phase == .recording, viewModel.coordinator.isRecording {
                VStack {
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
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .opacity(viewModel.isHUDVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isHUDVisible)
                    .allowsHitTesting(viewModel.isHUDVisible)

                    Spacer()
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
        .navigationTitle("Recording")
        .task {
            await viewModel.runRecordingFlow(appState: appState)
        }
        .onDisappear {
            Task { await viewModel.stopWithoutSaving() }
        }
        .onContinuousHover { phase in
            switch phase {
            case .active, .ended:
                viewModel.previewInteraction()
            default:
                break
            }
        }
        .alert("Saved Recording", isPresented: $viewModel.showSavedAlert) {
            Button("Export") {
                if let lastSavedMetadata {
                    appState.exportRecordingID = lastSavedMetadata.id
                    router.navigate(to: .export)
                }
            }
            Button("Dashboard", role: .cancel) {
                router.navigate(to: .dashboard)
            }
        } message: {
            Text(viewModel.savedPathForAlert)
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

    private func stopRecording() {
        Task {
            do {
                let metadata = try await viewModel.stopAndSave(appState: appState)
                try? RecordingStore.shared.add(metadata)

                if await shouldStartCaptionFlow(for: metadata) {
                    CaptionGenerationState.shared.begin(with: metadata)
                    router.navigate(to: .captionEditor)
                    return
                }

                lastSavedMetadata = metadata
                viewModel.savedPathForAlert = metadata.filePath
                viewModel.showSavedAlert = true
            } catch {
                viewModel.coordinator.errorMessage = error.localizedDescription
            }
        }
    }

    private func shouldStartCaptionFlow(for metadata: RecordingMetadata) async -> Bool {
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
