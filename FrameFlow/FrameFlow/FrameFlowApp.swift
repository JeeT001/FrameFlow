//
//  FrameFlowApp.swift
//  FrameFlow
//
//  Created by Simranjit Singh Babbar on 25/05/2026.
//

import SwiftUI

@main
struct FrameFlowApp: App {
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environment(router)
        }
        .defaultSize(width: 1100, height: 700)
    }
}
