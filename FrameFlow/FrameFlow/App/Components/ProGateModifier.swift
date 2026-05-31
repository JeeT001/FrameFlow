//
//  ProGateModifier.swift
//  FrameFlow
//

import SwiftUI

enum ProGate {
    static func perform(
        isPro: Bool,
        feature: String,
        description: String,
        present: (String, String) -> Void,
        action: () -> Void
    ) {
        if isPro {
            action()
        } else {
            AnalyticsService.trackFeatureBlocked(feature: feature)
            present(feature, description)
        }
    }
}

struct ProUpgradeSheet: View {
    @Environment(AppRouter.self) private var router
    @Binding var isPresented: Bool

    let feature: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(feature)
                .font(.title2)
                .fontWeight(.semibold)

            Text(description)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Not Now", role: .cancel) {
                    isPresented = false
                }

                Spacer()

                Button("Upgrade") {
                    isPresented = false
                    AnalyticsService.trackUpgradeClicked(source: "pro_gate")
                    router.navigate(to: .subscription)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 360)
    }
}

extension View {
    func proUpgradeSheet(
        isPresented: Binding<Bool>,
        feature: String,
        description: String
    ) -> some View {
        sheet(isPresented: isPresented) {
            ProUpgradeSheet(
                isPresented: isPresented,
                feature: feature,
                description: description
            )
        }
    }
}
