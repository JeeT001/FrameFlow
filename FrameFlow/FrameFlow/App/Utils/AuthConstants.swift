//
//  AuthConstants.swift
//  FrameFlow
//

import Foundation

enum AuthConstants {
    static let callbackScheme = "com.simranjit.frameflow"
    static let redirectURL = URL(string: "\(callbackScheme)://auth/callback")!
}
