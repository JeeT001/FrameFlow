//
//  ViewModels.swift
//  FrameFlow
//

import SwiftUI

@Observable
final class AppRouter {
    var selectedSection: SidebarSection = .home
    var currentRoute: AppRoute = .dashboard

    func selectSidebar(_ section: SidebarSection) {
        selectedSection = section
        currentRoute = AppRoute.route(for: section)
    }

    func navigate(to route: AppRoute) {
        currentRoute = route
    }
}
