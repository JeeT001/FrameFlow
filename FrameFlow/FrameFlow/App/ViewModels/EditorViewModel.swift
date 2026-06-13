//
//  EditorViewModel.swift
//  FrameFlow
//

import AppKit
import AVFoundation
import Foundation
import UniformTypeIdentifiers

@MainActor
@Observable
final class EditorViewModel {
    var inspectorMode: EditorInspectorMode = .edit
    var selection: EditorSelection = .none
    var project = EditorProjectModel()
    var platformPreviewOverlay: PlatformPreviewOverlay = .none

    var importError: String?
    var playheadFlash = false
    /// Playhead on the master/export ruler (extends past video when imported audio is longer).
    var masterPlayheadSeconds: Double = 0
    private var audioOnlyPlaybackTimer: Timer?
    /// True while the user expects preview to keep running (video and/or imported audio).
    private var userRequestedPlayback = false

    var isPreviewPlaying: Bool {
        captionViewModel.player.rate > 0 || audioOnlyPlaybackTimer != nil
    }

    var isPlayheadInAudioOnlyRegion: Bool {
        guard project.hasAudioTimelineExtension else { return false }
        return masterPlayheadSeconds > project.videoExportDurationSeconds + 0.02
    }

    var previewTransportLabel: String {
        if isPreviewPlaying {
            return isPlayheadInAudioOnlyRegion ? "Pause audio" : "Pause"
        }
        if isPlayheadInAudioOnlyRegion {
            return "Play audio"
        }
        return "Play"
    }

    var previewTransportIcon: String {
        isPreviewPlaying ? "pause.fill" : "play.fill"
    }

    let captionViewModel = CaptionEditorViewModel()
    let exportViewModel = ExportViewModel()
    private let audioPreview = EditorAudioPreviewService()

    var editTimeline: EditTimelineModel {
        get { project.timeline }
        set { project.timeline = newValue }
    }

    var sourceDurationSeconds: Double { project.timeline.sourceDurationSeconds }
    var trimStartSeconds: Double { project.timeline.trimStartSeconds }
    var trimEndSeconds: Double { project.timeline.trimEndSeconds }

    var hasTrimApplied: Bool { project.timeline.hasTrimApplied }
    var hasRemovedRegions: Bool { project.timeline.hasRemovedRegions }
    var hasMiddleDelete: Bool { hasRemovedRegions }

    var formattedExportDuration: String {
        TrimHelpers.formatExportDurationDisplay(
            project.exportDurationSeconds,
            sourceDuration: project.timeline.sourceDurationSeconds
        )
    }

    var formattedRemovedSpan: String? {
        guard hasRemovedRegions else { return nil }
        return TrimHelpers.formatTimelineTime(project.timeline.totalRemovedSeconds)
    }

    func exportSummary(
        isPro: Bool,
        applyCaptions: Bool,
        alsoSaveSRT: Bool,
        resolution: ExportResolution
    ) -> [String] {
        var lines: [String] = []

        lines.append("Length: \(TrimHelpers.formatTimelineTime(sourceDurationSeconds))")

        if isPro, applyCaptions, exportViewModel.hasCaptionsAvailable, !captionViewModel.segments.isEmpty {
            let style = captionViewModel.selectedStyle
            let position = style.verticalPosition.rawValue.capitalized
            lines.append("Captions: burned in (\(style.displayName), \(position))")
        }

        lines.append("Resolution: \(resolution.displayName)")
        lines.append(isPro ? "No watermark" : "Watermark: FrameFlow")

        if isPro, alsoSaveSRT, applyCaptions, !captionViewModel.segments.isEmpty {
            lines.append("SRT file saved alongside MP4")
        }

        return lines
    }

    func selectTimeline() {
        selection = .timeline
        inspectorMode = .edit
    }

    func selectImageOverlay(id: UUID) {
        guard project.imageOverlays.contains(where: { $0.id == id }) else { return }
        selection = .imageOverlay(id)
        inspectorMode = .edit
    }

    func selectImportedAudio(id: UUID) {
        guard project.importedAudioTracks.contains(where: { $0.id == id }) else { return }
        selection = .importedAudio(id)
        inspectorMode = .edit
    }

