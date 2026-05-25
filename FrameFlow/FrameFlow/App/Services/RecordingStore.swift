//
//  RecordingStore.swift
//  FrameFlow
//

import Foundation

@Observable
final class RecordingStore {
    static let shared = RecordingStore()

    private(set) var recordings: [RecordingMetadata] = []
    private(set) var isLoading = false

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private init() {}

    private var storageDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("FrameFlow", isDirectory: true)
    }

    private var recordingsFileURL: URL {
        storageDirectory.appendingPathComponent("recordings.json")
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try ensureStorageDirectoryExists()

            guard fileManager.fileExists(atPath: recordingsFileURL.path) else {
                try writeRecordings([])
                recordings = []
                return
            }

            let data = try Data(contentsOf: recordingsFileURL)
            let loaded = try decoder.decode([RecordingMetadata].self, from: data)
            recordings = sortRecordings(loaded)
        } catch {
            recordings = []
            try? writeRecordings([])
        }
    }

    func add(_ recording: RecordingMetadata) throws {
        recordings = sortRecordings(recordings + [recording])
        try save()
    }

    func remove(id: UUID) throws {
        recordings.removeAll { $0.id == id }
        try save()
    }

    #if DEBUG
    /// Inserts sample metadata when `FRAME_FLOW_MOCK_RECORDINGS=1` is set in the scheme environment.
    func loadDebugMocksIfNeeded() throws {
        guard ProcessInfo.processInfo.environment["FRAME_FLOW_MOCK_RECORDINGS"] == "1" else { return }
        guard recordings.isEmpty else { return }

        try add(.mock(name: "Product Demo", daysAgo: 1))
        try add(.mock(name: "Tutorial Walkthrough", resolution: "1080x1920", format: "9:16", daysAgo: 3))
    }
    #endif

    private func save() throws {
        try writeRecordings(recordings)
    }

    private func writeRecordings(_ items: [RecordingMetadata]) throws {
        try ensureStorageDirectoryExists()
        let data = try encoder.encode(items)
        try data.write(to: recordingsFileURL, options: .atomic)
    }

    private func ensureStorageDirectoryExists() throws {
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        }
    }

    private func sortRecordings(_ items: [RecordingMetadata]) -> [RecordingMetadata] {
        items.sorted { $0.createdAt > $1.createdAt }
    }
}
