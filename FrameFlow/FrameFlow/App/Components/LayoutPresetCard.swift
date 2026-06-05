//
//  LayoutPresetCard.swift
//  FrameFlow
//

import SwiftUI

struct LayoutPresetCard: View {
    let preset: LayoutPreset
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                LayoutPresetDiagram(preset: preset)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)

                Text(preset.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColors.primary : AppColors.border,
                        lineWidth: isSelected ? 2.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

struct LayoutPresetDiagram: View {
    let preset: LayoutPreset

    private let fill = AppColors.primary.opacity(0.35)
    private let stroke = AppColors.primary.opacity(0.6)

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            switch preset {
            case .stacked:
                stackedDiagram(in: size)
            case .sideBySide:
                sideBySideDiagram(in: size)
            case .pipBottomRight:
                pipBottomRightDiagram(in: size)
            case .pipFaceTop:
                pipFaceTopDiagram(in: size)
            case .freeForm:
                freeFormDiagram(in: size)
            }
        }
    }

    private func stackedDiagram(in size: CGSize) -> some View {
        VStack(spacing: 4) {
            rect(width: size.width * 0.85, height: size.height * 0.42)
            rect(width: size.width * 0.85, height: size.height * 0.42)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sideBySideDiagram(in size: CGSize) -> some View {
        HStack(spacing: 4) {
            rect(width: size.width * 0.4, height: size.height * 0.75)
            rect(width: size.width * 0.4, height: size.height * 0.75)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pipBottomRightDiagram(in size: CGSize) -> some View {
        ZStack(alignment: .bottomTrailing) {
            rect(width: size.width * 0.9, height: size.height * 0.85)
            rect(width: size.width * 0.32, height: size.height * 0.28)
                .offset(x: -4, y: -4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func freeFormDiagram(in size: CGSize) -> some View {
        ZStack {
            rect(width: size.width * 0.55, height: size.height * 0.38)
                .offset(x: -size.width * 0.12, y: size.height * 0.1)
            rect(width: size.width * 0.42, height: size.height * 0.3)
                .offset(x: size.width * 0.14, y: -size.height * 0.12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pipFaceTopDiagram(in size: CGSize) -> some View {
        ZStack(alignment: .top) {
            rect(width: size.width * 0.9, height: size.height * 0.55)
                .offset(y: size.height * 0.22)
            rect(width: size.width * 0.35, height: size.height * 0.32)
                .offset(y: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func rect(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1)
            }
            .frame(width: width, height: height)
    }
}

#Preview {
    HStack {
        LayoutPresetCard(preset: .stacked, isSelected: true, onSelect: {})
        LayoutPresetCard(preset: .pipBottomRight, isSelected: false, onSelect: {})
    }
    .padding()
    .frame(width: 320)
}
