//
//  LegalDocument.swift
//  FrameFlow
//

import Foundation

struct LegalSection: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let body: String
}

struct LegalDocument: Identifiable {
    enum Kind: String {
        case privacyPolicy
        case termsOfService
    }

    let kind: Kind
    let title: String
    let lastUpdated: String
    let sections: [LegalSection]
    let draftDisclaimer: String

    var id: Kind { kind }
}
