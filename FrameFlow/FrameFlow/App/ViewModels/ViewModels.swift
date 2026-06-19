//
//  ViewModels.swift
//  FrameFlow
//

import SwiftUI

@Observable
final class AppRouter {
    var selectedSection: SidebarSection = .home
    var currentRoute: AppRoute = .dashboard
    var legalReturnRoute: AppRoute?

    func selectSidebar(_ section: SidebarSection) {
        selectedSection = section
        currentRoute = AppRoute.route(for: section)
    }

    func navigate(to route: AppRoute) {
        currentRoute = route
        if route == .help {
            selectedSection = .help
        }
    }

    func navigateToLegal(_ legalRoute: AppRoute, returningTo returnRoute: AppRoute) {
        legalReturnRoute = returnRoute
        currentRoute = legalRoute
    }

    func navigateBackFromLegal() {
        currentRoute = legalReturnRoute ?? .help
        legalReturnRoute = nil
    }
}
