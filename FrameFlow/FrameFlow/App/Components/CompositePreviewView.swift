//
//  CompositePreviewView.swift
//  FrameFlow
//

import AppKit
import SwiftUI

enum CompositePreviewContentMode {
    case fit
    case fill
}

struct CompositePreviewView: View {
    let image: CGImage?
    let aspectRatio: CGFloat
    var fillsWindow: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let size = PreviewCanvasFitting.fittedSize(
                in: geometry.size,
                aspectRatio: aspectRatio
            )

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
}

struct CompositePreviewRepresentable: NSViewRepresentable {
    let image: CGImage?
    var contentMode: CompositePreviewContentMode = .fit

    func makeNSView(context: Context) -> CompositePreviewNSView {
        CompositePreviewNSView()
    }

    func updateNSView(_ nsView: CompositePreviewNSView, context: Context) {
        nsView.update(image: image, contentMode: contentMode)
    }
}

final class CompositePreviewNSView: NSView {
    /// Match SwiftUI top-left coordinates with CIImage-backed layer contents.
    override var isFlipped: Bool { true }

    private var contentMode: CompositePreviewContentMode = .fit

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.85).cgColor
        applyContentMode()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func update(image: CGImage?, contentMode: CompositePreviewContentMode = .fit) {
        self.contentMode = contentMode
        applyContentMode()
        layer?.contents = image
    }

    private func applyContentMode() {
        layer?.contentsGravity = contentMode == .fill ? .resizeAspectFill : .resizeAspect
    }
}

#Preview {
    CompositePreviewView(image: nil, aspectRatio: 16.0 / 9.0)
        .frame(width: 480, height: 320)
        .padding()
}
