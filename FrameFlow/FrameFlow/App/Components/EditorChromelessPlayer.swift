//
//  EditorChromelessPlayer.swift
//  FrameFlow
//

import AVKit
import SwiftUI

/// Video preview without AVKit transport chrome — editor uses a single scrubber row.
struct EditorChromelessPlayer: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.showsFullScreenToggleButton = false
        view.showsSharingServiceButton = false
        view.videoGravity = .resizeAspect
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
        nsView.videoGravity = .resizeAspect
    }
}
