//
//  FrameFlowUser.swift
//  FrameFlow
//

import Foundation

struct FrameFlowUser: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let email: String
    var displayName: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct FrameFlowUserInsert: Encodable, Sendable {
    let id: UUID
    let email: String
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
    }
}

struct FrameFlowUserUpdate: Encodable, Sendable {
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

#if DEBUG
struct FrameFlowSubscription: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let plan: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case plan
        case status
    }
}
#endif
