//
//  AuthScreenChrome.swift
//  FrameFlow
//

import AppKit
import SwiftUI

enum AuthHero {
    case brandWordmark
    case appIcon
    case systemImage(String, dashedCircle: Bool = true)
}

struct AuthScreenChrome<Content: View, Footer: View>: View {
    let hero: AuthHero
    let title: String
    let subtitle: String
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    init(
        hero: AuthHero = .brandWordmark,
        title: String,
        subtitle: String,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.hero = hero
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.footer = footer
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 48)

                VStack(spacing: 24) {
                    heroView

                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text(title)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppColors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            content()
                        }
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(AppColors.border.opacity(0.7))
                    }
                    .shadow(color: .black.opacity(0.04), radius: 12, y: 4)

                    footer()
                        .padding(.top, 4)
                }
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 48)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    @ViewBuilder
    private var heroView: some View {
        switch hero {
        case .brandWordmark:
            BrandLogoView(style: .authHero)
        case .appIcon:
            AuthAppIconView()
        case .systemImage(let name, let dashedCircle):
            if dashedCircle {
                ZStack {
                    Circle()
                        .strokeBorder(
                            AppColors.primary.opacity(0.35),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 5])
                        )
                        .frame(width: 72, height: 72)

                    Image(systemName: name)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(AppColors.primary)
                }
            } else {
                Image(systemName: name)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(AppColors.primary)
            }
        }
    }
}

private struct AuthAppIconView: View {
    var body: some View {
        Group {
            if let icon = NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "record.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}