    var selectedImageOverlayID: UUID? {
        if case .imageOverlay(let id) = selection { return id }
        return nil
    }

    var selectedImportedAudioID: UUID? {
        if case .importedAudio(let id) = selection { return id }
        return nil
    }

    func imageOverlay(id: UUID) -> EditorImageOverlay? {
        project.imageOverlays.first { $0.id == id }
    }

    func importedAudio(id: UUID) -> EditorImportedAudio? {
        project.importedAudioTracks.first { $0.id == id }
    }

    var selectedImageOverlay: EditorImageOverlay? {
        guard let id = selectedImageOverlayID else { return nil }
        return imageOverlay(id: id)
    }

    var selectedImportedAudio: EditorImportedAudio? {
        guard let id = selectedImportedAudioID else { return nil }
        return importedAudio(id: id)
    }

    private func shortLayerLabel(_ filename: String, prefix: String) -> String {
        let stem = (filename as NSString).deletingPathExtension
        if stem.count <= 8 { return prefix }
        return "\(prefix) \(stem.prefix(6))…"
    }

    private func mutateImageOverlay(id: UUID, _ body: (inout EditorImageOverlay) -> Void) {
        guard let index = project.imageOverlays.firstIndex(where: { $0.id == id }) else { return }
        var overlay = project.imageOverlays[index]
        body(&overlay)
        project.imageOverlays[index] = overlay
    }

    private func mutateImportedAudio(id: UUID, _ body: (inout EditorImportedAudio) -> Void) {
        guard let index = project.importedAudioTracks.firstIndex(where: { $0.id == id }) else { return }
        var audio = project.importedAudioTracks[index]
        body(&audio)
        project.importedAudioTracks[index] = audio
    }

    func selectCaptions() {
        selection = .captions
        inspectorMode = .captions
    }

    func selectCaptionSegment(_ id: UUID) {
        selection = .captionSegment(id)
        inspectorMode = .captions
        captionViewModel.selectedSegmentID = id
    }

    func clearSelection() {
        selection = .none
    }

    func removeRemovedRange(at index: Int) {
        project.timeline.removeRemovedRange(at: index)
        syncPlayback()
    }

    func load(appState: AppState, isPro: Bool) {
        exportViewModel.load(
            exportRecordingID: appState.exportRecordingID,
            pendingRecording: appState.pendingRecording,
            isPro: isPro
        )
        exportViewModel.editTimeline = nil
        exportViewModel.editorProject = nil
        exportViewModel.exportDurationOverride = nil

        guard let recording = exportViewModel.recording else { return }

        let url = URL(fileURLWithPath: recording.filePath)
        let deferPlayer = isPro && CaptionGenerationState.shared.isTranscribing
        captionViewModel.loadPreview(url: url, recording: recording, deferPlayerLoad: deferPlayer)
        configureTrim(from: captionViewModel.videoDuration)

        captionViewModel.editTimeline = nil
        captionViewModel.playbackRange = nil

        if isPro {
            captionViewModel.sync(from: CaptionGenerationState.shared)
        }

        if recording.format != "9:16" {
            platformPreviewOverlay = .none
        }
    }

    func onVideoDurationLoaded(_ duration: Double) {
        configureTrim(from: duration)
    }

    func onCaptionGenerationFinished(isPro: Bool) {
        captionViewModel.loadDeferredPlayerIfNeeded()
        if isPro {
            captionViewModel.sync(from: CaptionGenerationState.shared)
        }
    }

    func configureTrim(from duration: Double) {
        project.configureSourceDuration(duration)
        captionViewModel.editTimeline = nil
        captionViewModel.playbackRange = nil
        masterPlayheadSeconds = 0
        syncPlayback()
    }

    func updateTrimStart(_ value: Double) {
        project.timeline.updateTrimStart(value)
        clampImageOverlayToTrim()
        clampImportedAudioTracks()
        syncPlayback()
    }

    func updateTrimEnd(_ value: Double) {
        project.timeline.updateTrimEnd(value)
        clampImageOverlayToTrim()
        clampImportedAudioTracks()
        syncPlayback()
    }

