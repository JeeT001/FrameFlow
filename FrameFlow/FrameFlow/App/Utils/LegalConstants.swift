//
//  LegalConstants.swift
//  FrameFlow
//

import Foundation

enum LegalConstants {
    /// Set when marketing site goes live, e.g. `"https://drazlo.app"`
    static let websiteBaseURL: String? = nil

    static var privacyWebURL: URL? { webURL(path: "/privacy") }
    static var termsWebURL: URL? { webURL(path: "/terms") }

    static func webURL(for document: LegalDocument) -> URL? {
        switch document.kind {
        case .privacyPolicy: privacyWebURL
        case .termsOfService: termsWebURL
        }
    }

    private static func webURL(path: String) -> URL? {
        guard let base = websiteBaseURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !base.isEmpty
        else { return nil }
        let normalized = base.hasSuffix("/") ? String(base.dropLast()) : base
        return URL(string: normalized + path)
    }
}
