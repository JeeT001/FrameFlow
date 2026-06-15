//
//  RecordingSessionChip.swift
//  FrameFlow
//

import SwiftUI

struct RecordingSessionChip<Trailing: View>: View {
    let icon: String
    let title: String
    var isOn: Bool?
    @ViewBuilder var trailing: () -> Trailing

    init(
        icon: String,
        title: String,
        isOn: Bool? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.isOn = isOn
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            if let isOn {
                Text(isOn ? "ON" : "OFF")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isOn ? AppColors.successGreen : AppColors.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        (isOn ? AppColors.successGreen : AppColors.textSecondary).opacity(0.15),
                        in: Capsule()
                    )
            }

            trailing()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.background.opacity(0.95), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppColors.border.opacity(0.8))
        }
    }
}

extension RecordingSessionChip where Trailing == EmptyView {
    init(icon: String, title: String, isOn: Bool? = nil) {
        self.init(icon: icon, title: title, isOn: isOn, trailing: { EmptyView() })
    }
}
