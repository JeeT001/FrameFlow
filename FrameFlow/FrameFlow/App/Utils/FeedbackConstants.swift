//
//  FeedbackConstants.swift
//  FrameFlow
//

import Foundation

enum FeedbackConstants {
    /// External feedback form (Typeform, Google Forms, etc.). Set `feedbackFormURL` in `Config.swift`.
    static var formURL: URL? {
        let raw = Config.feedbackFormURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        return URL(string: raw)
    }
}
