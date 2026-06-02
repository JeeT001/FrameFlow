//
//  SecurityScopedFileAccess.swift
//  FrameFlow
//

import Foundation

enum SecurityScopedFileAccess {
    enum AccessError: LocalizedError {
        case denied

        var errorDescription: String? {
            SecurityScopedFileAccess.accessDeniedMessage
        }
    }

    static let accessDeniedMessage = "Re-select your save folder in Settings, then try again."

    static func canAccess(_ fileURL: URL) -> Bool {
        if RecordingStaging.isAppContainerPath(fileURL) {
            return FileManager.default.fileExists(atPath: fileURL.path)
        }

        if fileURL.startAccessingSecurityScopedResource() {
            defer { fileURL.stopAccessingSecurityScopedResource() }
            return FileManager.default.isReadableFile(atPath: fileURL.path)
        }

        guard let folderURL = resolveScopedSaveFolderURL() else {
            return false
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }
        return FileManager.default.isReadableFile(atPath: fileURL.path)
    }

    static func withAccess<T>(to fileURL: URL, _ work: () throws -> T) throws -> T {
        if RecordingStaging.isAppContainerPath(fileURL) {
            return try work()
        }

        if fileURL.startAccessingSecurityScopedResource() {
            defer { fileURL.stopAccessingSecurityScopedResource() }
            return try work()
        }

        guard let folderURL = resolveScopedSaveFolderURL() else {
            throw AccessError.denied
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }
        return try work()
    }

    static func withAccess<T>(to fileURL: URL, _ work: () async throws -> T) async throws -> T {
        if RecordingStaging.isAppContainerPath(fileURL) {
            return try await work()
        }

        if fileURL.startAccessingSecurityScopedResource() {
            defer { fileURL.stopAccessingSecurityScopedResource() }
            return try await work()
        }

        guard let folderURL = resolveScopedSaveFolderURL() else {
            throw AccessError.denied
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }
        return try await work()
    }

    static func withSaveFolderAccess<T>(
        fallbackURL: URL? = nil,
        _ work: (URL) throws -> T
    ) throws -> T {
        if let folderURL = resolveScopedSaveFolderURL() {
            defer { folderURL.stopAccessingSecurityScopedResource() }
            return try work(folderURL)
        }

        if let fallbackURL {
            let fileManager = FileManager.default
            try fileManager.createDirectory(at: fallbackURL, withIntermediateDirectories: true)
            return try work(fallbackURL)
        }

        throw AccessError.denied
    }

    static func withSaveFolderAccess<T>(
        fallbackURL: URL? = nil,
        _ work: (URL) async throws -> T
    ) async throws -> T {
        if let folderURL = resolveScopedSaveFolderURL() {
            defer { folderURL.stopAccessingSecurityScopedResource() }
            return try await work(folderURL)
        }

        if let fallbackURL {
            let fileManager = FileManager.default
            try fileManager.createDirectory(at: fallbackURL, withIntermediateDirectories: true)
            return try await work(fallbackURL)
        }

        throw AccessError.denied
    }

    static func resolveScopedSaveFolderURL() -> URL? {
        guard let bookmarkData = SettingsStore.shared.defaultSaveFolderBookmarkData else {
            return nil
        }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), !isStale else {
            return nil
        }

        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }

        return url
    }
}
