//
//  SettingsService.swift
//  ModernKey
//
//  Service managing app preferences and synchronization with C++ Engine global flags.
//

import Cocoa
import ServiceManagement

protocol SettingsServiceProtocol: AnyObject {
    func loadDefaultConfig()
    func synchronizeAll()
    
    // Getters & Setters for main options
    var language: Int32 { get set }
    var inputType: Int32 { get set }
    var codeTable: Int32 { get set }
    var switchKeyStatus: Int32 { get set }
    
    var freeMark: Bool { get set }
    var modernOrthography: Bool { get set }
    var checkSpelling: Bool { get set }
    var quickTelex: Bool { get set }
    var restoreIfWrongSpelling: Bool { get set }
    var fixRecommendBrowser: Bool { get set }
    var allowConsonantZFWJ: Bool { get set }
    var tempOffSpelling: Bool { get set }
    
    var useMacro: Bool { get set }
    var useMacroInEnglishMode: Bool { get set }
    var autoCapsMacro: Bool { get set }
    
    var sendKeyStepByStep: Bool { get set }
    var useSmartSwitchKey: Bool { get set }
    var upperCaseFirstChar: Bool { get set }
    var quickStartConsonant: Bool { get set }
    var quickEndConsonant: Bool { get set }
    var rememberCode: Bool { get set }
    var otherLanguage: Bool { get set }
    var tempOffOpenKey: Bool { get set }
    var showIconOnDock: Bool { get set }
    var fixChromiumBrowser: Bool { get set }
    var performLayoutCompat: Bool { get set }
    
    var runOnStartup: Bool { get set }
    var showUIOnStartup: Bool { get set }
    var grayIcon: Bool { get set }
    var checkUpdateOnStartup: Bool { get set }
    
    func setRunOnStartupEnabled(_ enabled: Bool)
    func setShowIconOnDockEnabled(_ enabled: Bool)
}

final class SettingsService: SettingsServiceProtocol {
    static let shared = SettingsService()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    func loadDefaultConfig() {
        language = 1
        inputType = 0
        freeMark = false
        checkSpelling = true
        codeTable = 0
        switchKeyStatus = 0x7A000206
        quickTelex = false
        modernOrthography = false
        restoreIfWrongSpelling = false
        fixRecommendBrowser = true
        useMacro = true
        useMacroInEnglishMode = false
        sendKeyStepByStep = false
        useSmartSwitchKey = true
        upperCaseFirstChar = false
        tempOffSpelling = false
        allowConsonantZFWJ = false
        quickStartConsonant = false
        quickEndConsonant = false
        rememberCode = true
        otherLanguage = true
        tempOffOpenKey = false
        showIconOnDock = false
        fixChromiumBrowser = false
        performLayoutCompat = false
        
        KeySoundService.shared.setEnabled(false)
        KeySoundService.shared.setVoice(index: 0)
        KeySoundService.shared.setVolume(60)
        KeySoundService.shared.setOnlyVietnamese(false)
        KeySoundService.shared.setSpecialKeys(true)
        KeySoundService.shared.setReleaseSound(true)
        
        defaults.set(1, forKey: "GrayIcon")
        defaults.set(1, forKey: "RunOnStartup")
        defaults.set(1, forKey: "NonFirstTime")
        
        setRunOnStartupEnabled(true)
        synchronizeAll()
    }
    
