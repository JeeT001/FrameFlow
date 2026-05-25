//
//  Components.swift
//  FrameFlow
//

import SwiftUI

struct ScreenPlaceholder: View {
    let route: AppRoute

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: route.systemImage)
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)

                    Text(route.title)
                        .font(.largeTitle)
                        .fontWeight(.semibold)

                    Text(route.subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 480)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Planned UI")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ForEach(route.plannedElements, id: \.self) { element in
                        Button(element) {}
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .disabled(true)
                    }
                }
                .frame(maxWidth: 360)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
        }
        .navigationTitle(route.title)
    }
}

#Preview {
    ScreenPlaceholder(route: .dashboard)
}
