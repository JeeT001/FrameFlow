//
//  AuthService.swift
//  FrameFlow
//

import Foundation
import Supabase

enum AuthServiceError: LocalizedError {
    case missingConfiguration
    case emailConfirmationRequired
    case invalidCredentials
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            "Supabase is not configured. Copy Config.example.swift to Config.swift and add your credentials."
        case .emailConfirmationRequired:
            "Check your email to confirm your account before signing in."
        case .invalidCredentials:
            "Invalid email or password."
        case .networkError:
            "Unable to reach the server. Check your internet connection and try again."
        case .unknown(let message):
            message
        }
    }
}

final class AuthService {
    static let shared = AuthService()

    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func signUp(email: String, password: String, name: String) async throws -> User {
        try ensureConfigured()

        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: [
                    "full_name": .string(name),
                    "display_name": .string(name),
                ]
            )

            if response.session == nil {
                throw AuthServiceError.emailConfirmationRequired
            }

            return response.user
        } catch let error as AuthServiceError {
            throw error
        } catch {
            throw mapError(error)
        }
    }

    func signIn(email: String, password: String) async throws -> User {
        try ensureConfigured()

        do {
            let session = try await client.auth.signIn(email: email, password: password)
            return session.user
        } catch {
            throw mapError(error)
        }
    }

    func signOut() async throws {
        try ensureConfigured()

        do {
            try await client.auth.signOut()
        } catch {
            throw mapError(error)
        }
    }

    func resetPassword(email: String) async throws {
        try ensureConfigured()

        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            throw mapError(error)
        }
    }

    func getCurrentSession() -> Session? {
        client.auth.currentSession
    }

    private func ensureConfigured() throws {
        guard SupabaseClientProvider.isConfigured else {
            throw AuthServiceError.missingConfiguration
        }
    }

    private func mapError(_ error: Error) -> AuthServiceError {
        if let authError = error as? Auth.AuthError {
            switch authError {
            case .sessionMissing:
                return .invalidCredentials
            case .weakPassword(let message, _):
                return .unknown(message)
            case .api(let message, let errorCode, _, _):
                switch errorCode {
                case .invalidCredentials, .emailNotConfirmed:
                    return .invalidCredentials
                case .emailExists, .userAlreadyExists:
                    return .unknown("An account with this email already exists.")
                case .weakPassword:
                    return .unknown("Password is too weak. Use at least 8 characters.")
                case .overRequestRateLimit, .overEmailSendRateLimit:
                    return .unknown("Too many attempts. Please wait and try again.")
                default:
                    return .unknown(message)
                }
            default:
                return .unknown(authError.localizedDescription)
            }
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }

        return .unknown(error.localizedDescription)
    }
}
