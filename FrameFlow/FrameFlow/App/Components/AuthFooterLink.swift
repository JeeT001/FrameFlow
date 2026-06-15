//
//  AuthFooterLink.swift
//  FrameFlow
//

import SwiftUI

struct AuthFooterLink: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.callout)
                }
                Text(title)
                    .font(.callout)
            }
            .foregroundStyle(AppColors.primary)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }
}
