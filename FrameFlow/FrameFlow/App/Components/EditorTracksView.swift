//
//  EditorTracksView.swift
//  FrameFlow
//

import AVFoundation
import SwiftUI

struct EditorImageClipLaneItem: Identifiable {
    let id: UUID
    let start: Double
    let end: Double
    let label: String
    let isSelected: Bool
}

struct EditorAudioClipLaneItem: Identifiable {
    let id: UUID
    let start: Double
    let end: Double
    let label: String
    let fileURL: URL
    let isSelected: Bool
}

struct EditorTracksView: View {
    @Bindable var viewModel: EditorViewModel

    let videoURL: URL
    let duration: Double
    let trimStart: Double
    let trimEnd: Double
    let exportDurationSeconds: Double
    let masterTimelineDuration: Double
    let videoExportDuration: Double
    let masterPlayheadSeconds: Double
    let hasAudioTimelineExtension: Bool
    let removedRanges: [RemovedRange]
    let splitPoints: [Double]
    let selectionStart: Double?
    let selectionEnd: Double?
    let currentTime: Double
    let currentExportTime: Double?
    let imageClips: [EditorImageClipLaneItem]
    let audioClips: [EditorAudioClipLaneItem]
    var videoClipLabel: String = "Video"
    let onTrimStartChange: (Double) -> Void
    let onTrimEndChange: (Double) -> Void
    let onSelectionStartChange: (Double) -> Void
    let onSelectionEndChange: (Double) -> Void
    let onSeek: (Double) -> Void
    let onImageStartChange: (UUID, Double) -> Void
    let onImageEndChange: (UUID, Double) -> Void
    let onImageClipMove: (UUID, Double) -> Void
    let onAudioStartChange: (UUID, Double) -> Void
    let onAudioEndChange: (UUID, Double) -> Void
    let onAudioClipMove: (UUID, Double) -> Void
    let onImportImage: () -> Void
    let onImportAudio: () -> Void
    let onSelectOverlay: (UUID) -> Void
    let onSelectAudio: (UUID) -> Void
    let onSelectTimeline: () -> Void
    let onDeleteSelection: () -> Void
    let onClearDeletes: () -> Void
    let canDeleteSelection: Bool
    let hasRemovedRegions: Bool

    private let minClipDuration = EditTimelineModel.minimumSpanSeconds
    private let toggleYellow = EditorTimelineDesign.trimHandleYellow
    private let toolbarBG = Color(red: 0.14, green: 0.14, blue: 0.14)

    private var imageLaneCount: Int { max(1, imageClips.count) }
    private var audioLaneCount: Int { max(1, audioClips.count) }

