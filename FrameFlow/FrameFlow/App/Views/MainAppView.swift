//
//  MainAppView.swift
//  FrameFlow
//

import SwiftUI

struct MainAppView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        NavigationSplitView {
            SidebarView(
                selection: Binding(
                    get: { router.selectedSection },
                    set: { router.selectSidebar($0) }
                )
            )
        } detail: {
            RouteDetailView(route: router.currentRoute)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        RoutePickerMenu(selection: $router.currentRoute)
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
    }
}

private struct RoutePickerMenu: View {
    @Binding var selection: AppRoute

    var body: some View {
        Picker("Screen", selection: $selection) {
            ForEach(AppRoute.allCases) { route in
                Text(route.title).tag(route)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
}

#Preview {
    MainAppView()
        .environment(AppRouter())
}
