//
//  DashboardView.swift
//  FrameFlow
//

import SwiftUI
import AppKit

private enum DashboardRecordingSort: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case name = "Name"
    case duration = "Duration"

    var id: String { rawValue }
}

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(SettingsStore.self) private var settingsStore
    @State private var recordingStore = RecordingStore.shared
    @State private var deleteErrorMessage: String?
    @State private var searchText = ""
    @State private var sortOption: DashboardRecordingSort = .recent
    @State private var showAllRecordings = false
    @State private var feedbackBannerVisible = false

    private let gridColumns = [
        GridItem(.adaptive(minimum: 240, maximum: 300), spacing: 20)
    ]

    private static let collapsedRecordingLimit = 8

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    DashboardWelcomeHeader(
                        displayName: welcomeName,
                        initials: UserDisplayHelpers.initials(for: appState.currentUser),
                        showsUpgrade: !appState.isPro,
                        searchText: $searchText,
                        onUpgrade: {
                            AnalyticsService.trackUpgradeClicked(source: "dashboard")
                            router.navigate(to: .subscription)
                        }
                    )

                    DashboardHeroBanner {
                        router.navigate(to: .windowPicker)
                    }

                    if showsExpiryBanner {
                        ExpiryBannerView(
                            status: appState.subscriptionStatus,
                            onRenew: {
                                AnalyticsService.trackUpgradeClicked(source: "expiry_banner")
                                router.navigate(to: .subscription)
                            },
                            onDismiss: { settingsStore.expiryBannerDismissed = true }
                        )
                    }

                    recordingsSection
                }
                .padding(28)
                .padding(.bottom, feedbackBannerVisible ? 88 : 0)
            }

            if feedbackBannerVisible {
                DashboardFeedbackBanner(
                    onShareFeedback: openFeedbackForm,
                    onDismiss: dismissFeedbackBanner
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: feedbackBannerVisible)
        .navigationTitle("")
        .alert("Couldn’t delete recording", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "Try again or remove the file manually in Finder.")
        }
        .task {
            await recordingStore.load()
            #if DEBUG
            try? recordingStore.loadDebugMocksIfNeeded()
            #endif
            refreshFeedbackBannerVisibility()
        }
        .onAppear {
            refreshFeedbackBannerVisibility()
        }
        #if DEBUG
        .toolbar {
            if !subscriptionManager.isConfigured {
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
                        Divider()
                        Button("Feedback: reset prompt") {
                            settingsStore.feedbackPromptLastPresentedAt = nil
                            settingsStore.completedExportCount = 0
                            refreshFeedbackBannerVisibility()
                        }
                        Button("Feedback: simulate 3 exports") {
                            settingsStore.completedExportCount = 3
                            settingsStore.feedbackPromptLastPresentedAt = nil
                            refreshFeedbackBannerVisibility()
                        }
                    }
                }
            }
        }
        #endif
    }

    private var welcomeName: String {
        let name = UserDisplayHelpers.displayName(for: appState.currentUser)
        if name == "Guest" || name == "User" {
            return "there"
        }
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    private var showsExpiryBanner: Bool {
        needsSubscriptionAttention && !settingsStore.expiryBannerDismissed
    }

    private var needsSubscriptionAttention: Bool {
        appState.subscriptionStatus == .past_due || appState.subscriptionStatus == .expired
    }

    private func refreshFeedbackBannerVisibility() {
        let shouldShow = settingsStore.shouldShowFeedbackPrompt()
        if shouldShow, !feedbackBannerVisible {
            settingsStore.recordFeedbackPromptPresented()
            AnalyticsService.trackFeedbackPromptShown(exportCount: settingsStore.completedExportCount)
        }
        feedbackBannerVisible = shouldShow
    }

    private func openFeedbackForm() {
        guard let url = FeedbackConstants.formURL else { return }
        NSWorkspace.shared.open(url)
        AnalyticsService.trackFeedbackPromptClicked(exportCount: settingsStore.completedExportCount)
        dismissFeedbackBanner()
    }

    private func dismissFeedbackBanner() {
        settingsStore.recordFeedbackPromptPresented()
        feedbackBannerVisible = false
    }

    @ViewBuilder
    private var recordingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Recent Recordings")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                if !recordingStore.recordings.isEmpty {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(DashboardRecordingSort.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 120)
                }
            }

            if recordingStore.isLoading {
                loadingState
            } else if sortedFilteredRecordings.isEmpty {
                if recordingStore.recordings.isEmpty {
                    emptyState
                } else {
                    noSearchResultsState
                }
            } else {
                recordingsGrid
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Loading recordings…")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary.opacity(0.7))

            Text("No recordings yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Your recordings will appear here after you finish your first session.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Button {
                router.navigate(to: .windowPicker)
            } label: {
                Label("New Recording", systemImage: "record.circle")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.vertical, 24)
    }

    private var noSearchResultsState: some View {
        ContentUnavailableView(
            "No matches",
            systemImage: "magnifyingglass",
            description: Text("Try a different search term.")
        )
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    private var sortedFilteredRecordings: [RecordingMetadata] {
        var items = recordingStore.recordings

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            items = items.filter { $0.name.lowercased().contains(query) }
        }

        switch sortOption {
        case .recent:
            items.sort { $0.createdAt > $1.createdAt }
        case .name:
            items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .duration:
            items.sort { $0.durationSeconds > $1.durationSeconds }
        }

        return items
    }

    private var visibleRecordings: [RecordingMetadata] {
        let items = sortedFilteredRecordings
        guard !showAllRecordings, items.count > Self.collapsedRecordingLimit else {
            return items
        }
        return Array(items.prefix(Self.collapsedRecordingLimit))
    }

    private var showsViewAllTile: Bool {
        !showAllRecordings && sortedFilteredRecordings.count > Self.collapsedRecordingLimit
    }

    private var recordingsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 20) {
            ForEach(visibleRecordings) { recording in
                RecordingListItemView(
                    recording: recording,
                    onTap: { openDetail(for: recording) },
                    onExport: { openExport(for: recording) },
                    onDelete: { deleteRecording(recording) }
                )
            }

            if showsViewAllTile {
                viewAllTile
            }
        }
    }

    private var viewAllTile: some View {
        Button {
            showAllRecordings = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "square.grid.2x2")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                Text("View all recordings")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .padding(20)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColors.border, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            }
        }
        .buttonStyle(.plain)
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
        let url = URL(fileURLWithPath: recording.filePath)
        try? SecurityScopedFileAccess.withAccess(to: url) {
            RecordingFileCleanup.deleteExportedRecordingFiles(for: recording)
        }
        RecordingThumbnailService.removeCached(forFilePath: recording.filePath)

        do {
            try recordingStore.remove(id: recording.id)
        } catch {
            deleteErrorMessage = "The recording file may have been moved or deleted. Try again, or remove it from your save folder in Finder."
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
        .environment(AppRouter())
        .environment(SubscriptionManager.shared)
        .environment(SettingsStore.shared)
}
