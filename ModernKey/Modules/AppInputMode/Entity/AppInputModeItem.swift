//
//  AppInputModeItem.swift
//  ModernKey
//
//  Entity representing an application and its preferred input method.
//

import Cocoa

struct AppInputModeItem: Equatable {
    let bundleId: String
    var appName: String
    var icon: NSImage?
    var isVietnamese: Bool // true = [V] (1), false = [E] (0)
    var codeTable: Int
}

struct AppInputModeStats {
    let totalCount: Int
    let vietnameseCount: Int
    let englishCount: Int
}
