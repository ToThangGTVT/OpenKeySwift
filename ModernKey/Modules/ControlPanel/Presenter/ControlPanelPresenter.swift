//
//  ControlPanelPresenter.swift
//  ModernKey
//
//  VIPER Presenter for ControlPanel module.
//

import Cocoa

final class ControlPanelPresenter: ControlPanelPresenterProtocol {
    weak var view: ControlPanelViewProtocol?
    var interactor: ControlPanelInteractorInputProtocol?
    var router: ControlPanelRouterProtocol?
    
    func viewDidLoad() {
        interactor?.loadInitialData()
    }
    
    func viewWillAppear() {
        interactor?.checkPermission()
    }
    
    func didSelectTab(index: Int) {
        view?.showTab(index: index)
    }
    
    // MARK: - Primary Tab
    func didChangeInputType(index: Int) {
        interactor?.updateGeneralSetting { $0.inputType = Int32(index) }
    }
    
    func didChangeCodeTable(index: Int) {
        interactor?.updateGeneralSetting { $0.codeTable = Int32(index) }
    }
    
    func didToggleLanguage(isVietnamese: Bool) {
        interactor?.updateGeneralSetting { $0.language = isVietnamese ? 1 : 0 }
    }
    
    func didToggleFreeMark(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.freeMark = isOn }
    }
    
    func didToggleModernOrthography(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.modernOrthography = isOn }
    }
    
    func didToggleCheckSpelling(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.checkSpelling = isOn }
    }
    
    func didToggleQuickTelex(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.quickTelex = isOn }
    }
    
    func didToggleRestoreIfWrongSpelling(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.restoreIfWrongSpelling = isOn }
    }
    
    func didToggleFixRecommendBrowser(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.fixRecommendBrowser = isOn }
    }
    
    func didToggleAllowConsonantZFWJ(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.allowConsonantZFWJ = isOn }
    }
    
    func didToggleTempOffSpelling(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.tempOffSpelling = isOn }
    }
    
    func didToggleRunOnStartup(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.runOnStartup = isOn }
    }
    
    func didToggleShowUIOnStartup(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.showUIOnStartup = isOn }
    }
    
    func didToggleGrayIcon(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.grayIcon = isOn }
    }
    
    // MARK: - Switch Key
    func didToggleSwitchModifier(control: Bool, option: Bool, command: Bool, shift: Bool) {
        interactor?.updateGeneralSetting { settings in
            var current = settings.switchKeyStatus
            if current == 0 { current = 0x7A000206 }
            var sk = current & Int32(bitPattern: 0xFF0080FF) // keep char, beep, and keycode
            if control { sk |= 0x100 }
            if option { sk |= 0x200 }
            if command { sk |= 0x400 }
            if shift { sk |= 0x800 }
            settings.switchKeyStatus = sk
        }
    }
    
    func didChangeSwitchKey(keyCode: UInt16, character: UInt16) {
        interactor?.updateGeneralSetting { settings in
            var current = settings.switchKeyStatus
            if current == 0 { current = 0x7A000206 }
            var sk = current & 0x0000FF00 // keep modifiers & beep
            sk |= (Int32(character & 0xFF) << 24) | Int32(keyCode & 0xFF)
            settings.switchKeyStatus = sk
        }
    }
    
    func didToggleSwitchBeep(isOn: Bool) {
        interactor?.updateGeneralSetting { settings in
            var sk = settings.switchKeyStatus
            if sk == 0 { sk = 0x7A000206 }
            if isOn { sk |= 0x8000 } else { sk &= ~0x8000 }
            settings.switchKeyStatus = sk
        }
    }
    
    // MARK: - Macro Tab
    func didToggleUseMacro(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.useMacro = isOn }
    }
    
    func didToggleUseMacroInEnglishMode(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.useMacroInEnglishMode = isOn }
    }
    
    func didToggleAutoCapsMacro(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.autoCapsMacro = isOn }
    }
    
    // MARK: - System Tab
    func didToggleSendKeyStepByStep(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.sendKeyStepByStep = isOn }
    }
    
    func didToggleUseSmartSwitchKey(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.useSmartSwitchKey = isOn }
    }
    
    func didToggleUpperCaseFirstChar(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.upperCaseFirstChar = isOn }
    }
    
    func didToggleQuickStartConsonant(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.quickStartConsonant = isOn }
    }
    
    func didToggleQuickEndConsonant(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.quickEndConsonant = isOn }
    }
    
    func didToggleRememberCode(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.rememberCode = isOn }
    }
    
    func didToggleOtherLanguage(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.otherLanguage = isOn }
    }
    
    func didToggleTempOffOpenKey(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.tempOffOpenKey = isOn }
    }
    
    func didToggleShowIconOnDock(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.showIconOnDock = isOn }
    }
    
    func didToggleFixChromiumBrowser(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.fixChromiumBrowser = isOn }
    }
    
    func didTogglePerformLayoutCompat(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.performLayoutCompat = isOn }
    }
    
    // MARK: - Sound Tab
    func didToggleKeySound(isOn: Bool) {
        KeySoundService.shared.setEnabled(isOn)
        interactor?.loadInitialData()
    }
    
    func didChangeKeySoundVoice(index: Int) {
        KeySoundService.shared.setVoice(index: index)
        interactor?.loadInitialData()
    }
    
    func didChangeKeySoundVolume(volume: Int) {
        KeySoundService.shared.setVolume(volume)
        interactor?.loadInitialData()
    }
    
    func didToggleKeySoundOnlyVietnamese(isOn: Bool) {
        KeySoundService.shared.setOnlyVietnamese(isOn)
        interactor?.loadInitialData()
    }
    
    func didToggleKeySoundSpecialKeys(isOn: Bool) {
        KeySoundService.shared.setSpecialKeys(isOn)
        interactor?.loadInitialData()
    }
    
    func didToggleKeySoundRelease(isOn: Bool) {
        KeySoundService.shared.setReleaseSound(isOn)
        interactor?.loadInitialData()
    }
    
    func didTapTestSound() {
        interactor?.testKeySound()
    }
    
    // MARK: - Clipboard Tab
    func didToggleClipboard(isOn: Bool) {
        ClipboardService.shared.isEnabled = isOn
        interactor?.loadInitialData()
    }
    
    func didToggleClipboardAutoPaste(isOn: Bool) {
        ClipboardService.shared.isAutoPaste = isOn
        interactor?.loadInitialData()
    }
    
    func didChangeClipboardHistorySize(size: Int) {
        ClipboardService.shared.historySize = size
        interactor?.loadInitialData()
    }
    
    func didToggleClipboardSwitchModifier(control: Bool, option: Bool, command: Bool, shift: Bool) {
        let defaults = UserDefaults.standard
        var sk = defaults.integer(forKey: "ClipboardHotkeyData")
        if sk == 0 {
            sk = (118 << 24) | 0x09 | 0x400 | 0x800 // default Cmd+Shift+V
        }
        sk &= Int(bitPattern: 0xFF0000FF) // keep char and keyCode
        if control { sk |= 0x100 }
        if option { sk |= 0x200 }
        if command { sk |= 0x400 }
        if shift { sk |= 0x800 }
        defaults.set(sk, forKey: "ClipboardHotkeyData")
        clipboardHotKey = Int32(sk)
        interactor?.loadInitialData()
    }
    
    func didChangeClipboardSwitchKey(keyCode: UInt16, character: UInt16) {
        let defaults = UserDefaults.standard
        var sk = defaults.integer(forKey: "ClipboardHotkeyData")
        if sk == 0 {
            sk = 0x400 | 0x800 // Command + Shift
        }
        sk &= 0x0000FF00 // keep modifiers
        sk |= Int((UInt32(character & 0xFF) << 24) | UInt32(keyCode & 0xFF))
        defaults.set(sk, forKey: "ClipboardHotkeyData")
        clipboardHotKey = Int32(sk)
        interactor?.loadInitialData()
    }
    
    func didTapClearClipboardHistory() {
        interactor?.clearClipboardHistory()
    }
    
    // MARK: - Info Tab & Updates
    func didToggleCheckUpdateOnStartup(isOn: Bool) {
        interactor?.updateGeneralSetting { $0.checkUpdateOnStartup = isOn }
    }
    
    func didTapCheckNewVersion(window: NSWindow?) {
        view?.setCheckingUpdateState(isChecking: true)
        interactor?.checkNewVersion(parentWindow: window)
    }
    
    func didTapRetryPermission() {
        _ = interactor?.restartEventTap()
    }
    
    func didTapOpenMacroWindow() {
        router?.openMacroWindow()
    }
    
    func didTapOpenConvertToolWindow() {
        router?.openConvertToolWindow()
    }
    
    func didTapOpenAppInputModeWindow() {
        router?.openAppInputModeWindow()
    }
}

// MARK: - Interactor Output
extension ControlPanelPresenter: ControlPanelInteractorOutputProtocol {
    func didLoadState(_ state: GeneralSettingsState, inputTypes: [String], codeTables: [String], soundVoices: [String]) {
        view?.displayState(state, inputTypes: inputTypes, codeTables: codeTables, soundVoices: soundVoices)
    }
    
    func didUpdatePermissionStatus(isGranted: Bool) {
        view?.updatePermissionStatus(isGranted: isGranted)
    }
    
    func didCheckVersionResult(hasUpdate: Bool, newVersion: String, parentWindow: NSWindow?) {
        view?.setCheckingUpdateState(isChecking: false)
        router?.showUpdateAlert(needUpdating: hasUpdate, newVersion: newVersion, parentWindow: parentWindow) {
            UpdateService.shared.launchUpdateHelper()
        }
    }
}
