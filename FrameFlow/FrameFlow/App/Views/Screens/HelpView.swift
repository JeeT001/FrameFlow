//
//  HelpView.swift
//  FrameFlow
//

import AppKit
import SwiftUI

struct HelpView: View {
    @Environment(AppRouter.self) private var router

    private static let supportEmail = "kiwibooking.nz@gmail.com"

    @State private var searchText = ""

    private var allFAQItems: [HelpFAQItem] {
        HelpFAQItem.allItems(
            saveFolder: SettingsStore.shared.expandedSaveFolder,
            supportEmail: Self.supportEmail
        )
    }

    private var filteredSections: [(category: HelpFAQCategory, items: [HelpFAQItem])] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return HelpFAQCategory.visibleCases.compactMap { category in
            let items = allFAQItems.filter { item in
                item.category == category
                    && (query.isEmpty || item.searchableText.lowercased().contains(query))
            }
            guard !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    private var hasSearchQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HelpPageHeader(
                    title: "Help & Support",
                    subtitle: "Answers about permissions, recording, exports, captions, and shortcuts."
                )

                HelpSearchField(searchText: $searchText)

                if filteredSections.isEmpty, hasSearchQuery {
                    ContentUnavailableView(
                        "No results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    ForEach(filteredSections, id: \.category.id) { section in
                        HelpFAQSection(title: section.category.rawValue, icon: section.category.icon) {
                            ForEach(section.items) { item in
                                HelpFAQRow(item: item)
                            }
                        }
                    }
                }

                HelpSupportCard(
                    onEmailSupport: openEmailSupport,
                    version: appVersionString,
                    onPrivacy: openPrivacyPolicy,
                    onTerms: openTermsOfService
                )
            }
            .padding(28)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .navigationTitle("")
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func openEmailSupport() {
        let encoded = Self.supportEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? Self.supportEmail
        guard let url = URL(string: "mailto:\(encoded)?subject=\(AppBranding.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? AppBranding.name)%20Support") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func openPrivacyPolicy() {
        router.navigateToLegal(.privacyPolicy, returningTo: .help)
    }

    private func openTermsOfService() {
        router.navigateToLegal(.termsOfService, returningTo: .help)
    }
}

#Preview {
    HelpView()
        .environment(AppRouter())
        .frame(width: 900, height: 720)
}
