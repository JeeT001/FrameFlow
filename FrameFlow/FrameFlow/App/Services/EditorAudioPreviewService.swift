//
//  EditorAudioPreviewService.swift
//  FrameFlow
//

import AVFoundation
import Foundation

/// Mixes imported audio layers during editor preview (export-time coordinates).
@MainActor
final class EditorAudioPreviewService {
    private struct PlayerSlot {
        var player: AVAudioPlayer
    }

    private var slots: [UUID: PlayerSlot] = [:]

    func updateTracks(_ tracks: [EditorImportedAudio]) {
        let activeIDs = Set(tracks.map(\.id))

        for id in slots.keys where !activeIDs.contains(id) {
            slots[id]?.player.stop()
            slots.removeValue(forKey: id)
        }

        for track in tracks where slots[track.id] == nil {
            loadPlayer(for: track)
        }
    }

    func sync(
        tracks: [EditorImportedAudio],
        exportTime: Double,
        isVideoPlaying: Bool,
        mutedTrackIDs: Set<UUID> = []
    ) {
        updateTracks(tracks)

        for track in tracks {
            guard let slot = slots[track.id] else { continue }
            let player = slot.player
            let baseVolume = mutedTrackIDs.contains(track.id) ? 0 : Float(min(max(track.volume, 0), 1))
            player.volume = baseVolume

            let clipStart = track.timelineStartSeconds
            let clipEnd = track.timelineEndSeconds
            guard clipEnd > clipStart else {
                player.pause()
                continue
            }

            let inClip = exportTime >= clipStart && exportTime < clipEnd
            let timelineOffset = exportTime - clipStart
            let sourceOffset = track.sourceTrimStartSeconds + timelineOffset
            let maxSourceEnd = min(track.sourceTrimEndSeconds, player.duration)
            let maxOffset = max(0, min(sourceOffset, maxSourceEnd - 0.01))

            if inClip {
                if abs(player.currentTime - maxOffset) > 0.12 {
                    player.currentTime = maxOffset
                }
                if isVideoPlaying {
                    if !player.isPlaying {
                        player.play()
                    }
                } else {
                    player.pause()
                }
            } else {
                player.pause()
                if exportTime < clipStart {
                    player.currentTime = track.sourceTrimStartSeconds
                } else if exportTime >= clipEnd {
                    player.currentTime = min(
                        track.sourceTrimEndSeconds - 0.01,
                        player.duration - 0.01
                    )
                }
            }
        }
    }

    func pauseAll() {
        for slot in slots.values {
            slot.player.pause()
        }
    }

    func teardown() {
        pauseAll()
        slots.removeAll()
    }

    private func loadPlayer(for track: EditorImportedAudio) {
        Task {
            do {
                try await SecurityScopedFileAccess.withAccess(to: track.fileURL) {
                    let player = try AVAudioPlayer(contentsOf: track.fileURL)
                    player.prepareToPlay()
                    slots[track.id] = PlayerSlot(player: player)
                }
            } catch {
                #if DEBUG
                print("[EditorAudioPreview] Failed to load \(track.fileURL.lastPathComponent): \(error)")
                #endif
            }
        }
    }
}
