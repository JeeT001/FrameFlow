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

    // MARK: - public.users sync

    @discardableResult
    func createUser(id: UUID, email: String, name: String) async throws -> FrameFlowUser? {
        guard SupabaseClientProvider.isConfigured else { return nil }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = FrameFlowUserInsert(
            id: id,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            displayName: trimmedName.isEmpty ? nil : trimmedName
        )

        do {
            try await client
                .from("users")
                .insert(payload)
                .execute()
        } catch {
            if isUniqueViolation(error) {
                return try await fetchUser(userId: id)
            }
            throw error
        }

        return try await fetchUser(userId: id)
    }

    func fetchUser(userId: UUID) async throws -> FrameFlowUser? {
        guard SupabaseClientProvider.isConfigured else { return nil }

        let rows: [FrameFlowUser] = try await client
            .from("users")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    func ensureUserProfile(for authUser: User) async {
        guard SupabaseClientProvider.isConfigured else { return }

        do {
            if try await fetchUser(userId: authUser.id) != nil {
                return
            }

            let email = authUser.email ?? ""
            guard !email.isEmpty else { return }

            let name = UserDisplayHelpers.displayName(for: authUser)
            _ = try await createUser(id: authUser.id, email: email, name: name)
        } catch {
            #if DEBUG
            print("[UserService] ensureUserProfile failed: \(error.localizedDescription)")
            #endif
        }
    }

    func updateDisplayName(_ name: String) async throws -> User {
        guard let userId = client.auth.currentUser?.id else {
            throw AuthServiceError.unknown("Not signed in.")
        }
        return try await updateDisplayName(userId: userId, name: name)
    }

    func updateDisplayName(userId: UUID, name: String) async throws -> User {
        guard SupabaseClientProvider.isConfigured else {
            throw AuthServiceError.missingConfiguration
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AuthServiceError.unknown("Display name cannot be empty.")
        }

        try await client
            .from("users")
            .update(FrameFlowUserUpdate(displayName: trimmed))
            .eq("id", value: userId)
            .execute()

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

    #if DEBUG
    func debugLogSubscription(for userId: UUID) async {
        guard SupabaseClientProvider.isConfigured else { return }

        do {
            let rows: [FrameFlowSubscription] = try await client
                .from("subscriptions")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value

            if let sub = rows.first {
                print("[UserService] subscription row: plan=\(sub.plan) status=\(sub.status)")
            } else {
                print("[UserService] no subscription row for user \(userId.uuidString)")
            }
        } catch {
            print("[UserService] subscription fetch failed: \(error.localizedDescription)")
        }
    }
    #endif

    // MARK: - Helpers

    private func isUniqueViolation(_ error: Error) -> Bool {
        if let postgrest = error as? PostgrestError, postgrest.code == "23505" {
            return true
        }
        let message = error.localizedDescription.lowercased()
        return message.contains("duplicate key") || message.contains("unique constraint")
    }
}
