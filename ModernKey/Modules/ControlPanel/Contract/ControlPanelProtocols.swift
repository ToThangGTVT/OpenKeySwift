//
//  ControlPanelProtocols.swift
//  ModernKey
//
//  VIPER Protocols for ControlPanel module.
//

import Cocoa

// MARK: - View
protocol ControlPanelViewProtocol: AnyObject {
    func displayState(_ state: GeneralSettingsState, inputTypes: [String], codeTables: [String], soundVoices: [String])
    func updatePermissionStatus(isGranted: Bool)
    func showTab(index: Int)
    func setCheckingUpdateState(isChecking: Bool)
}

// MARK: - Presenter
protocol ControlPanelPresenterProtocol: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func didSelectTab(index: Int)
    
    // Primary Tab
    func didChangeInputType(index: Int)
    func didChangeCodeTable(index: Int)
    func didToggleLanguage(isVietnamese: Bool)
    func didToggleFreeMark(isOn: Bool)
    func didToggleModernOrthography(isOn: Bool)
    func didToggleCheckSpelling(isOn: Bool)
    func didToggleQuickTelex(isOn: Bool)
    func didToggleRestoreIfWrongSpelling(isOn: Bool)
    func didToggleFixRecommendBrowser(isOn: Bool)
    func didToggleAllowConsonantZFWJ(isOn: Bool)
    func didToggleTempOffSpelling(isOn: Bool)
    func didToggleRunOnStartup(isOn: Bool)
    func didToggleShowUIOnStartup(isOn: Bool)
    func didToggleGrayIcon(isOn: Bool)
    
    // Switch Key
    func didToggleSwitchModifier(control: Bool, option: Bool, command: Bool, shift: Bool)
    func didChangeSwitchKey(keyCode: UInt16, character: UInt16)
    func didToggleSwitchBeep(isOn: Bool)
    
    // Macro Tab
    func didToggleUseMacro(isOn: Bool)
    func didToggleUseMacroInEnglishMode(isOn: Bool)
    func didToggleAutoCapsMacro(isOn: Bool)
    
    // System Tab
    func didToggleSendKeyStepByStep(isOn: Bool)
    func didToggleUseSmartSwitchKey(isOn: Bool)
    func didToggleUpperCaseFirstChar(isOn: Bool)
    func didToggleQuickStartConsonant(isOn: Bool)
    func didToggleQuickEndConsonant(isOn: Bool)
    func didToggleRememberCode(isOn: Bool)
    func didToggleOtherLanguage(isOn: Bool)
    func didToggleTempOffOpenKey(isOn: Bool)
    func didToggleShowIconOnDock(isOn: Bool)
    func didToggleFixChromiumBrowser(isOn: Bool)
    func didTogglePerformLayoutCompat(isOn: Bool)
    
    // Sound Tab
    func didToggleKeySound(isOn: Bool)
    func didChangeKeySoundVoice(index: Int)
    func didChangeKeySoundVolume(volume: Int)
    func didToggleKeySoundOnlyVietnamese(isOn: Bool)
    func didToggleKeySoundSpecialKeys(isOn: Bool)
    func didToggleKeySoundRelease(isOn: Bool)
    func didTapTestSound()
    
    // Clipboard Tab
    func didToggleClipboard(isOn: Bool)
    func didToggleClipboardAutoPaste(isOn: Bool)
    func didChangeClipboardHistorySize(size: Int)
    func didToggleClipboardSwitchModifier(control: Bool, option: Bool, command: Bool, shift: Bool)
    func didChangeClipboardSwitchKey(keyCode: UInt16, character: UInt16)
    func didTapClearClipboardHistory()
    
    // Info Tab & Updates
    func didToggleCheckUpdateOnStartup(isOn: Bool)
    func didTapCheckNewVersion(window: NSWindow?)
    func didTapRetryPermission()
    func didTapOpenMacroWindow()
    func didTapOpenConvertToolWindow()
}

// MARK: - Interactor
protocol ControlPanelInteractorInputProtocol: AnyObject {
    func loadInitialData()
    func checkPermission()
    func restartEventTap() -> Bool
    func updateGeneralSetting(_ updateBlock: (inout SettingsServiceProtocol) -> Void)
    func testKeySound()
    func clearClipboardHistory()
    func checkNewVersion(parentWindow: NSWindow?)
}

protocol ControlPanelInteractorOutputProtocol: AnyObject {
    func didLoadState(_ state: GeneralSettingsState, inputTypes: [String], codeTables: [String], soundVoices: [String])
    func didUpdatePermissionStatus(isGranted: Bool)
    func didCheckVersionResult(hasUpdate: Bool, newVersion: String, parentWindow: NSWindow?)
}

// MARK: - Router
protocol ControlPanelRouterProtocol: AnyObject {
    func openMacroWindow()
    func openConvertToolWindow()
    func openAboutWindow()
    func showUpdateAlert(needUpdating: Bool, newVersion: String, parentWindow: NSWindow?, confirmUpdate: @escaping () -> Void)
}
