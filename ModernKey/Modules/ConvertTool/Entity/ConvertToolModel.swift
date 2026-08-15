//
//  ConvertToolModel.swift
//  ModernKey
//
//  VIPER Entity for ConvertTool module.
//

import Foundation

struct ConvertToolConfig {
    var fromCode: Int
    var toCode: Int
    var alertWhenComplete: Bool
    var toAllCaps: Bool
    var toNonCaps: Bool
    var toCapsFirstLetter: Bool
    var toCapsEachWord: Bool
    var removeMark: Bool
    var hotKey: Int32
}
