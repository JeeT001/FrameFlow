//
//  CaptionSegmentRow.swift
//  FrameFlow
//

import SwiftUI

struct CaptionSegmentRow: View {
    let segment: CaptionSegment
    let isSelected: Bool
    let onTextChange: (String) -> Void
    let onSelect: () -> Void

    @State private var draftText: String

    init(
        segment: CaptionSegment,
        isSelected: Bool,
        onTextChange: @escaping (String) -> Void,
        onSelect: @escaping () -> Void
    ) {
        self.segment = segment
        self.isSelected = isSelected
        self.onTextChange = onTextChange
        self.onSelect = onSelect
        _draftText = State(initialValue: segment.text)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(CaptionSegmentRow.formatTime(segment.startTime))
                    .font(.caption.monospacedDigit())
                Text(CaptionSegmentRow.formatTime(segment.endTime))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(width: 44, alignment: .leading)

            TextField("Caption text", text: $draftText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
                .onChange(of: draftText) { _, newValue in
                    onTextChange(newValue)
                }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? AppColors.primary.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? AppColors.primary.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onChange(of: segment.text) { _, newValue in
            if draftText != newValue {
                draftText = newValue
            }
        }
    }

    static func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