    func splitAtPoint(_ sourceSeconds: Double) {
        let minSpan = EditTimelineModel.minimumSpanSeconds
        let clamped = max(
            project.timeline.trimStartSeconds + minSpan,
            min(sourceSeconds, project.timeline.trimEndSeconds - minSpan)
        )
        guard !project.timeline.splitPoints.contains(where: { abs($0 - clamped) < 0.05 }) else { return }
        project.timeline.addSplitPoint(at: clamped)
        if let exportTime = CaptionTimelineMapper.exportTime(
            fromSourceTime: clamped,
            editTimeline: project.timeline
        ) {
            seekPreviewOnMasterTimeline(exportTime)
        } else {
            seekPreviewOnSourceTimeline(clamped)
        }
    }

    func moveSplitPoint(at index: Int, to newSourceSeconds: Double) {
        guard project.timeline.canMoveSplitBoundary(at: index) else { return }
        project.timeline.moveSplitPoint(at: index, to: newSourceSeconds)
        syncPlayback()
    }

    func trimVideoSegmentOut(segmentID: Int, newEffectiveEnd: Double) {
        guard let segment = project.timeline.videoClipSegments().first(where: { $0.id == segmentID }) else { return }
        project.timeline.trimSegmentOut(segment: segment, newEffectiveEnd: newEffectiveEnd)
        afterSegmentEdit(seekTo: newEffectiveEnd)
    }

    func trimVideoSegmentIn(segmentID: Int, newEffectiveStart: Double) {
        guard let segment = project.timeline.videoClipSegments().first(where: { $0.id == segmentID }) else { return }
        project.timeline.trimSegmentIn(segment: segment, newEffectiveStart: newEffectiveStart)
        afterSegmentEdit(seekTo: newEffectiveStart)
    }

    func extendVideoSegmentOut(segmentID: Int, newEffectiveEnd: Double) {
        guard let segment = project.timeline.videoClipSegments().first(where: { $0.id == segmentID }) else { return }
        project.timeline.extendSegmentOut(segment: segment, newEffectiveEnd: newEffectiveEnd)
        afterSegmentEdit(seekTo: newEffectiveEnd)
    }

    func extendVideoSegmentIn(segmentID: Int, newEffectiveStart: Double) {
        guard let segment = project.timeline.videoClipSegments().first(where: { $0.id == segmentID }) else { return }
        project.timeline.extendSegmentIn(segment: segment, newEffectiveStart: newEffectiveStart)
        afterSegmentEdit(seekTo: newEffectiveStart)
    }

    func rippleCloseVideoGap(leftSegmentID: Int, rightSegmentID: Int, joinAt: Double) {
        let segments = project.timeline.videoClipSegments()
        guard let left = segments.first(where: { $0.id == leftSegmentID }),
              let right = segments.first(where: { $0.id == rightSegmentID }) else { return }
        project.timeline.rippleCloseGap(leftSegment: left, rightSegment: right, joinAt: joinAt)
        afterSegmentEdit(seekTo: joinAt)
    }

    func moveVideoSplitBoundary(splitIndex: Int, to newSourceSeconds: Double) {
        project.timeline.moveSplitPoint(at: splitIndex, to: newSourceSeconds)
        afterSegmentEdit(seekTo: newSourceSeconds)
    }

    func reorderSegment(from fromIndex: Int, to toIndex: Int) {
        var updated = project.timeline
        updated.moveSegment(from: fromIndex, to: toIndex)
        project.timeline = updated
        masterPlayheadSeconds = min(
            masterPlayheadSeconds,
            project.timeline.exportDurationSeconds
        )
        syncPlayback()
    }

    private func afterSegmentEdit(seekTo sourceTime: Double) {
        clampImageOverlayToTrim()
        clampImportedAudioTracks()
        syncPlayback()
        seekPreviewOnSourceTimeline(sourceTime)
    }

    func jumpToStart() {
        seekPreviewOnSourceTimeline(project.timeline.trimStartSeconds)
        triggerPlayheadFlash()
    }