    func synchronizeAll() {
        vLanguage = Int32(defaults.integer(forKey: "InputMethod"))
        vInputType = Int32(defaults.integer(forKey: "InputType"))
        vFreeMark = Int32(defaults.integer(forKey: "FreeMark"))
        vCheckSpelling = Int32(defaults.integer(forKey: "Spelling"))
        vCodeTable = Int32(defaults.integer(forKey: "CodeTable"))
        
        var sk = defaults.integer(forKey: "SwitchKeyStatus")
        if sk == 0 { sk = 0x7A000206 }
        vSwitchKeyStatus = Int32(sk)
        
        vQuickTelex = Int32(defaults.integer(forKey: "QuickTelex"))
        vUseModernOrthography = Int32(defaults.integer(forKey: "ModernOrthography"))
        vRestoreIfWrongSpelling = Int32(defaults.integer(forKey: "RestoreIfInvalidWord"))
        vFixRecommendBrowser = Int32(defaults.integer(forKey: "FixRecommendBrowser"))
        vUseMacro = Int32(defaults.integer(forKey: "UseMacro"))
        vUseMacroInEnglishMode = Int32(defaults.integer(forKey: "UseMacroInEnglishMode"))
        vSendKeyStepByStep = Int32(defaults.integer(forKey: "SendKeyStepByStep"))
        vUseSmartSwitchKey = Int32(defaults.integer(forKey: "UseSmartSwitchKey"))
        vUpperCaseFirstChar = Int32(defaults.integer(forKey: "UpperCaseFirstChar"))
        vTempOffSpelling = Int32(defaults.integer(forKey: "vTempOffSpelling"))
        vAllowConsonantZFWJ = Int32(defaults.integer(forKey: "vAllowConsonantZFWJ"))
        vQuickStartConsonant = Int32(defaults.integer(forKey: "vQuickStartConsonant"))
        vQuickEndConsonant = Int32(defaults.integer(forKey: "vQuickEndConsonant"))
        vRememberCode = Int32(defaults.integer(forKey: "vRememberCode"))
        vOtherLanguage = Int32(defaults.integer(forKey: "vOtherLanguage"))
        vTempOffOpenKey = Int32(defaults.integer(forKey: "vTempOffOpenKey"))
        vShowIconOnDock = Int32(defaults.integer(forKey: "vShowIconOnDock"))
        vFixChromiumBrowser = Int32(defaults.integer(forKey: "vFixChromiumBrowser"))
        vPerformLayoutCompat = Int32(defaults.integer(forKey: "vPerformLayoutCompat"))
        vAutoCapsMacro = Int32(defaults.integer(forKey: "AutoCapsMacro"))
        
        vKeySound = Int32(defaults.integer(forKey: "vKeySound"))
        vKeySoundVoice = Int32(defaults.integer(forKey: "vKeySoundVoice"))
        var vol = defaults.integer(forKey: "vKeySoundVolume")
        if vol == 0 && !defaults.bool(forKey: "vKeySoundVolume_Set") {
            vol = 60
            defaults.set(60, forKey: "vKeySoundVolume")
            defaults.set(true, forKey: "vKeySoundVolume_Set")
        }
        vKeySoundVolume = Int32(vol)
        vKeySoundOnlyVietnamese = Int32(defaults.integer(forKey: "vKeySoundOnlyVietnamese"))
        vKeySoundSpecialKeys = defaults.object(forKey: "vKeySoundSpecialKeys") != nil ? Int32(defaults.integer(forKey: "vKeySoundSpecialKeys")) : 1
        vKeySoundRelease = defaults.object(forKey: "vKeySoundRelease") != nil ? Int32(defaults.integer(forKey: "vKeySoundRelease")) : 1
        
        KeySoundService.shared.applySettings()
    }
    
    // MARK: - General Properties
    
    var language: Int32 {
        get { Int32(defaults.integer(forKey: "InputMethod")) }
        set {
            vLanguage = newValue
            defaults.set(Int(newValue), forKey: "InputMethod")
        }
    }
    
    var inputType: Int32 {
        get { Int32(defaults.integer(forKey: "InputType")) }
        set {
            vInputType = newValue
            defaults.set(Int(newValue), forKey: "InputType")
        }
    }
    
    var codeTable: Int32 {
        get { Int32(defaults.integer(forKey: "CodeTable")) }
        set {
            vCodeTable = newValue
            defaults.set(Int(newValue), forKey: "CodeTable")
            OnTableCodeChange()
        }
    }
    
    var switchKeyStatus: Int32 {
        get {
            let val = defaults.integer(forKey: "SwitchKeyStatus")
            return val == 0 ? 0x7A000206 : Int32(val)
        }
        set {
            vSwitchKeyStatus = newValue
            defaults.set(Int(newValue), forKey: "SwitchKeyStatus")
        }
    }
    
