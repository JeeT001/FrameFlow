//
//  EditorShellLayout.swift
//  FrameFlow
//

import SwiftUI

/// Post-record editor shell: preview (left) + sidebar (right).
struct EditorShellLayout<Preview: View, Sidebar: View>: View {
    let preview: Preview
    let sidebar: Sidebar

    init(
        @ViewBuilder preview: () -> Preview,
        @ViewBuilder sidebar: () -> Sidebar
    ) {
        self.preview = preview()
        self.sidebar = sidebar()
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                preview
                    .frame(width: geometry.size.width * 0.58, height: geometry.size.height, alignment: .center)

                Divider()

                sidebar
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .background(AppColors.background)
    }
}
