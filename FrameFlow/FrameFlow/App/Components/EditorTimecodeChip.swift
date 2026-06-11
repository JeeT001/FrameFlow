//
//  EditorTimecodeChip.swift
//  FrameFlow
//

import SwiftUI

struct EditorTimecodeChip: View {
    let primary: String
    var secondary: String?
    var accent: String?

    var body: some View {
        HStack(spacing: 6) {
            Text(primary)
                .font(.system(.caption, design: .monospaced).weight(.medium))

            if let secondary {
                Text("·")
                    .foregroundStyle(.secondary)
                Text(secondary)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if let accent {
                Text(accent)
                    .font(.system(.caption2, design: .monospaced).weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.35), in: Capsule())
    }
}
