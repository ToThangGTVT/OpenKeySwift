//
//  AboutModel.swift
//  ModernKey
//
//  VIPER Entity for About module.
//

import Foundation

struct AboutInfo {
    let versionText: String
    let isCheckUpdateOnStartup: Bool
    let homePageURL: URL?
    let fanPageURL: URL?
    let releasesURL: URL?
}
