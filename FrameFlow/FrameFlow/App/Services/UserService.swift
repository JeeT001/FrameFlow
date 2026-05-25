//
//  UserService.swift
//  FrameFlow
//

import Foundation
import Supabase

final class UserService {
    static let shared = UserService()

    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func updateDisplayName(_ name: String) async throws -> User {
        guard SupabaseClientProvider.isConfigured else {
            throw AuthServiceError.missingConfiguration
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AuthServiceError.unknown("Display name cannot be empty.")
        }

        let attributes = UserAttributes(
            data: [
                "full_name": .string(trimmed),
                "display_name": .string(trimmed),
            ]
        )

        return try await client.auth.update(user: attributes)
    }

    func refreshCurrentUser() async -> User? {
        guard SupabaseClientProvider.isConfigured else { return nil }

        if let session = await AuthService.shared.restoreSession() {
            return session.user
        }
        return client.auth.currentUser
    }
}
