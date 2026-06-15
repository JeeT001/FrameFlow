//
//  AuthPrimaryButton.swift
//  FrameFlow
//

import SwiftUI

struct AuthPrimaryButton: View {
    let title: String
    let isLoading: Bool
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(
            AppColors.primary.opacity(isDisabled ? 0.45 : 1),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .disabled(isDisabled || isLoading)
    }
}