    var freeMark: Bool {
        get { defaults.integer(forKey: "FreeMark") != 0 }
        set {
            vFreeMark = newValue ? 1 : 0
            defaults.set(vFreeMark, forKey: "FreeMark")
        }
    }
    
    var modernOrthography: Bool {
        get { defaults.integer(forKey: "ModernOrthography") != 0 }
        set {
            vUseModernOrthography = newValue ? 1 : 0
            defaults.set(vUseModernOrthography, forKey: "ModernOrthography")
        }
    }
    
    var checkSpelling: Bool {
        get { defaults.integer(forKey: "Spelling") != 0 }
        set {
            vCheckSpelling = newValue ? 1 : 0
            defaults.set(vCheckSpelling, forKey: "Spelling")
            OnSpellCheckingChanged()
        }
    }
    
    var quickTelex: Bool {
        get { defaults.integer(forKey: "QuickTelex") != 0 }
        set {
            vQuickTelex = newValue ? 1 : 0
            defaults.set(vQuickTelex, forKey: "QuickTelex")
        }
    }
    
    var restoreIfWrongSpelling: Bool {
        get { defaults.integer(forKey: "RestoreIfInvalidWord") != 0 }
        set {
            vRestoreIfWrongSpelling = newValue ? 1 : 0
            defaults.set(vRestoreIfWrongSpelling, forKey: "RestoreIfInvalidWord")
        }
    }
    
    var fixRecommendBrowser: Bool {
        get { defaults.integer(forKey: "FixRecommendBrowser") != 0 }
        set {
            vFixRecommendBrowser = newValue ? 1 : 0
            defaults.set(vFixRecommendBrowser, forKey: "FixRecommendBrowser")
        }
    }
    
    var allowConsonantZFWJ: Bool {
        get { defaults.integer(forKey: "vAllowConsonantZFWJ") != 0 }
        set {
            vAllowConsonantZFWJ = newValue ? 1 : 0
            defaults.set(vAllowConsonantZFWJ, forKey: "vAllowConsonantZFWJ")
        }
    }
    
    var tempOffSpelling: Bool {
        get { defaults.integer(forKey: "vTempOffSpelling") != 0 }
        set {
            vTempOffSpelling = newValue ? 1 : 0
            defaults.set(vTempOffSpelling, forKey: "vTempOffSpelling")
        }
    }
    
    var useMacro: Bool {
        get { defaults.integer(forKey: "UseMacro") != 0 }
        set {
            vUseMacro = newValue ? 1 : 0
            defaults.set(vUseMacro, forKey: "UseMacro")
        }
    }
    
    var useMacroInEnglishMode: Bool {
        get { defaults.integer(forKey: "UseMacroInEnglishMode") != 0 }
        set {
            vUseMacroInEnglishMode = newValue ? 1 : 0
            defaults.set(vUseMacroInEnglishMode, forKey: "UseMacroInEnglishMode")
        }
    }
    
    var autoCapsMacro: Bool {
        get { defaults.integer(forKey: "AutoCapsMacro") != 0 }
        set {
            vAutoCapsMacro = newValue ? 1 : 0
            defaults.set(vAutoCapsMacro, forKey: "AutoCapsMacro")
        }
    }
    
    var sendKeyStepByStep: Bool {
        get { defaults.integer(forKey: "SendKeyStepByStep") != 0 }
        set {
            vSendKeyStepByStep = newValue ? 1 : 0
            defaults.set(vSendKeyStepByStep, forKey: "SendKeyStepByStep")
        }
    }
    
    var useSmartSwitchKey: Bool {
        get { defaults.integer(forKey: "UseSmartSwitchKey") != 0 }
        set {
            vUseSmartSwitchKey = newValue ? 1 : 0
            defaults.set(vUseSmartSwitchKey, forKey: "UseSmartSwitchKey")
        }
    }
    