    func jumpToEnd() {
        seekPreviewOnSourceTimeline(project.timeline.trimEndSeconds)
        triggerPlayheadFlash()
    }

    private func triggerPlayheadFlash() {
        playheadFlash = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            playheadFlash = false
        }
    }

    func clearSplitPoints() {
        project.timeline.clearSplitPoints()
        syncPlayback()
    }

    func splitAtPlayhead(currentTime: Double) {
        splitAtPoint(currentTime)
    }

    func importImage() {
        importError = nil
        let panel = NSOpenPanel()
        panel.title = "Import image overlays"
        panel.allowedContentTypes = [.png, .jpeg]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, !panel.urls.isEmpty else { return }

        var lastID: UUID?
        for (index, url) in panel.urls.enumerated() {
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Could not access \(url.lastPathComponent)."
                continue
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let playhead = captionViewModel.currentPlaybackTime + Double(index) * 0.25
            let interval = EditorImageOverlay.defaultInterval(
                playhead: playhead,
                trimStart: project.timeline.trimStartSeconds,
                trimEnd: project.timeline.trimEndSeconds
            )

            var overlay = EditorImageOverlay(
                fileURL: url,
                startSeconds: interval.start,
                endSeconds: interval.end
            )
            let layerIndex = project.imageOverlays.count + index
            overlay.normalizedCenterX = min(0.9, overlay.normalizedCenterX - Double(layerIndex) * 0.06)
            overlay.normalizedCenterY = min(0.9, overlay.normalizedCenterY + Double(layerIndex) * 0.04)

            let imageAspect = EditorImageOverlay.imageAspectRatio(for: url)
            let clamped = overlay.clampedCenter(
                x: overlay.normalizedCenterX,
                y: overlay.normalizedCenterY,
                containerAspect: previewContainerAspect,
                imageAspect: imageAspect
            )
            overlay.normalizedCenterX = clamped.x
            overlay.normalizedCenterY = clamped.y
            project.imageOverlays.append(overlay)
            lastID = overlay.id
        }

        if let lastID {
            selection = .imageOverlay(lastID)
            inspectorMode = .edit
        }
    }

    func importAudio() {
        importError = nil
        let panel = NSOpenPanel()
        panel.title = "Import audio"
        panel.allowedContentTypes = [.mp3, .wav, .aiff, .mpeg4Audio]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, !panel.urls.isEmpty else { return }

        var lastID: UUID?
        var nextStart: Double = 0
        for url in panel.urls {
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Could not access \(url.lastPathComponent)."
                continue
            }
            let sourceDuration = Self.loadSourceAudioDuration(url: url)
            url.stopAccessingSecurityScopedResource()

            var track = EditorImportedAudio.importedFullLength(
                fileURL: url,
                sourceDuration: sourceDuration,
                timelineStart: nextStart
            )
            track.clampTimelineToMaster()
            project.importedAudioTracks.append(track)
            nextStart = track.timelineEndSeconds + 0.5
            lastID = track.id
        }

        if let lastID {
            selection = .importedAudio(lastID)
            inspectorMode = .edit
            masterPlayheadSeconds = 0
            seekPreviewOnMasterTimeline(0)
        } else {
            refreshAudioPreview()
        }
    }

    private static func loadSourceAudioDuration(url: URL) -> Double {
        if let player = try? AVAudioPlayer(contentsOf: url) {
            return max(player.duration, 0.1)
        }
        let asset = AVURLAsset(url: url)
        let seconds = CMTimeGetSeconds(asset.duration)
        if seconds.isFinite, seconds > 0.01 {
            return seconds
        }
        return 30
    }

    func currentExportPlayheadTime() -> Double {
        masterPlayheadSeconds
    }

    func seekPreviewOnSourceTimeline(_ sourceTime: Double) {
        let exportTime = CaptionTimelineMapper.exportTime(
            fromSourceTime: sourceTime,
            editTimeline: project.timeline
        ) ?? sourceTime
        seekPreviewOnMasterTimeline(exportTime)
    }

    func seekPreviewOnMasterTimeline(_ masterTime: Double) {
        pausePreview()
        let clamped = min(max(0, masterTime), project.masterTimelineDurationSeconds)
        masterPlayheadSeconds = clamped

        let videoEnd = project.videoExportDurationSeconds
        if clamped <= videoEnd + 0.02 {
            let source = CaptionTimelineMapper.sourceTime(
                fromExportTime: clamped,
                editTimeline: project.timeline
            )
            captionViewModel.seek(to: source)
        } else {
            parkVideoAtExportEnd()
        }
        refreshAudioPreview()
    }

    /// Called when the video playhead moves — keeps master time in sync and hands off to audio.
    func onPreviewTimeTick() {
        if captionViewModel.player.rate > 0 {
            syncMasterPlayheadFromVideoIfNeeded()
            handoffToAudioOnlyIfVideoReachedEnd()
        } else if userRequestedPlayback {
            tryContinueWithAudioAfterVideoEnd()
        }
        refreshAudioPreview()
    }

    func refreshAudioPreview() {
        let isVideoPlaying = captionViewModel.player.rate > 0
        let isAudioOnlyPlaying = audioOnlyPlaybackTimer != nil
        audioPreview.sync(
            tracks: project.importedAudioTracks,
            exportTime: masterPlayheadSeconds,
            isVideoPlaying: isVideoPlaying || isAudioOnlyPlaying,
            mutedTrackIDs: []
        )
    }

    private func syncMasterPlayheadFromVideoIfNeeded() {
        guard let exportFromSource = CaptionTimelineMapper.exportTime(
            fromSourceTime: captionViewModel.currentPlaybackTime,
            editTimeline: project.timeline
        ) else { return }
        let videoEnd = project.videoExportDurationSeconds
        if exportFromSource <= videoEnd + 0.05 {
            masterPlayheadSeconds = exportFromSource
        }
    }

    private func handoffToAudioOnlyIfVideoReachedEnd() {
        guard userRequestedPlayback else { return }
        guard project.hasAudioTimelineExtension else { return }
        let videoEnd = project.videoExportDurationSeconds
        guard masterPlayheadSeconds >= videoEnd - 0.12 else { return }
        guard masterPlayheadSeconds < project.masterTimelineDurationSeconds - 0.05 else {
            pausePreview()
            return
        }
        guard audioOnlyPlaybackTimer == nil else { return }

        let sourceEnd = project.timeline.keptSourceRanges.last?.end ?? project.timeline.trimEndSeconds
        guard captionViewModel.currentPlaybackTime >= sourceEnd - 0.12 else { return }

        captionViewModel.player.pause()
        beginAudioOnlyPlayback(from: max(masterPlayheadSeconds, videoEnd))
    }

    private func tryContinueWithAudioAfterVideoEnd() {
        guard audioOnlyPlaybackTimer == nil else { return }
        guard project.hasAudioTimelineExtension else { return }
        let videoEnd = project.videoExportDurationSeconds
        guard masterPlayheadSeconds >= videoEnd - 0.15 else { return }
        guard masterPlayheadSeconds < project.masterTimelineDurationSeconds - 0.05 else {
            userRequestedPlayback = false
            return
        }
        beginAudioOnlyPlayback(from: masterPlayheadSeconds)
    }

    private func parkVideoAtExportEnd() {
        let endSource = project.timeline.keptSourceRanges.last?.end ?? project.timeline.trimEndSeconds
        captionViewModel.seek(to: endSource)
    }

    private func beginAudioOnlyPlayback(from masterTime: Double) {
        stopAudioOnlyPlayback()
        captionViewModel.player.pause()
        masterPlayheadSeconds = min(max(0, masterTime), project.masterTimelineDurationSeconds)

        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickAudioOnlyPlayback()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        audioOnlyPlaybackTimer = timer
        refreshAudioPreview()
    }

    private func tickAudioOnlyPlayback() {
        let end = project.masterTimelineDurationSeconds
        guard masterPlayheadSeconds < end - 0.02 else {
            masterPlayheadSeconds = end
            userRequestedPlayback = false
            stopAudioOnlyPlayback()
            refreshAudioPreview()
            return
        }
        masterPlayheadSeconds += 0.05
        refreshAudioPreview()
    }

    private func stopAudioOnlyPlayback() {
        audioOnlyPlaybackTimer?.invalidate()
        audioOnlyPlaybackTimer = nil
    }

    func pausePreview() {
        userRequestedPlayback = false
        stopAudioOnlyPlayback()
        captionViewModel.player.pause()
        refreshAudioPreview()
    }

    func playPreview() {
        let videoEnd = project.videoExportDurationSeconds
        let masterEnd = project.masterTimelineDurationSeconds

        if masterPlayheadSeconds >= masterEnd - 0.02 {
            seekPreviewOnMasterTimeline(0)
        }

        userRequestedPlayback = true

        if project.hasAudioTimelineExtension, masterPlayheadSeconds >= videoEnd - 0.02 {
            beginAudioOnlyPlayback(from: masterPlayheadSeconds)
            return
        }

        let source = CaptionTimelineMapper.sourceTime(
            fromExportTime: masterPlayheadSeconds,
            editTimeline: project.timeline
        )
        captionViewModel.seek(to: source)
        captionViewModel.player.play()
        refreshAudioPreview()
    }

    func togglePlayback() {
        if isPreviewPlaying {
            pausePreview()
        } else {
            playPreview()
        }
    }

    func sourceTimeAtPlayhead() -> Double {
        if masterPlayheadSeconds <= project.videoExportDurationSeconds + 0.02 {
            return CaptionTimelineMapper.sourceTime(
                fromExportTime: masterPlayheadSeconds,
                editTimeline: project.timeline
            )
        }
        return project.timeline.keptSourceRanges.last?.end ?? project.timeline.trimEndSeconds
    }

    func removeImageOverlay(id: UUID? = nil) {
        let targetID = id ?? selectedImageOverlayID
        guard let targetID else { return }
        project.imageOverlays.removeAll { $0.id == targetID }
        if case .imageOverlay(let selectedID) = selection, selectedID == targetID {
            selection = project.imageOverlays.isEmpty ? .none : .imageOverlay(project.imageOverlays.last!.id)
        }
    }

    func removeImportedAudio(id: UUID? = nil) {
        let targetID = id ?? selectedImportedAudioID
        guard let targetID else { return }
        project.importedAudioTracks.removeAll { $0.id == targetID }
        if case .importedAudio(let selectedID) = selection, selectedID == targetID {
            selection = project.importedAudioTracks.isEmpty
                ? .none
                : .importedAudio(project.importedAudioTracks.last!.id)
        }
        refreshAudioPreview()
    }

    func updateImageOpacity(_ opacity: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImageOverlayID else { return }
        mutateImageOverlay(id: targetID) { overlay in
            overlay.opacity = min(max(opacity, 0), 1)
        }
    }

    var previewContainerAspect: Double {
        Double(exportViewModel.recording?.previewAspectRatio ?? (16.0 / 9.0))
    }

    func updateImagePosition(x: Double, y: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImageOverlayID else { return }
        mutateImageOverlay(id: targetID) { overlay in
            let imageAspect = EditorImageOverlay.imageAspectRatio(for: overlay.fileURL)
            let clamped = overlay.clampedCenter(
                x: x,
                y: y,
                containerAspect: previewContainerAspect,
                imageAspect: imageAspect
            )
            overlay.normalizedCenterX = clamped.x
            overlay.normalizedCenterY = clamped.y
        }
    }

    func updateImageWidth(_ width: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImageOverlayID else { return }
        mutateImageOverlay(id: targetID) { overlay in
            let imageAspect = EditorImageOverlay.imageAspectRatio(for: overlay.fileURL)
            overlay.normalizedWidth = overlay.clampedWidth(width)
            let clamped = overlay.clampedCenter(
                x: overlay.normalizedCenterX,
                y: overlay.normalizedCenterY,
                normalizedWidth: overlay.normalizedWidth,
                containerAspect: previewContainerAspect,
                imageAspect: imageAspect
            )
            overlay.normalizedCenterX = clamped.x
            overlay.normalizedCenterY = clamped.y
        }
    }

    func updateImportedAudioVolume(_ volume: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImportedAudioID else { return }
        mutateImportedAudio(id: targetID) { audio in
            audio.volume = min(max(volume, 0), 1)
        }
        refreshAudioPreview()
    }

    func updateImportedAudioStart(_ seconds: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImportedAudioID else { return }
        mutateImportedAudio(id: targetID) { audio in
            let minSpan = EditTimelineModel.minimumSpanSeconds
            audio.timelineStartSeconds = min(
                max(0, seconds),
                audio.timelineEndSeconds - minSpan
            )
            audio.clampTimelineToMaster()
        }
        refreshAudioPreview()
    }

    func updateImportedAudioEnd(_ seconds: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImportedAudioID else { return }
        mutateImportedAudio(id: targetID) { audio in
            let minSpan = EditTimelineModel.minimumSpanSeconds
            let minEnd = audio.timelineStartSeconds + minSpan
            let maxEnd = audio.timelineStartSeconds + audio.sourceTrimDuration
            audio.timelineEndSeconds = min(max(seconds, minEnd), maxEnd)
            audio.clampTimelineToMaster()
        }
        refreshAudioPreview()
        recalculateMasterTimelineAfterAudioTrim()
    }

    private func recalculateMasterTimelineAfterAudioTrim() {
        if masterPlayheadSeconds > project.masterTimelineDurationSeconds {
            masterPlayheadSeconds = project.masterTimelineDurationSeconds
        }
    }

    func updateImportedAudioClipMove(toStart start: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImportedAudioID else { return }
        mutateImportedAudio(id: targetID) { audio in
            let duration = max(audio.playDuration, EditTimelineModel.minimumSpanSeconds)
            audio.timelineStartSeconds = max(0, start)
            audio.timelineEndSeconds = audio.timelineStartSeconds + duration
            audio.clampTimelineToMaster()
        }
        refreshAudioPreview()
    }

    func updateImportedAudioSourceTrimStart(_ seconds: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImportedAudioID else { return }
        mutateImportedAudio(id: targetID) { audio in
            let minSpan = EditTimelineModel.minimumSpanSeconds
            audio.sourceTrimStartSeconds = min(
                max(0, seconds),
                audio.sourceTrimEndSeconds - minSpan
            )
            audio.clampSourceTrim()
            audio.clampTimelineToMaster()
        }
        refreshAudioPreview()
    }

    func updateImportedAudioSourceTrimEnd(_ seconds: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImportedAudioID else { return }
        mutateImportedAudio(id: targetID) { audio in
            let minSpan = EditTimelineModel.minimumSpanSeconds
            audio.sourceTrimEndSeconds = max(
                min(audio.sourceDurationSeconds, seconds),
                audio.sourceTrimStartSeconds + minSpan
            )
            audio.clampSourceTrim()
            audio.clampTimelineToMaster()
        }
        refreshAudioPreview()
    }

    func updateImageStart(_ seconds: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImageOverlayID else { return }
        mutateImageOverlay(id: targetID) { overlay in
            let minSpan = EditTimelineModel.minimumSpanSeconds
            overlay.startSeconds = min(seconds, overlay.endSeconds - minSpan)
            applyImageOverlayTiming(&overlay)
        }
    }

    func updateImageEnd(_ seconds: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImageOverlayID else { return }
        mutateImageOverlay(id: targetID) { overlay in
            let minSpan = EditTimelineModel.minimumSpanSeconds
            overlay.endSeconds = max(seconds, overlay.startSeconds + minSpan)
            applyImageOverlayTiming(&overlay)
        }
    }

    func updateImageClipMove(toStart start: Double, id: UUID? = nil) {
        guard let targetID = id ?? selectedImageOverlayID else { return }
        mutateImageOverlay(id: targetID) { overlay in
            let span = overlay.duration
            overlay.startSeconds = start
            overlay.endSeconds = start + span
            applyImageOverlayTiming(&overlay)
        }
    }

    var isImageVisibleAtPlayhead: Bool {
        guard let id = selectedImageOverlayID, let overlay = imageOverlay(id: id) else { return false }
        return overlay.contains(playhead: captionViewModel.currentPlaybackTime)
    }

    func visibleImageOverlays(at playhead: Double) -> [EditorImageOverlay] {
        project.imageOverlays.filter { $0.contains(playhead: playhead) }
    }

    func exportRecording(isPro: Bool, appState: AppState) async {
        if isPro, !captionViewModel.segments.isEmpty {
            do {
                try await saveCaptionsBeforeExport()
            } catch SecurityScopedFileAccess.AccessError.denied {
                exportViewModel.exportError = SecurityScopedFileAccess.accessDeniedMessage
                return
            } catch {
                exportViewModel.exportError = ExportDiskSpaceChecker.userFacingExportError(error)
                return
            }
        }

        exportViewModel.editorProject = nil
        exportViewModel.editTimeline = nil
        exportViewModel.exportDurationOverride = nil

        await exportViewModel.export(isPro: isPro, appState: appState)

        guard exportViewModel.exportedURL != nil, exportViewModel.exportError == nil else { return }

        if isPro, exportViewModel.alsoSaveSRT, exportViewModel.hasCaptionsAvailable {
            await writeExportSRT(isPro: isPro)
        }
    }

    func discard(appState: AppState) {
        exportViewModel.discardPending(appState: appState)
        CaptionGenerationState.shared.reset()
        teardown()
    }

    func teardown() {
        pausePreview()
        audioPreview.teardown()
        captionViewModel.editTimeline = nil
        captionViewModel.playbackRange = nil
        captionViewModel.teardown()
        exportViewModel.teardown()
    }

    func seekPreview(to time: Double) {
        seekPreviewOnSourceTimeline(time)
    }

    private func syncPlayback() {
        captionViewModel.editTimeline = nil
        captionViewModel.playbackRange = nil
    }

    private func clampImageOverlayToTrim() {
        for index in project.imageOverlays.indices {
            var overlay = project.imageOverlays[index]
            applyImageOverlayTiming(&overlay)
            project.imageOverlays[index] = overlay
        }
    }

    private func applyImageOverlayTiming(_ overlay: inout EditorImageOverlay) {
        let interval = overlay.clampedInterval(
            trimStart: trimStartSeconds,
            trimEnd: trimEndSeconds
        )
        overlay.startSeconds = interval.start
        overlay.endSeconds = interval.end
    }

    private func clampImportedAudioTracks() {
        for index in project.importedAudioTracks.indices {
            project.importedAudioTracks[index].clampTimelineToMaster()
        }
        if masterPlayheadSeconds > project.masterTimelineDurationSeconds {
            masterPlayheadSeconds = project.masterTimelineDurationSeconds
        }
        refreshAudioPreview()
    }

    private func clampPlaybackToEdit() {
        let snapped = CaptionTimelineMapper.snapToKeptSourceTime(
            captionViewModel.currentPlaybackTime,
            editTimeline: project.timeline
        )
        if abs(snapped - captionViewModel.currentPlaybackTime) > 0.01 {
            captionViewModel.seek(to: snapped)
        }
    }

    private func saveCaptionsBeforeExport() async throws {
        guard let recording = exportViewModel.recording else { return }
        let url = URL(fileURLWithPath: recording.filePath)
        try await SecurityScopedFileAccess.withAccess(to: url) {
            try CaptionEngine.shared.saveCaptions(
                captionViewModel.segments,
                for: url,
                recordingID: recording.id,
                style: captionViewModel.selectedStyle
            )
        }
    }

    private func writeExportSRT(isPro: Bool) async {
        guard isPro,
              let exportedURL = exportViewModel.exportedURL else { return }

        let segments = CaptionTimelineMapper.segmentsForExportTimeline(
            from: captionViewModel.segments,
            editTimeline: project.timeline.preparedForExport()
        )
        guard !segments.isEmpty else { return }

        let srtURL = exportedURL.deletingPathExtension().appendingPathExtension("srt")
        do {
            try await SecurityScopedFileAccess.withAccess(to: exportedURL) {
                try CaptionRenderer.shared.writeSRT(segments: segments, to: srtURL)
            }
        } catch {
            exportViewModel.exportError = "MP4 exported but SRT save failed: \(error.localizedDescription)"
        }
    }
}
