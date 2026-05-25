//
//  SidebarView.swift
//  FrameFlow
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection

    var body: some View {
        List(SidebarSection.allCases, selection: $selection) { section in
            Label(section.title, systemImage: section.systemImage)
                .tag(section)
        }
        .listStyle(.sidebar)
        .navigationTitle("FrameFlow")
    }
}

#Preview {
    SidebarView(selection: .constant(.home))
        .frame(width: 220, height: 400)
}
