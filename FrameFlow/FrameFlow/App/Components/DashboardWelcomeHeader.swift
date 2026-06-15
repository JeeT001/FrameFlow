//
//  DashboardWelcomeHeader.swift
//  FrameFlow
//

import SwiftUI

struct DashboardWelcomeHeader: View {
    let displayName: String
    let initials: String
    let showsUpgrade: Bool
    @Binding var searchText: String
    let onUpgrade: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back, \(displayName)!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Ready to create your next amazing video?")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 12)

            searchField
                .frame(maxWidth: 280)

            userAvatar

            if showsUpgrade {
                Button("Upgrade") {
                    onUpgrade()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textSecondary)
            TextField("Search recordings…", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppColors.border)
        }
    }

    private var userAvatar: some View {
        Circle()
            .fill(AppColors.primary.opacity(0.18))
            .frame(width: 40, height: 40)
            .overlay {
                Text(initials)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.primary)
            }
            .help(displayName)
    }
}
