//
//  EditorTracksView.swift
//  FrameFlow
//

import SwiftUI

struct EditorTracksView: View {
    @Bindable var viewModel: EditorViewModel

    let duration: Double
    let trimStart: Double
    let trimEnd: Double
    let splitPoints: [Double]
    let currentTime: Double
    let onTrimStartChange: (Double) -> Void
    let onTrimEndChange: (Double) -> Void
    let onSeek: (Double) -> Void
    let onRazorCut: (Double) -> Void
    let onMoveSplitPoint: (Int, Double) -> Void
    let onClearSplits: () -> Void

    private let toggleYellow = EditorTimelineDesign.trimHandleYellow
    private let toolbarBG = Color(red: 0.14, green: 0.14, blue: 0.14)

    private var stackHeight: CGFloat {
        EditorTimelineLayout.mvpTimelineStackHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            timelineToolbar
                .padding(.horizontal, EditorTimelineLayout.tracksOuterPadding)

            GeometryReader { geometry in
                let trackWidth = max(geometry.size.width - EditorTimelineLayout.tracksOuterPadding * 2, 1)

                VStack(spacing: 0) {
                    EditorTimelineRulerView(
                        duration: duration,
                        trackWidth: trackWidth,
                        labelColumnWidth: 0
                    )

                    Divider()
                        .frame(height: EditorTimelineDesign.laneDividerThickness)

                    EditorTimelineView(
                        duration: duration,
                        trimStart: trimStart,
                        trimEnd: trimEnd,
                        splitPoints: splitPoints,
                        currentTime: currentTime,
                        trackWidth: trackWidth,
                        razorModeActive: viewModel.razorModeActive,
                        onTrimStartChange: onTrimStartChange,
                        onTrimEndChange: onTrimEndChange,
                        onSeek: onSeek,
                        onRazorCut: onRazorCut,
                        onMoveSplitPoint: onMoveSplitPoint
                    )
                    .frame(height: EditorTimelineLayout.mainTrackHeight)
                }
                .padding(.horizontal, EditorTimelineLayout.tracksOuterPadding)
            }
            .frame(height: stackHeight)
        }
        .padding(.vertical, EditorTimelineLayout.tracksOuterPadding)
        .background(EditorTimelineDesign.timelineBackground)
        .onKeyPress(.escape) {
            if viewModel.razorModeActive {
                viewModel.razorModeActive = false
                return .handled
            }
            return .ignored
        }
    }

    private var timelineToolbar: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.razorModeActive.toggle()
            } label: {
                Image(systemName: viewModel.razorModeActive ? "scissors.circle.fill" : "scissors")
                    .foregroundStyle(viewModel.razorModeActive ? toggleYellow : Color.primary)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help("Razor cut")

            if !splitPoints.isEmpty {
                Button("Clear splits") {
                    onClearSplits()
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }

            Spacer()

            EditorTimecodeChip(
                primary: TrimHelpers.formatTimelineTime(currentTime),
                secondary: TrimHelpers.formatTimelineTime(duration)
            )
        }
        .font(.system(size: 13))
        .padding(.horizontal, 8)
        .frame(height: EditorTimelineDesign.toolbarHeight)
        .background(toolbarBG)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
