//
//  SidebarView.swift
//  FrameFlow
//

import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Binding var selection: SidebarSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BrandLogoView(style: .sidebar)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            List(SidebarSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .listStyle(.sidebar)

            Spacer(minLength: 0)

            if !appState.isPro {
                proReminderCard
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 16)
            }
        }
        .navigationTitle("")
    }

    private var proReminderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)

                    Text("Drazlo Pro")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }

                Text("Unlock captions, 9:16 export, and no watermark.")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("See Pro") {
                router.navigate(to: .subscription)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SidebarView(selection: .constant(.home))
        .environment(AppState())
        .environment(AppRouter())
        .frame(width: 220, height: 400)
}
