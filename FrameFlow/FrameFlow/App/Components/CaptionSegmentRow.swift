//
//  CaptionSegmentRow.swift
//  FrameFlow
//

import SwiftUI

struct CaptionSegmentRow: View {
    let segment: CaptionSegment
    let isSelected: Bool
    let allowsTimeEditing: Bool
    let onTextChange: (String) -> Void
    let onStartTimeChange: ((Double) -> Void)?
    let onEndTimeChange: ((Double) -> Void)?
    let onSelect: () -> Void

    @State private var draftText: String
    @State private var draftStartTime: String
    @State private var draftEndTime: String

    init(
        segment: CaptionSegment,
        isSelected: Bool,
        allowsTimeEditing: Bool = false,
        onTextChange: @escaping (String) -> Void,
        onStartTimeChange: ((Double) -> Void)? = nil,
        onEndTimeChange: ((Double) -> Void)? = nil,
        onSelect: @escaping () -> Void
    ) {
        self.segment = segment
        self.isSelected = isSelected
        self.allowsTimeEditing = allowsTimeEditing
        self.onTextChange = onTextChange
        self.onStartTimeChange = onStartTimeChange
        self.onEndTimeChange = onEndTimeChange
        self.onSelect = onSelect
        _draftText = State(initialValue: segment.text)
        _draftStartTime = State(initialValue: CaptionSegmentRow.formatEditableTime(segment.startTime))
        _draftEndTime = State(initialValue: CaptionSegmentRow.formatEditableTime(segment.endTime))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if allowsTimeEditing {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Start", text: $draftStartTime)
                        .font(.caption.monospacedDigit())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 64)
                        .onSubmit { commitStartTime() }
                        .onChange(of: draftStartTime) { _, _ in commitStartTime() }

                    TextField("End", text: $draftEndTime)
                        .font(.caption2.monospacedDigit())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 64)
                        .onSubmit { commitEndTime() }
                        .onChange(of: draftEndTime) { _, _ in commitEndTime() }
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(CaptionSegmentRow.formatTime(segment.startTime))
                        .font(.caption.monospacedDigit())
                    Text(CaptionSegmentRow.formatTime(segment.endTime))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(width: 44, alignment: .leading)
            }

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
        .onChange(of: segment.startTime) { _, newValue in
            let formatted = CaptionSegmentRow.formatEditableTime(newValue)
            if draftStartTime != formatted {
                draftStartTime = formatted
            }
        }
        .onChange(of: segment.endTime) { _, newValue in
            let formatted = CaptionSegmentRow.formatEditableTime(newValue)
            if draftEndTime != formatted {
                draftEndTime = formatted
            }
        }
    }

    private func commitStartTime() {
        guard allowsTimeEditing,
              let parsed = CaptionSegmentRow.parseTime(draftStartTime) else {
            draftStartTime = CaptionSegmentRow.formatEditableTime(segment.startTime)
            return
        }
        onStartTimeChange?(parsed)
    }

    private func commitEndTime() {
        guard allowsTimeEditing,
              let parsed = CaptionSegmentRow.parseTime(draftEndTime) else {
            draftEndTime = CaptionSegmentRow.formatEditableTime(segment.endTime)
            return
        }
        onEndTimeChange?(parsed)
    }

    static func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    static func formatEditableTime(_ seconds: Double) -> String {
        let clamped = max(0, seconds)
        let minutes = Int(clamped) / 60
        let secs = clamped.truncatingRemainder(dividingBy: 60)
        if minutes > 0 {
            return String(format: "%d:%04.1f", minutes, secs)
        }
        return String(format: "%.1f", secs)
    }

    static func parseTime(_ string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                  let minutes = Double(parts[0]),
                  let seconds = Double(parts[1]) else {
                return nil
            }
            return minutes * 60 + seconds
        }

        return Double(trimmed)
    }
}
