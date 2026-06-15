//
//  WindowPickerFooterBar.swift
//  FrameFlow
//

import SwiftUI

struct WindowPickerFooterBar: View {
    let selectedCount: Int
    let selectionLimit: Int
    let canProceed: Bool
    let isLoading: Bool
    let onNext: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(selectedCount > 0 ? AppColors.primary : AppColors.textSecondary.opacity(0.5))

                Text("\(selectedCount) selected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            Text("You can select up to \(selectionLimit) windows")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)

            Button("Refresh") {
                onRefresh()
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)

            Button {
                onNext()
            } label: {
                HStack(spacing: 6) {
                    Text("Next")
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.semibold))
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canProceed || isLoading)
            .help(canProceed ? "Continue to layout picker" : "Select at least one window to continue")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(AppColors.background)
    }
}
