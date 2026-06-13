//
//  ExportDiskSpaceChecker.swift
//  FrameFlow
//

import AVFoundation
import Foundation

enum ExportDiskSpaceChecker {
    static let diskFullMessage = "Not enough disk space to save the export. Free up space and try again."

    static func hasSufficientSpace(at folderURL: URL, minimumBytes: Int64 = 256 * 1024 * 1024) -> Bool {
        guard let values = try? folderURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let available = values.volumeAvailableCapacityForImportantUsage else {
            return true
        }
        return available >= minimumBytes
    }

    static func isDiskFullError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSPOSIXErrorDomain, nsError.code == 28 {
            return true
        }
        if nsError.domain == AVFoundationErrorDomain,
           nsError.code == AVError.diskFull.rawValue {
            return true
        }
        let message = nsError.localizedDescription.lowercased()
        return message.contains("disk full")
            || message.contains("no space")
            || message.contains("not enough space")
            || message.contains("enospc")
    }

    static func userFacingExportError(_ error: Error) -> String {
        if let exportError = error as? ExportServiceError {
            switch exportError {
            case .diskFull:
                return diskFullMessage
            case .exportFailed(let detail):
                if isDiskFullError(NSError(domain: "FrameFlow", code: 0, userInfo: [NSLocalizedDescriptionKey: detail])) {
                    return diskFullMessage
                }
                return exportError.localizedDescription
            default:
                return exportError.localizedDescription
            }
        }
        if isDiskFullError(error) {
            return diskFullMessage
        }
        return error.localizedDescription
    }
}
