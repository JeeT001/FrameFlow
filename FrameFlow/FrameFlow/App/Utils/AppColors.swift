//
//  AppColors.swift
//  FrameFlow
//
//  Semantic colors from Assets.xcassets (light/dark appearances).
//  Uses Color("name") to avoid conflicting with Xcode-generated asset symbol extensions.
//

import SwiftUI

enum AppColors {
    static let primary = Color("appPrimary")
    static let background = Color("appBackground")
    static let surface = Color("appSurface")
    static let border = Color("appBorder")
    static let textPrimary = Color("appTextPrimary")
    static let textSecondary = Color("appTextSecondary")
    static let recRed = Color("recRed")
    static let proGold = Color("proGold")
    static let successGreen = Color("successGreen")
    static let pauseYellow = Color("pauseYellow")
}
