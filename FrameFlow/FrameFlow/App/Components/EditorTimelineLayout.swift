//
//  EditorTimelineLayout.swift
//  FrameFlow
//

import SwiftUI

/// Shared column geometry for main track, overlay, and audio lanes.
enum EditorTimelineLayout {
    static let laneControlWidth: CGFloat = 0
    static let laneLabelWidth: CGFloat = 0
    static let rowSpacing: CGFloat = 0
    static let mainTrackHeight: CGFloat = EditorTimelineDesign.videoLaneHeight
    static let clipLaneHeight: CGFloat = EditorTimelineDesign.overlayLaneHeight
    static let audioLaneHeight: CGFloat = EditorTimelineDesign.audioLaneHeight
    static let playheadWidth: CGFloat = EditorTimelineDesign.playheadWidth
    static let trimHandleWidth: CGFloat = EditorTimelineDesign.trimHandleWidth
    static let trimHandleHeight: CGFloat = EditorTimelineDesign.videoLaneHeight
    static let clipTrimHandleWidth: CGFloat = EditorTimelineDesign.overlayAudioHandleWidth
    static let clipTrimHandleHitWidth: CGFloat = 18
    static let timelineRulerHeight: CGFloat = EditorTimelineDesign.timelineRulerHeight
    static let toolbarHeight: CGFloat = EditorTimelineDesign.toolbarHeight
    static let tracksOuterPadding: CGFloat = EditorTimelineDesign.tracksOuterPadding

    static func trackContentWidth(totalWidth: CGFloat) -> CGFloat {
        max(totalWidth - laneControlWidth, 1)
    }

    static func effectiveTrackWidth(baseWidth: CGFloat, zoom: Double) -> CGFloat {
        max(baseWidth * CGFloat(zoom), 1)
    }

    static func timelineStackHeight(imageLaneCount: Int, audioLaneCount: Int) -> CGFloat {
        let imageRows = max(1, imageLaneCount)
        let audioRows = max(1, audioLaneCount)
        let dividerCount = 3 + max(0, imageRows - 1) + max(0, audioRows - 1)
        let dividers = CGFloat(dividerCount) * EditorTimelineDesign.laneDividerThickness
        return timelineRulerHeight
            + mainTrackHeight
            + CGFloat(imageRows) * clipLaneHeight
            + CGFloat(audioRows) * audioLaneHeight
            + dividers
    }

    static func unifiedPlayheadHeight(imageLaneCount: Int, audioLaneCount: Int) -> CGFloat {
        timelineStackHeight(imageLaneCount: imageLaneCount, audioLaneCount: audioLaneCount)
    }

    static var mvpTimelineStackHeight: CGFloat {
        timelineRulerHeight
            + EditorTimelineDesign.laneDividerThickness
            + mainTrackHeight
    }

    static var mvpTracksPanelHeight: CGFloat {
        tracksOuterPadding * 2 + toolbarHeight + mvpTimelineStackHeight
    }

    static func tracksPanelTotalHeight(imageLaneCount: Int, audioLaneCount: Int) -> CGFloat {
        mvpTracksPanelHeight
    }

    static func audioLaneYOffset(imageLaneCount: Int) -> CGFloat {
        let imageRows = max(1, imageLaneCount)
        let imageBlock = CGFloat(imageRows) * clipLaneHeight
        return timelineRulerHeight
            + EditorTimelineDesign.laneDividerThickness
            + mainTrackHeight
            + EditorTimelineDesign.laneDividerThickness
            + imageBlock
            + EditorTimelineDesign.laneDividerThickness
    }
}