    var upperCaseFirstChar: Bool {
        get { defaults.integer(forKey: "UpperCaseFirstChar") != 0 }
        set {
            vUpperCaseFirstChar = newValue ? 1 : 0
            defaults.set(vUpperCaseFirstChar, forKey: "UpperCaseFirstChar")
        }
    }
    
    var quickStartConsonant: Bool {
        get { defaults.integer(forKey: "vQuickStartConsonant") != 0 }
        set {
            vQuickStartConsonant = newValue ? 1 : 0
            defaults.set(vQuickStartConsonant, forKey: "vQuickStartConsonant")
        }
    }
    
    var quickEndConsonant: Bool {
        get { defaults.integer(forKey: "vQuickEndConsonant") != 0 }
        set {
            vQuickEndConsonant = newValue ? 1 : 0
            defaults.set(vQuickEndConsonant, forKey: "vQuickEndConsonant")
        }
    }
    
    var rememberCode: Bool {
        get { defaults.integer(forKey: "vRememberCode") != 0 }
        set {
            vRememberCode = newValue ? 1 : 0
            defaults.set(vRememberCode, forKey: "vRememberCode")
        }
    }
    
    var otherLanguage: Bool {
        get { defaults.integer(forKey: "vOtherLanguage") != 0 }
        set {
            vOtherLanguage = newValue ? 1 : 0
            defaults.set(vOtherLanguage, forKey: "vOtherLanguage")
        }
    }
    
    var tempOffOpenKey: Bool {
        get { defaults.integer(forKey: "vTempOffOpenKey") != 0 }
        set {
            vTempOffOpenKey = newValue ? 1 : 0
            defaults.set(vTempOffOpenKey, forKey: "vTempOffOpenKey")
        }
    }
    
    var showIconOnDock: Bool {
        get { defaults.integer(forKey: "vShowIconOnDock") != 0 }
        set {
            vShowIconOnDock = newValue ? 1 : 0
            defaults.set(vShowIconOnDock, forKey: "vShowIconOnDock")
            setShowIconOnDockEnabled(newValue)
        }
    }
    
    var fixChromiumBrowser: Bool {
        get { defaults.integer(forKey: "vFixChromiumBrowser") != 0 }
        set {
            vFixChromiumBrowser = newValue ? 1 : 0
            defaults.set(vFixChromiumBrowser, forKey: "vFixChromiumBrowser")
        }
    }
    
    var performLayoutCompat: Bool {
        get { defaults.integer(forKey: "vPerformLayoutCompat") != 0 }
        set {
            vPerformLayoutCompat = newValue ? 1 : 0
            defaults.set(vPerformLayoutCompat, forKey: "vPerformLayoutCompat")
        }
    }
    
    var runOnStartup: Bool {
        get { defaults.integer(forKey: "RunOnStartup") != 0 }
        set {
            defaults.set(newValue ? 1 : 0, forKey: "RunOnStartup")
            setRunOnStartupEnabled(newValue)
        }
    }
    
    var showUIOnStartup: Bool {
        get { defaults.integer(forKey: "ShowUIOnStartup") != 0 }
        set { defaults.set(newValue ? 1 : 0, forKey: "ShowUIOnStartup") }
    }
    
    var grayIcon: Bool {
        get { defaults.integer(forKey: "GrayIcon") != 0 }
        set { defaults.set(newValue ? 1 : 0, forKey: "GrayIcon") }
    }
    
    var checkUpdateOnStartup: Bool {
        get { defaults.integer(forKey: "DontCheckUpdate") == 0 }
        set { defaults.set(newValue ? 0 : 1, forKey: "DontCheckUpdate") }
    }
    
    func setRunOnStartupEnabled(_ enabled: Bool) {
        let appId = OPENKEY_HELPER_BUNDLE as CFString
        SMLoginItemSetEnabled(appId, enabled)
    }
    
    func setShowIconOnDockEnabled(_ enabled: Bool) {
        NSApp.setActivationPolicy(enabled ? .regular : .accessory)
    }
}
