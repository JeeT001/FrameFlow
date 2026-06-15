//
//  LegalDocumentView.swift
//  FrameFlow
//

import AppKit
import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        LegalDocumentView(document: LegalDocumentContent.privacyPolicy)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        LegalDocumentView(document: LegalDocumentContent.termsOfService)
    }
}

struct LegalDocumentView: View {
    @Environment(AppRouter.self) private var router

    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                ForEach(document.sections) { section in
                    sectionBlock(section)
                }

                draftFooter

                if let webURL = LegalConstants.webURL(for: document) {
                    websiteLink(webURL)
                }
            }
            .padding(28)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    router.navigateBackFromLegal()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(document.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Last updated: \(document.lastUpdated)")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionBlock(_ section: LegalSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text(LocalizedStringKey(section.body))
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var draftFooter: some View {
        Text(document.draftDisclaimer)
            .font(.caption)
            .foregroundStyle(AppColors.textSecondary)
            .italic()
            .padding(.top, 8)
    }

    private func websiteLink(_ url: URL) -> some View {
        Button("View on website") {
            NSWorkspace.shared.open(url)
        }
        .buttonStyle(.plain)
        .font(.callout)
        .foregroundStyle(AppColors.primary)
        .padding(.top, 4)
    }
}

#Preview("Privacy") {
    LegalDocumentView(document: LegalDocumentContent.privacyPolicy)
        .environment(AppRouter())
        .frame(width: 900, height: 720)
}

#Preview("Terms") {
    LegalDocumentView(document: LegalDocumentContent.termsOfService)
        .environment(AppRouter())
        .frame(width: 900, height: 720)
}
