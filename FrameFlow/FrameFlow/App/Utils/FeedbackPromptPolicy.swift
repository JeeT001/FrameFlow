//
//  FeedbackPromptPolicy.swift
//  FrameFlow
//

import Foundation

enum FeedbackPromptPolicy {
    static let minimumCompletedExports = 3
    static let presentationInterval: TimeInterval = 7 * 24 * 60 * 60

    static func shouldShow(exportCount: Int, lastPresentedAt: Date?, hasFormURL: Bool) -> Bool {
        guard hasFormURL else { return false }
        guard exportCount >= minimumCompletedExports else { return false }
        guard let lastPresentedAt else { return true }
        return Date().timeIntervalSince(lastPresentedAt) >= presentationInterval
    }
}
