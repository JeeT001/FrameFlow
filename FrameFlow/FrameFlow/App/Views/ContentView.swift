//
//  ContentView.swift
//  FrameFlow
//
//  Created by Simranjit Singh Babbar on 25/05/2026.
//

import SwiftUI

/// Legacy entry retained for previews; the app launches via `MainAppView`.
struct ContentView: View {
    var body: some View {
        MainAppView()
            .environment(AppRouter())
    }
}

#Preview {
    ContentView()
}
