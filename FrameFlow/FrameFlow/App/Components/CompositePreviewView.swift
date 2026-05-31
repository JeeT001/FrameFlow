//
//  CompositePreviewView.swift
//  FrameFlow
//

import AppKit
import SwiftUI

struct CompositePreviewView: View {
    let image: CGImage?
    let aspectRatio: CGFloat
    var fillsWindow: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let size = fittedSize(in: geometry.size)

            CompositePreviewRepresentable(image: image)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    if !fillsWindow {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(AppColors.border)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var cornerRadius: CGFloat {
        fillsWindow ? 0 : 12
    }

    private func fittedSize(in available: CGSize) -> CGSize {
        var width = available.width
        var height = width / aspectRatio
        if height > available.height {
            height = available.height
            width = height * aspectRatio
        }
        return CGSize(width: width, height: height)
    }
}

private struct CompositePreviewRepresentable: NSViewRepresentable {
    let image: CGImage?

    func makeNSView(context: Context) -> CompositePreviewNSView {
        CompositePreviewNSView()
    }

    func updateNSView(_ nsView: CompositePreviewNSView, context: Context) {
        nsView.update(image: image)
    }
}

private final class CompositePreviewNSView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.85).cgColor
        layer?.contentsGravity = .resizeAspect
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func update(image: CGImage?) {
        layer?.contents = image
    }
}

#Preview {
    CompositePreviewView(image: nil, aspectRatio: 16.0 / 9.0)
        .frame(width: 480, height: 320)
        .padding()
}
