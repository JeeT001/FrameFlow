//
//  DashboardView.swift
//  FrameFlow
//

import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var recordingStore = RecordingStore.shared

    private let gridColumns = [
        GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if showsSubscriptionBanner {
                    subscriptionBanner
                }

                topBar
                newRecordingButton

                if recordingStore.isLoading {
                    ProgressView("Loading recordings…")
                        .frame(maxWidth: .infinity, minHeight: 160)
                } else if recordingStore.recordings.isEmpty {
                    emptyState
                } else {
                    recordingsGrid
                }
            }
            .padding(24)
        }
        .navigationTitle("Home")
        .task {
            await recordingStore.load()
            #if DEBUG
            try? recordingStore.loadDebugMocksIfNeeded()
            #endif
        }
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu("Debug") {
                    Button("Subscription: Free") { appState.subscriptionStatus = .free }
                    Button("Subscription: Active (Pro)") { appState.subscriptionStatus = .active }
                    Button("Subscription: Past Due") { appState.subscriptionStatus = .past_due }
                    Button("Subscription: Expired") { appState.subscriptionStatus = .expired }
                    Divider()
                    Button("Test window fetch") {
                        Task {
                            await WindowCaptureService.shared.debugLogWindowFetch()
                        }
                    }
                }
            }
        }
        #endif
    }

    private var showsSubscriptionBanner: Bool {
        appState.subscriptionStatus == .past_due || appState.subscriptionStatus == .expired
    }

    private var subscriptionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Subscription needs attention")
                    .font(.headline)
                Text(bannerMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Manage Subscription") {
                router.navigate(to: .subscription)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var bannerMessage: String {
        switch appState.subscriptionStatus {
        case .past_due:
            "Your payment is past due. Update billing to keep Pro features."
        case .expired:
            "Your Pro plan has expired. Renew to restore full access."
        default:
            ""
        }
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("FrameFlow")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            userAvatar

            if !appState.isPro {
                Button("Upgrade") {
                    router.navigate(to: .subscription)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var userAvatar: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.2))
            .frame(width: 36, height: 36)
            .overlay {
                Text(UserDisplayHelpers.initials(for: appState.currentUser))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .help(UserDisplayHelpers.displayName(for: appState.currentUser))
    }

    private var newRecordingButton: some View {
        Button {
            router.navigate(to: .windowPicker)
        } label: {
            Label("New Recording", systemImage: "record.circle")
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Text("No recordings yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start your first screen recording to see it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                router.navigate(to: .windowPicker)
            } label: {
                Label("New Recording", systemImage: "record.circle")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.vertical, 24)
    }

    private var recordingsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(recordingStore.recordings) { recording in
                RecordingListItemView(
                    recording: recording,
                    onTap: { openDetail(for: recording) },
                    onExport: { openExport(for: recording) },
                    onDelete: { deleteRecording(recording) }
                )
            }
        }
    }

    private func openDetail(for recording: RecordingMetadata) {
        appState.detailRecordingID = recording.id
        router.navigate(to: .recordingDetail)
    }

    private func openExport(for recording: RecordingMetadata) {
        appState.exportRecordingID = recording.id
        router.navigate(to: .export)
    }

    private func deleteRecording(_ recording: RecordingMetadata) {
        do {
            try recordingStore.remove(id: recording.id)
        } catch {
            // Metadata-only store; ignore delete failures for now.
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
        .environment(AppRouter())
}
