//
//  ControlPanelModels.swift
//  ModernKey
//
//  VIPER Entity for ControlPanel module.
//

import Foundation

enum ControlPanelTab: Int {
    case primary = 0
    case macro = 1
    case system = 2
    case sound = 3
    case clipboard = 4
    case info = 5
}

struct GeneralSettingsState {
    var language: Int32
    var inputType: Int32
    var codeTable: Int32
    var freeMark: Bool
    var modernOrthography: Bool
    var checkSpelling: Bool
    var quickTelex: Bool
    var restoreIfWrongSpelling: Bool
    var fixRecommendBrowser: Bool
    var allowConsonantZFWJ: Bool
    var tempOffSpelling: Bool
    var runOnStartup: Bool
    var showUIOnStartup: Bool
    var grayIcon: Bool
    
    // Switch key
    var switchCommand: Bool
    var switchOption: Bool
    var switchControl: Bool
    var switchShift: Bool
    var switchKeyChar: UInt16
    var switchBeepSound: Bool
    
    // Macro tab
    var useMacro: Bool
    var useMacroInEnglishMode: Bool
    var autoCapsMacro: Bool
    
    // System tab
    var sendKeyStepByStep: Bool
    var useSmartSwitchKey: Bool
    var upperCaseFirstChar: Bool
    var quickStartConsonant: Bool
    var quickEndConsonant: Bool
    var rememberCode: Bool
    var otherLanguage: Bool
    var tempOffOpenKey: Bool
    var showIconOnDock: Bool
    var fixChromiumBrowser: Bool
    var performLayoutCompat: Bool
    
    // Sound tab
    var keySoundEnabled: Bool
    var keySoundVoice: Int
    var keySoundVolume: Int
    var keySoundOnlyVietnamese: Bool
    var keySoundSpecialKeys: Bool
    var keySoundRelease: Bool
    
    // Clipboard tab
    var clipboardEnabled: Bool
    var clipboardAutoPaste: Bool
    var clipboardHistorySize: Int
    var clipboardSwitchControl: Bool
    var clipboardSwitchOption: Bool
    var clipboardSwitchCommand: Bool
    var clipboardSwitchShift: Bool
    var clipboardSwitchKeyChar: UInt16
    
    // Info tab
    var checkUpdateOnStartup: Bool
    var versionText: String
}