    private var timelineStackHeight: CGFloat {
        EditorTimelineLayout.timelineStackHeight(
            imageLaneCount: imageLaneCount,
            audioLaneCount: audioLaneCount
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            filmoraToolbar
                .padding(.horizontal, EditorTimelineLayout.tracksOuterPadding)

            GeometryReader { geometry in
                let baseTrackWidth = EditorTimelineLayout.trackContentWidth(totalWidth: geometry.size.width)
                let effectiveTrackWidth = EditorTimelineLayout.effectiveTrackWidth(
                    baseWidth: baseTrackWidth,
                    zoom: viewModel.timelineZoom
                )
                let rulerDuration = max(masterTimelineDuration, 0.1)
                let pixelsPerSecond = effectiveTrackWidth / CGFloat(rulerDuration)

                ScrollView(.horizontal, showsIndicators: viewModel.timelineZoom > 1.01) {
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            rulerRow(
                                baseTrackWidth: baseTrackWidth,
                                effectiveTrackWidth: effectiveTrackWidth
                            )

                            laneDivider

                            mainTrackRow(effectiveTrackWidth: effectiveTrackWidth, laneIndex: 0)

                            laneDivider

                            overlayLanes(effectiveTrackWidth: effectiveTrackWidth, startingLaneIndex: 1)

                            laneDivider

                            audioLanes(effectiveTrackWidth: effectiveTrackWidth, startingLaneIndex: 1 + imageLaneCount)
                        }

                        playheadLine(
                            pixelsPerSecond: pixelsPerSecond,
                            totalHeight: timelineStackHeight
                        )
                        .zIndex(10)

                        playheadHandle(
                            pixelsPerSecond: pixelsPerSecond,
                            rulerDuration: rulerDuration
                        )
                        .zIndex(11)
                    }
                    .frame(
                        width: EditorTimelineLayout.laneControlWidth + effectiveTrackWidth,
                        alignment: .topLeading
                    )
                    .coordinateSpace(name: "timeline")
                }
                .scrollDisabled(viewModel.timelineZoom <= 1.01)
            }
            .frame(height: timelineStackHeight)
            .padding(.horizontal, EditorTimelineLayout.tracksOuterPadding)
        }
        .padding(.vertical, EditorTimelineLayout.tracksOuterPadding)
        .background(EditorTimelineDesign.timelineBackground)
        .overlay(alignment: .top) {
            if let toast = viewModel.toastMessage {
                Text(toast)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.85), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.top, 4)
            }
        }
        .onKeyPress(.escape) {
            if viewModel.razorModeActive {
                viewModel.razorModeActive = false
                return .handled
            }
            return .ignored
        }
        .onChange(of: viewModel.videoLaneMuted) { _, muted in
            viewModel.captionViewModel.player.isMuted = muted
        }
    }

    private var filmoraToolbar: some View {
        VStack(spacing: EditorTimelineDesign.toolbarRowGap) {
            editToolsRow
                .frame(height: EditorTimelineDesign.toolbarHeight)
            timelineControlsRow
                .frame(height: EditorTimelineDesign.toolbarHeight)
        }
        .padding(.vertical, 4)
        .background(toolbarBG)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var editToolsRow: some View {
        HStack(spacing: 6) {
            toolButton("arrow.uturn.backward", help: "Undo") { viewModel.undo() }
            toolButton("arrow.uturn.forward", help: "Redo") { viewModel.redo() }

            toolbarDivider

            toolButton("trash", help: "Delete") { viewModel.deleteSelectedClip() }

            toggleToolButton(
                viewModel.razorModeActive ? "scissors.circle.fill" : "scissors",
                help: "Razor cut",
                isActive: viewModel.razorModeActive
            ) {
                viewModel.razorModeActive.toggle()
            }

            stubToolButton("waveform.slash", help: "Detach audio — Coming soon") {
                viewModel.detachAudio()
            }
            stubToolButton("text.bubble", help: "Text — Coming soon") { viewModel.addTextOverlay() }
            stubToolButton("crop", help: "Crop — Coming soon") { viewModel.cropClip() }
            stubToolButton("paintpalette", help: "Color — Coming soon") { viewModel.colorGrade() }
            stubToolButton("gyroscope", help: "Stabilise — Coming soon") { viewModel.stabilise() }

            Spacer()
        }
        .controlSize(.small)
        .padding(.horizontal, 8)
    }

    private var timelineControlsRow: some View {
        HStack(spacing: 8) {
            toggleToolButton(
                "arrow.left.and.right.righttriangle.left.righttriangle.right",
                help: "Magnetic snap",
                isActive: viewModel.magneticSnapEnabled
            ) {
                viewModel.magneticSnapEnabled.toggle()
            }

            toggleToolButton(
                "arrow.triangle.2.circlepath",
                help: "Auto ripple",
                isActive: viewModel.autoRippleEnabled
            ) {
                viewModel.autoRippleEnabled.toggle()
            }

            Spacer()

            Button { viewModel.timelineZoom = max(0.5, viewModel.timelineZoom - 0.25) } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 13))

            Slider(value: $viewModel.timelineZoom, in: 0.5...4.0)
                .frame(width: 120)

            Button { viewModel.timelineZoom = min(4.0, viewModel.timelineZoom + 0.25) } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 13))

            Button {} label: {
                Image(systemName: "square.grid.2x2")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 13))
            .help("Layout (coming soon)")
            .disabled(true)
            .opacity(0.4)
        }
        .padding(.horizontal, 8)
    }

    private var toolbarDivider: some View {
        Divider().frame(height: 16)
    }

    private func toolButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.borderless)
        .help(help)
    }

    private func toggleToolButton(
        _ symbol: String,
        help: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(isActive ? toggleYellow : Color.primary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.borderless)
        .help(help)
    }

    private func stubToolButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.borderless)
        .help(help)
        .opacity(0.85)
    }

    private func rulerRow(baseTrackWidth: CGFloat, effectiveTrackWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: EditorTimelineLayout.laneControlWidth, height: EditorTimelineLayout.timelineRulerHeight)
                .background(Color.white.opacity(0.04))

            TimelineRulerView(
                totalDuration: max(masterTimelineDuration, 0.1),
                trackWidth: baseTrackWidth,
                timelineZoom: viewModel.timelineZoom,
                playheadSeconds: masterPlayheadSeconds
            )
        }
        .frame(height: EditorTimelineLayout.timelineRulerHeight)
    }

    private var laneDivider: some View {
        Divider()
            .frame(height: EditorTimelineDesign.laneDividerThickness)
    }

    private func mainTrackRow(effectiveTrackWidth: CGFloat, laneIndex: Int) -> some View {
        laneRow(
            laneName: "Video 1",
            laneHeight: EditorTimelineLayout.mainTrackHeight,
            isPrimaryLane: laneIndex.isMultiple(of: 2),
            isLocked: $viewModel.videoLaneLocked,
            isMuted: $viewModel.videoLaneMuted,
            isVisible: $viewModel.videoLaneVisible,
            effectiveTrackWidth: effectiveTrackWidth
        ) {
            ZStack(alignment: .leading) {
                EditorTimelineView(
                    videoURL: videoURL,
                    duration: duration,
                    trimStart: trimStart,
                    trimEnd: trimEnd,
                    exportDurationSeconds: exportDurationSeconds,
                    removedRanges: removedRanges,
                    splitPoints: splitPoints,
                    segmentOrder: viewModel.project.timeline.segmentOrder,
                    selectionStart: selectionStart,
                    selectionEnd: selectionEnd,
                    currentTime: currentTime,
                    trackWidth: effectiveTrackWidth,
                    showsPlayhead: false,
                    scrubDuration: masterTimelineDuration,
                    clipLabel: videoClipLabel,
                    razorModeActive: viewModel.razorModeActive,
                    isLaneLocked: viewModel.videoLaneLocked,
                    isLaneVisible: viewModel.videoLaneVisible,
                    onTrimStartChange: onTrimStartChange,
                    onTrimEndChange: onTrimEndChange,
                    onSelectionStartChange: onSelectionStartChange,
                    onSelectionEndChange: onSelectionEndChange,
                    onSeek: onSeek,
                    onRazorCut: { viewModel.splitAtPoint($0) },
                    onTrimSegmentOut: { viewModel.trimVideoSegmentOut(segmentID: $0, newEffectiveEnd: $1) },
                    onTrimSegmentIn: { viewModel.trimVideoSegmentIn(segmentID: $0, newEffectiveStart: $1) },
                    onExtendSegmentOut: { viewModel.extendVideoSegmentOut(segmentID: $0, newEffectiveEnd: $1) },
                    onExtendSegmentIn: { viewModel.extendVideoSegmentIn(segmentID: $0, newEffectiveStart: $1) },
                    onRippleCloseGap: { viewModel.rippleCloseVideoGap(leftSegmentID: $0, rightSegmentID: $1, joinAt: $2) },
                    onMoveSplitPoint: { viewModel.moveVideoSplitBoundary(splitIndex: $0, to: $1) },
                    onReorderSegment: { viewModel.reorderSegment(from: $0, to: $1) }
                )

                if hasAudioTimelineExtension, masterTimelineDuration > 0 {
                    let videoWidth = CGFloat(videoExportDuration / masterTimelineDuration) * effectiveTrackWidth
                    let extensionWidth = max(0, effectiveTrackWidth - videoWidth)
                    Color.white.opacity(0.04)
                        .frame(width: extensionWidth, height: EditorTimelineLayout.mainTrackHeight)
                        .offset(x: videoWidth)
                        .allowsHitTesting(false)
                }
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    if !viewModel.razorModeActive {
                        onSelectTimeline()
                    }
                }
            )
        }
    }

    private func playheadLine(pixelsPerSecond: CGFloat, totalHeight: CGFloat) -> some View {
        let x = CGFloat(masterPlayheadSeconds) * pixelsPerSecond
        return Rectangle()
            .fill(Color(red: 0.95, green: 0.2, blue: 0.2))
            .frame(width: 1.5, height: totalHeight)
            .offset(x: EditorTimelineLayout.laneControlWidth + x)
            .allowsHitTesting(false)
    }

    private func playheadHandle(pixelsPerSecond: CGFloat, rulerDuration: Double) -> some View {
        let x = CGFloat(masterPlayheadSeconds) * pixelsPerSecond
        return Circle()
            .fill(Color(red: 0.95, green: 0.3, blue: 0.3))
            .frame(width: 18, height: 18)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
            .offset(x: EditorTimelineLayout.laneControlWidth + x - 9, y: -4)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("timeline"))
                    .onChanged { value in
                        let time = Double(value.location.x / max(pixelsPerSecond, 0.001))
                            .clamped(to: 0...max(rulerDuration, 0.001))
                        onSeek(time)
                    }
            )
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }

    @ViewBuilder
    private func overlayLanes(effectiveTrackWidth: CGFloat, startingLaneIndex: Int) -> some View {
        if imageClips.isEmpty {
            laneRow(
                laneName: "Overlay",
                laneHeight: EditorTimelineLayout.clipLaneHeight,
                isPrimaryLane: startingLaneIndex.isMultiple(of: 2),
                isLocked: $viewModel.overlayLaneLocked,
                isMuted: .constant(false),
                isVisible: $viewModel.overlayLaneVisible,
                effectiveTrackWidth: effectiveTrackWidth
            ) {
                emptyLane(trackWidth: effectiveTrackWidth, kind: .overlay)
            }
        } else {
            ForEach(Array(imageClips.enumerated()), id: \.element.id) { index, clip in
                Group {
                    if index > 0 { laneDivider }
                    laneRow(
                        laneName: index == 0 ? "Overlay" : "Overlay \(index + 1)",
                        laneHeight: EditorTimelineLayout.clipLaneHeight,
                        isPrimaryLane: (startingLaneIndex + index).isMultiple(of: 2),
                        isLocked: $viewModel.overlayLaneLocked,
                        isMuted: .constant(false),
                        isVisible: $viewModel.overlayLaneVisible,
                        effectiveTrackWidth: effectiveTrackWidth
                    ) {
                        imageClipView(clip: clip, trackWidth: effectiveTrackWidth)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func audioLanes(effectiveTrackWidth: CGFloat, startingLaneIndex: Int) -> some View {
        if audioClips.isEmpty {
            laneRow(
                laneName: "Audio 1",
                laneHeight: EditorTimelineLayout.audioLaneHeight,
                isPrimaryLane: startingLaneIndex.isMultiple(of: 2),
                isLocked: $viewModel.audioLaneLocked,
                isMuted: .constant(false),
                isVisible: .constant(true),
                effectiveTrackWidth: effectiveTrackWidth
            ) {
                emptyLane(trackWidth: effectiveTrackWidth, kind: .audio)
            }
        } else {
            ForEach(Array(audioClips.enumerated()), id: \.element.id) { index, clip in
                Group {
                    if index > 0 { laneDivider }
                    laneRow(
                        laneName: "Audio \(index + 1)",
                        laneHeight: EditorTimelineLayout.audioLaneHeight,
                        isPrimaryLane: (startingLaneIndex + index).isMultiple(of: 2),
                        isLocked: $viewModel.audioLaneLocked,
                        isMuted: audioMuteBinding(for: clip.id),
                        isVisible: .constant(true),
                        effectiveTrackWidth: effectiveTrackWidth
                    ) {
                        audioClipView(clip: clip, trackWidth: effectiveTrackWidth)
                    }
                }
            }
        }
    }

    private func audioMuteBinding(for trackID: UUID) -> Binding<Bool> {
        Binding(
            get: { viewModel.mutedAudioTrackIDs.contains(trackID) },
            set: { isMuted in
                if isMuted {
                    viewModel.mutedAudioTrackIDs.insert(trackID)
                } else {
                    viewModel.mutedAudioTrackIDs.remove(trackID)
                }
                viewModel.refreshAudioPreview()
            }
        )
    }

    private func imageClipView(clip: EditorImageClipLaneItem, trackWidth: CGFloat) -> some View {
        EditorTimelineClipView(
            startTime: clip.start,
            endTime: clip.end,
            totalDuration: duration,
            trackWidth: trackWidth,
            minClipDuration: minClipDuration,
            label: clip.label,
            kind: .overlay,
            isSelected: clip.isSelected,
            isActiveAtPlayhead: currentTime >= clip.start && currentTime <= clip.end,
            isLocked: viewModel.overlayLaneLocked,
            isHidden: !viewModel.overlayLaneVisible,
            onStartChange: { onImageStartChange(clip.id, $0) },
            onEndChange: { onImageEndChange(clip.id, $0) },
            onMoveStart: { onImageClipMove(clip.id, $0) },
            onSelect: { onSelectOverlay(clip.id) }
        )
    }

    private func audioClipView(clip: EditorAudioClipLaneItem, trackWidth: CGFloat) -> some View {
        let exportPlayhead = masterPlayheadSeconds
        return EditorTimelineClipView(
            startTime: clip.start,
            endTime: clip.end,
            totalDuration: masterTimelineDuration,
            trackWidth: trackWidth,
            minClipDuration: minClipDuration,
            label: clip.label,
            kind: .audio,
            isSelected: clip.isSelected,
            isActiveAtPlayhead: exportPlayhead >= clip.start && exportPlayhead <= clip.end,
            isLocked: viewModel.audioLaneLocked,
            audioFileURL: clip.fileURL,
            onStartChange: { onAudioStartChange(clip.id, $0) },
            onEndChange: { onAudioEndChange(clip.id, $0) },
            onMoveStart: { onAudioClipMove(clip.id, $0) },
            onSelect: { onSelectAudio(clip.id) }
        )
    }

    private func laneRow<Content: View>(
        laneName: String,
        laneHeight: CGFloat,
        isPrimaryLane: Bool,
        isLocked: Binding<Bool>,
        isMuted: Binding<Bool>,
        isVisible: Binding<Bool>,
        effectiveTrackWidth: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 0) {
            LaneControlBar(
                laneName: laneName,
                laneHeight: laneHeight,
                isLocked: isLocked,
                isMuted: isMuted,
                isVisible: isVisible
            )
            .clipped()

            content()
                .frame(width: effectiveTrackWidth, height: laneHeight, alignment: .leading)
                .background(isPrimaryLane ? EditorTimelineDesign.laneRowPrimaryBG : EditorTimelineDesign.laneRowSecondaryBG)
        }
        .frame(height: laneHeight)
    }

    private enum EmptyLaneKind {
        case overlay
        case audio
    }

    private func emptyLane(trackWidth: CGFloat, kind: EmptyLaneKind) -> some View {
        Button {
            switch kind {
            case .overlay: onImportImage()
            case .audio: onImportAudio()
            }
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    Color.white.opacity(0.18),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                )
                .frame(width: trackWidth, height: kind == .audio ? EditorTimelineLayout.audioLaneHeight : EditorTimelineLayout.clipLaneHeight)
                .overlay {
                    Image(systemName: "plus")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.secondary)
                }
        }
        .buttonStyle(.plain)
        .help(kind == .overlay ? "Import an image overlay" : "Import background music or audio")
    }
}
