//
//  EditorShellLayout.swift
//  FrameFlow
//

import SwiftUI

/// Editor 3.0 shell: preview | contextual inspector, with full-width tracks below.
struct EditorShellLayout<Preview: View, Inspector: View, Tracks: View>: View {
    let preview: Preview
    let inspector: Inspector
    let tracks: Tracks

    init(
        @ViewBuilder preview: () -> Preview,
        @ViewBuilder inspector: () -> Inspector,
        @ViewBuilder tracks: () -> Tracks
    ) {
        self.preview = preview()
        self.inspector = inspector()
        self.tracks = tracks()
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                HStack(alignment: .top, spacing: 0) {
                    preview
                        .frame(width: geometry.size.width * 0.58, height: geometry.size.height, alignment: .center)

                    Divider()

                    inspector
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }

            Divider()

            tracks
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
