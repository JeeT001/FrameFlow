//
//  SidebarView.swift
//  FrameFlow
//

import SwiftUI

struct SidebarView: View {
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
        }
        .navigationTitle("")
    }
}

#Preview {
    SidebarView(selection: .constant(.home))
        .frame(width: 220, height: 400)
}
