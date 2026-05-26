//
//  AudioLevelMonitor.swift
//  FrameFlow
//

import AVFoundation
import CoreAudio
import Foundation

@Observable
@MainActor
final class AudioLevelMonitor {
    var level: Float = 0
    var permissionDenied = false
    var statusMessage: String?

    private var engine: AVAudioEngine?
    private var smoothedLevel: Float = 0
    private var savedDefaultInputDeviceID: AudioDeviceID?

    func startMonitoring(preferredDeviceUniqueID: String?) async {
        stopMonitoring()

        let status = PermissionManager.shared.checkMicrophonePermission()
        if status == .notDetermined {
            let granted = await PermissionManager.shared.requestMicrophonePermission()
            guard granted else {
                setPermissionDenied("Microphone access is required for input level monitoring.")
                return
            }
        } else if status != .authorized {
            setPermissionDenied("Enable microphone access in System Settings to see input levels.")
            return
        }

        if let uniqueID = preferredDeviceUniqueID,
           let deviceID = Self.audioDeviceID(forUID: uniqueID) {
            savedDefaultInputDeviceID = Self.currentDefaultInputDeviceID()
            _ = Self.setDefaultInputDevice(deviceID)
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            let sampleLevel = Self.rmsLevel(from: buffer)
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.smoothedLevel = self.smoothedLevel * 0.65 + sampleLevel * 0.35
                self.level = min(1, self.smoothedLevel)
            }
        }

        do {
            engine.prepare()
            try engine.start()
            self.engine = engine
            permissionDenied = false
            statusMessage = nil
        } catch {
            restoreDefaultInputDeviceIfNeeded()
            setPermissionDenied("Could not start audio level monitoring.")
        }
    }

    func stopMonitoring() {
        if let engine {
            inputNodeRemoveTapSafely(engine)
            engine.stop()
        }
        engine = nil
        level = 0
        smoothedLevel = 0
        restoreDefaultInputDeviceIfNeeded()
        permissionDenied = false
        statusMessage = nil
    }

    private func setPermissionDenied(_ message: String) {
        permissionDenied = true
        statusMessage = message
        level = 0
        smoothedLevel = 0
    }

    private func restoreDefaultInputDeviceIfNeeded() {
        guard let savedDefaultInputDeviceID else { return }
        _ = Self.setDefaultInputDevice(savedDefaultInputDeviceID)
        self.savedDefaultInputDeviceID = nil
    }

    private func inputNodeRemoveTapSafely(_ engine: AVAudioEngine) {
        engine.inputNode.removeTap(onBus: 0)
    }

    private static func rmsLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum: Float = 0
        var sampleCount = 0

        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for frame in 0..<frameLength {
                let sample = samples[frame]
                sum += sample * sample
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else { return 0 }
        let rms = sqrt(sum / Float(sampleCount))
        return min(1, rms * 8)
    }

    private static func currentDefaultInputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : nil
    }

    private static func setDefaultInputDevice(_ deviceID: AudioDeviceID) -> Bool {
        var mutableDeviceID = deviceID
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &mutableDeviceID
        )
        return status == noErr
    }

    private static func audioDeviceID(forUID uid: String) -> AudioDeviceID? {
        guard let deviceIDs = allAudioDeviceIDs() else { return nil }

        for deviceID in deviceIDs {
            guard let deviceUID = deviceUID(for: deviceID), deviceUID == uid else { continue }
            return deviceID
        }
        return nil
    }

    private static func allAudioDeviceIDs() -> [AudioDeviceID]? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        ) == noErr else { return nil }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceIDs
        ) == noErr else { return nil }

        return deviceIDs
    }

    private static func deviceUID(for deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var uid: CFString?
        var size = UInt32(MemoryLayout<CFString?>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &uid)
        guard status == noErr, let uid else { return nil }
        return uid as String
    }
}
