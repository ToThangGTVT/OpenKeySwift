//
//  ControlPanelInteractor.swift
//  ModernKey
//
//  VIPER Interactor for ControlPanel module.
//

import Cocoa

final class ControlPanelInteractor: ControlPanelInteractorInputProtocol {
    weak var presenter: ControlPanelInteractorOutputProtocol?
    
    private var settingsService: SettingsServiceProtocol
    private let keySoundService: KeySoundServiceProtocol
    private let clipboardService: ClipboardServiceProtocol
    private let updateService: UpdateServiceProtocol
    private let accessibilityService: AccessibilityServiceProtocol
    
    init(settingsService: SettingsServiceProtocol = SettingsService.shared,
         keySoundService: KeySoundServiceProtocol = KeySoundService.shared,
         clipboardService: ClipboardServiceProtocol = ClipboardService.shared,
         updateService: UpdateServiceProtocol = UpdateService.shared,
         accessibilityService: AccessibilityServiceProtocol = AccessibilityService.shared) {
        self.settingsService = settingsService
        self.keySoundService = keySoundService
        self.clipboardService = clipboardService
        self.updateService = updateService
        self.accessibilityService = accessibilityService
    }
    
    func loadInitialData() {
        let inputTypes = ["Telex", "VNI", "Simple Telex 1", "Simple Telex 2"]
        let codeTables = OpenKeyManager.getTableCodes()
        let soundVoices = keySoundService.voiceNames
        
        let state = buildCurrentState()
        presenter?.didLoadState(state, inputTypes: inputTypes, codeTables: codeTables, soundVoices: soundVoices)
    }
    
    private func buildCurrentState() -> GeneralSettingsState {
        let defaults = UserDefaults.standard
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let buildDate = OpenKeyManager.getBuildDate()
        let versionText = "Phiên bản \(shortVersion) (build \(version)) - Ngày cập nhật \(buildDate)"
        
        let sk = Int(settingsService.switchKeyStatus)
        let rawCbk = defaults.integer(forKey: "ClipboardHotkeyData")
        let cbk = rawCbk == 0 ? ((118 << 24) | 0x09 | 0x400 | 0x800) : rawCbk
        
        return GeneralSettingsState(
            language: settingsService.language,
            inputType: settingsService.inputType,
            codeTable: settingsService.codeTable,
            freeMark: settingsService.freeMark,
            modernOrthography: settingsService.modernOrthography,
            checkSpelling: settingsService.checkSpelling,
            quickTelex: settingsService.quickTelex,
            restoreIfWrongSpelling: settingsService.restoreIfWrongSpelling,
            fixRecommendBrowser: settingsService.fixRecommendBrowser,
            allowConsonantZFWJ: settingsService.allowConsonantZFWJ,
            tempOffSpelling: settingsService.tempOffSpelling,
            runOnStartup: settingsService.runOnStartup,
            showUIOnStartup: settingsService.showUIOnStartup,
            grayIcon: settingsService.grayIcon,
            
            switchCommand: (sk & 0x400) != 0,
            switchOption: (sk & 0x200) != 0,
            switchControl: (sk & 0x100) != 0,
            switchShift: (sk & 0x800) != 0,
            switchKeyChar: UInt16((sk >> 24) & 0xFF),
            switchBeepSound: (sk & 0x8000) != 0,
            
            useMacro: settingsService.useMacro,
            useMacroInEnglishMode: settingsService.useMacroInEnglishMode,
            autoCapsMacro: settingsService.autoCapsMacro,
            
            sendKeyStepByStep: settingsService.sendKeyStepByStep,
            useSmartSwitchKey: settingsService.useSmartSwitchKey,
            upperCaseFirstChar: settingsService.upperCaseFirstChar,
            quickStartConsonant: settingsService.quickStartConsonant,
            quickEndConsonant: settingsService.quickEndConsonant,
            rememberCode: settingsService.rememberCode,
            otherLanguage: settingsService.otherLanguage,
            tempOffOpenKey: settingsService.tempOffOpenKey,
            showIconOnDock: settingsService.showIconOnDock,
            fixChromiumBrowser: settingsService.fixChromiumBrowser,
            performLayoutCompat: settingsService.performLayoutCompat,
            
            keySoundEnabled: vKeySound != 0,
            keySoundVoice: Int(vKeySoundVoice),
            keySoundVolume: Int(vKeySoundVolume),
            keySoundOnlyVietnamese: vKeySoundOnlyVietnamese != 0,
            keySoundSpecialKeys: vKeySoundSpecialKeys != 0,
            keySoundRelease: vKeySoundRelease != 0,
            
            clipboardEnabled: clipboardService.isEnabled,
            clipboardAutoPaste: clipboardService.isAutoPaste,
            clipboardHistorySize: clipboardService.historySize,
            clipboardSwitchControl: (cbk & 0x100) != 0,
            clipboardSwitchOption: (cbk & 0x200) != 0,
            clipboardSwitchCommand: (cbk & 0x400) != 0,
            clipboardSwitchShift: (cbk & 0x800) != 0,
            clipboardSwitchKeyChar: UInt16((cbk >> 24) & 0xFF),
            
            checkUpdateOnStartup: settingsService.checkUpdateOnStartup,
            versionText: versionText
        )
    }
    
    func checkPermission() {
        let isOk = OpenKeyManager.isInited() || accessibilityService.isAccessibilityEnabled()
        presenter?.didUpdatePermissionStatus(isGranted: isOk)
    }
    
    func restartEventTap() -> Bool {
        let ok = OpenKeyManager.initEventTap()
        presenter?.didUpdatePermissionStatus(isGranted: ok)
        return ok
    }
    
    func updateGeneralSetting(_ updateBlock: (inout SettingsServiceProtocol) -> Void) {
        updateBlock(&settingsService)
        loadInitialData()
        (NSApplication.shared.delegate as? AppDelegate)?.fillData()
    }
    
    func testKeySound() {
        keySoundService.preview()
    }
    
    func clearClipboardHistory() {
        clipboardService.clearHistory()
    }
    
    func checkNewVersion(parentWindow: NSWindow?) {
        updateService.checkNewVersion(parent: parentWindow) { [weak self] hasUpdate, newVersion, _ in
            self?.presenter?.didCheckVersionResult(hasUpdate: hasUpdate, newVersion: newVersion, parentWindow: parentWindow)
        }
    }
}
