//
//  RecordingListItemView.swift
//  FrameFlow
//

import SwiftUI

struct RecordingListItemView: View {
    let recording: RecordingMetadata
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
                    .aspectRatio(16 / 9, contentMode: .fit)

                Image(systemName: "play.rectangle")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recording.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(recording.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text(recording.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(recording.resolutionBadge)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.15))
        }
        .contextMenu {
            if let onDelete {
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
    }
}

#if DEBUG
#Preview {
    RecordingListItemView(
        recording: .mock(name: "Preview Recording"),
        onDelete: {}
    )
    .frame(width: 240)
    .padding()
}
#endif
