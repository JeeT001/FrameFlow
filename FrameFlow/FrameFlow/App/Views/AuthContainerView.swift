//
//  AuthContainerView.swift
//  FrameFlow
//

import SwiftUI

struct AuthContainerView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        RouteDetailView(route: displayedRoute)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var displayedRoute: AppRoute {
        switch router.currentRoute {
        case .signUp, .forgotPassword, .resetPassword:
            router.currentRoute
        default:
            .login
        }
    }
}

#Preview {
    AuthContainerView()
        .environment(AppRouter())
}
