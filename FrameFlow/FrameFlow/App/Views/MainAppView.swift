//
//  MainAppView.swift
//  FrameFlow
//

import SwiftUI

struct MainAppView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
    @State private var splitVisibility: NavigationSplitViewVisibility = .all
    @State private var showSubscriptionSuccessAlert = false
    @State private var subscriptionSuccessMessage = ""

    var body: some View {
        @Bindable var router = router

        NavigationSplitView(columnVisibility: $splitVisibility) {
            SidebarView(
                selection: Binding(
                    get: { router.selectedSection },
                    set: { router.selectSidebar($0) }
                )
            )
        } detail: {
            RouteDetailView(route: router.currentRoute)
                #if DEBUG
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        RoutePickerMenu(selection: $router.currentRoute)
                    }
                }
                #endif
        }
        .navigationSplitViewStyle(.balanced)
        .background(AppColors.background)
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: router.currentRoute) { _, route in
            splitVisibility = route.isEditorFocused ? .detailOnly : .all
        }
        .onAppear {
            splitVisibility = router.currentRoute.isEditorFocused ? .detailOnly : .all
            presentSubscriptionSuccessMessageIfNeeded()
        }
        .onChange(of: appState.pendingSubscriptionSuccessMessage) { _, _ in
            presentSubscriptionSuccessMessageIfNeeded()
        }
        .alert("Subscription", isPresented: $showSubscriptionSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(subscriptionSuccessMessage)
        }
    }

    private func presentSubscriptionSuccessMessageIfNeeded() {
        guard let message = appState.consumePendingSubscriptionSuccessMessage() else { return }
        subscriptionSuccessMessage = message
        showSubscriptionSuccessAlert = true
    }
}

#if DEBUG
private struct RoutePickerMenu: View {
    @Binding var selection: AppRoute

    var body: some View {
        Picker("Screen", selection: $selection) {
            ForEach(AppRoute.allCases.filter(\.showInRoutePicker)) { route in
                Text(route.title).tag(route)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
}
#endif

#Preview {
    MainAppView()
        .environment(AppRouter())
}
