//
//  AuthFormLayout.swift
//  FrameFlow
//

import SwiftUI

struct AuthFormLayout<Content: View, Footer: View>: View {
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
        AuthScreenChrome(
            hero: hero,
            title: title,
            subtitle: subtitle,
            content: content,
            footer: footer
        )
    }
}

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(AppColors.recRed)

            Text(message)
                .font(.callout)
                .foregroundStyle(AppColors.recRed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(AppColors.recRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppColors.recRed.opacity(0.2))
        }
    }
}

struct AuthSuccessBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.successGreen)

            Text(message)
                .font(.callout)
                .foregroundStyle(AppColors.successGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(AppColors.successGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppColors.successGreen.opacity(0.2))
        }
    }
}
