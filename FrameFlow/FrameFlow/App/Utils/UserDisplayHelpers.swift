//
//  UserDisplayHelpers.swift
//  FrameFlow
//

import Foundation
import Supabase

enum UserDisplayHelpers {
    static func displayName(for user: User?) -> String {
        guard let user else { return "Guest" }

        if let metadataName = stringValue(in: user.userMetadata, key: "full_name"), !metadataName.isEmpty {
            return metadataName
        }
        if let metadataName = stringValue(in: user.userMetadata, key: "display_name"), !metadataName.isEmpty {
            return metadataName
        }
        return user.email ?? "User"
    }

    static func initials(for user: User?) -> String {
        let name = displayName(for: user)
        if name.contains("@") {
            return String(name.prefix(1)).uppercased()
        }
        return initials(from: name)
    }

    static func initials(from name: String) -> String {
        let parts = name
            .split(separator: " ")
            .filter { !$0.isEmpty }

        if parts.count >= 2 {
            let first = parts[0].prefix(1)
            let last = parts[parts.count - 1].prefix(1)
            return "\(first)\(last)".uppercased()
        }

        if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }

        return "?"
    }

    private static func stringValue(in metadata: [String: AnyJSON], key: String) -> String? {
        guard case .string(let value) = metadata[key] else { return nil }
        return value
    }
}
