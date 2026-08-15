//
//  ViewController.swift
//  ModernKey
//
//  VIPER View for ControlPanel module.
//

import Cocoa

weak var viewController: ViewController?

@objc(ViewController)
class ViewController: NSViewController, ControlPanelViewProtocol, MyTextFieldDelegate {

    @IBOutlet weak var viewParent: NSView!
    @IBOutlet weak var tabSegment: NSSegmentedControl!
    @IBOutlet weak var tabContainer: NSView!

    @IBOutlet var tabviewPrimary: NSBox!
    @IBOutlet var tabviewMacro: NSBox!
    @IBOutlet var tabviewSystem: NSBox!
    @IBOutlet var tabviewSound: NSBox!
    @IBOutlet var tabviewClipboard: NSBox!
    @IBOutlet var tabviewInfo: NSBox!
    
    @IBOutlet weak var popupInputType: NSPopUpButton!
    @IBOutlet weak var popupCode: NSPopUpButton!
    
    @IBOutlet weak var appOK: NSBox!
    @IBOutlet weak var permissionWarning: NSBox!
    @IBOutlet weak var retryButton: NSButton!
    
    @IBOutlet weak var VietButton: NSButton!
    @IBOutlet weak var EngButton: NSButton!
    
    @IBOutlet weak var FreeMarkButton: NSButton!
    @IBOutlet weak var UseModernOrthography: NSButton!
    
    @IBOutlet weak var CheckSpellingButton: NSButton!
    
    @IBOutlet weak var RunOnStartupButton: NSButton!
    @IBOutlet weak var ShowUIButton: NSButton!
    
    @IBOutlet weak var UseGrayIcon: NSButton!
    @IBOutlet weak var QuickTelex: NSButton!
    
    @IBOutlet weak var RestoreIfInvalidWord: NSButton!
    @IBOutlet weak var FixRecommendBrowser: NSButton!
    @IBOutlet weak var AllowZWJF: NSButton!
    @IBOutlet weak var TempOffSpellChecking: NSButton!
    
    @IBOutlet weak var UseMacro: NSButton!
    @IBOutlet weak var UseMacroInEnglishMode: NSButton!
    
    @IBOutlet weak var SendKeyStepByStep: NSButton!
    @IBOutlet weak var AutoRememberSwitchKey: NSButton!
    @IBOutlet weak var UpperCaseFirstChar: NSButton!
    @IBOutlet weak var QuickStartConsonant: NSButton!
    @IBOutlet weak var QuickEndConsonant: NSButton!
    
    @IBOutlet weak var RememberTableCode: NSButton!
    @IBOutlet weak var OtherLanguage: NSButtonCell!
    
    @IBOutlet weak var TempOffOpenKey: NSButton!
    @IBOutlet weak var AutoCapsMacro: NSButton!
    @IBOutlet weak var ShowIconOnDock: NSButton!
    @IBOutlet weak var CheckNewVersionOnStartup: NSButton!
    @IBOutlet weak var FixChromiumBrowser: NSButton!
    @IBOutlet weak var PerformLayoutCompat: NSButton!
    
    @IBOutlet weak var CheckNewVersionButton: NSButton!
    @IBOutlet weak var VersionInfo: NSTextField!
    
    @IBOutlet weak var cursorImage: NSImageView!
    
    @IBOutlet weak var CustomSwitchCommand: NSButton!
    @IBOutlet weak var CustomSwitchOption: NSButton!
    @IBOutlet weak var CustomSwitchControl: NSButton!
    @IBOutlet weak var CustomSwitchShift: NSButton!
    @IBOutlet weak var CustomSwitchKey: MyTextField!
    @IBOutlet weak var CustomBeepSound: NSButton!

    @IBOutlet weak var KeySoundEnable: NSButton!
    @IBOutlet weak var KeySoundVoice: NSPopUpButton!
    @IBOutlet weak var KeySoundVoiceLabel: NSTextField!
    @IBOutlet weak var KeySoundTestButton: NSButton!
    @IBOutlet weak var KeySoundVolume: NSSlider!
    @IBOutlet weak var KeySoundVolumeLabel: NSTextField!
    @IBOutlet weak var KeySoundVolumeValue: NSTextField!
    @IBOutlet weak var KeySoundOnlyVietnamese: NSButton!
    @IBOutlet weak var KeySoundSpecialKeys: NSButton!
    @IBOutlet weak var KeySoundRelease: NSButton!

    @IBOutlet weak var ClipboardEnable: NSButton!
    @IBOutlet weak var ClipboardAutoPaste: NSButton!
    @IBOutlet weak var ClipboardHistorySize: NSPopUpButton!
    @IBOutlet weak var ClipboardSizeLabel: NSTextField!
    @IBOutlet weak var ClipboardHotkeyLabel: NSTextField!
    @IBOutlet weak var ClipboardSwitchControl: NSButton!
    @IBOutlet weak var ClipboardSwitchOption: NSButton!
    @IBOutlet weak var ClipboardSwitchCommand: NSButton!
    @IBOutlet weak var ClipboardSwitchShift: NSButton!
    @IBOutlet weak var ClipboardSwitchKey: MyTextField!
    @IBOutlet weak var ClipboardClearButton: NSButton!
    @IBOutlet weak var ClipboardHelpLabel: NSTextField!

    var presenter: ControlPanelPresenterProtocol?
    var tabviews: [NSBox] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        viewController = self
        CustomSwitchKey.parent = self
        ClipboardSwitchKey.parent = self
        
        tabviews = [tabviewPrimary, tabviewMacro, tabviewSystem, tabviewSound, tabviewClipboard, tabviewInfo]
        showTab(index: 0)
        
        if presenter == nil {
            _ = ControlPanelBuilder.setup(view: self)
        }
        presenter?.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        self.view.window?.title = "OpenKeySwift \(shortVersion) - Bộ gõ Tiếng Việt"
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        presenter?.viewWillAppear()
    }
    
    @objc func fillData() {
        presenter?.viewDidLoad()
    }

    // MARK: - ControlPanelViewProtocol
    func displayState(_ state: GeneralSettingsState, inputTypes: [String], codeTables: [String], soundVoices: [String]) {
        if popupInputType.numberOfItems != inputTypes.count {
            popupInputType.removeAllItems()
            popupInputType.addItems(withTitles: inputTypes)
        }
        if popupCode.numberOfItems != codeTables.count {
            popupCode.removeAllItems()
            popupCode.addItems(withTitles: codeTables)
        }
        if KeySoundVoice.numberOfItems != soundVoices.count {
            KeySoundVoice.removeAllItems()
            KeySoundVoice.addItems(withTitles: soundVoices)
        }
        
        popupInputType.selectItem(at: Int(state.inputType))
        popupCode.selectItem(at: Int(state.codeTable))
        
        VietButton.state = state.language == 1 ? .on : .off
        EngButton.state = state.language == 0 ? .on : .off
        
        FreeMarkButton.state = state.freeMark ? .on : .off
        UseModernOrthography.state = state.modernOrthography ? .on : .off
        CheckSpellingButton.state = state.checkSpelling ? .on : .off
        
        RestoreIfInvalidWord.isEnabled = state.checkSpelling
        AllowZWJF.isEnabled = state.checkSpelling
        TempOffSpellChecking.isEnabled = state.checkSpelling
        
        RestoreIfInvalidWord.state = state.restoreIfWrongSpelling ? .on : .off
        AllowZWJF.state = state.allowConsonantZFWJ ? .on : .off
        TempOffSpellChecking.state = state.tempOffSpelling ? .on : .off
        
        FixRecommendBrowser.state = state.fixRecommendBrowser ? .on : .off
        QuickTelex.state = state.quickTelex ? .on : .off
        
        RunOnStartupButton.state = state.runOnStartup ? .on : .off
        ShowUIButton.state = state.showUIOnStartup ? .on : .off
        UseGrayIcon.state = state.grayIcon ? .on : .off
        
        CustomSwitchCommand.state = state.switchCommand ? .on : .off
        CustomSwitchOption.state = state.switchOption ? .on : .off
        CustomSwitchControl.state = state.switchControl ? .on : .off
        CustomSwitchShift.state = state.switchShift ? .on : .off
        CustomSwitchKey.setTextByChar(state.switchKeyChar)
        CustomBeepSound.state = state.switchBeepSound ? .on : .off
        
        // Macro
        UseMacro.state = state.useMacro ? .on : .off
        UseMacroInEnglishMode.state = state.useMacroInEnglishMode ? .on : .off
        AutoCapsMacro.state = state.autoCapsMacro ? .on : .off
        
        // System
        SendKeyStepByStep.state = state.sendKeyStepByStep ? .on : .off
        AutoRememberSwitchKey.state = state.useSmartSwitchKey ? .on : .off
        UpperCaseFirstChar.state = state.upperCaseFirstChar ? .on : .off
        QuickStartConsonant.state = state.quickStartConsonant ? .on : .off
        QuickEndConsonant.state = state.quickEndConsonant ? .on : .off
        RememberTableCode.state = state.rememberCode ? .on : .off
        OtherLanguage.state = state.otherLanguage ? .on : .off
        TempOffOpenKey.state = state.tempOffOpenKey ? .on : .off
        ShowIconOnDock.state = state.showIconOnDock ? .on : .off
        FixChromiumBrowser.state = state.fixChromiumBrowser ? .on : .off
        PerformLayoutCompat.state = state.performLayoutCompat ? .on : .off
        
        // Sound
        KeySoundEnable.state = state.keySoundEnabled ? .on : .off
        KeySoundVoice.selectItem(at: min(state.keySoundVoice, soundVoices.count - 1))
        KeySoundVolume.integerValue = state.keySoundVolume
        KeySoundVolumeValue.stringValue = "\(state.keySoundVolume)%"
        KeySoundOnlyVietnamese.state = state.keySoundOnlyVietnamese ? .on : .off
        KeySoundSpecialKeys.state = state.keySoundSpecialKeys ? .on : .off
        KeySoundRelease.state = state.keySoundRelease ? .on : .off
        
        let soundOn = state.keySoundEnabled
        KeySoundVoice.isEnabled = soundOn
        KeySoundVoiceLabel.isEnabled = soundOn
        KeySoundTestButton.isEnabled = soundOn
        KeySoundVolume.isEnabled = soundOn
        KeySoundVolumeLabel.isEnabled = soundOn
        KeySoundVolumeValue.isEnabled = soundOn
        KeySoundOnlyVietnamese.isEnabled = soundOn
        KeySoundSpecialKeys.isEnabled = soundOn
        KeySoundRelease.isEnabled = soundOn
        
        // Clipboard
        ClipboardEnable.state = state.clipboardEnabled ? .on : .off
        ClipboardAutoPaste.state = state.clipboardAutoPaste ? .on : .off
        
        let sizes = [20, 50, 100, 200, 500]
        if let idx = sizes.firstIndex(of: state.clipboardHistorySize) {
            ClipboardHistorySize.selectItem(at: idx)
        }
        
        ClipboardSwitchControl.state = state.clipboardSwitchControl ? .on : .off
        ClipboardSwitchOption.state = state.clipboardSwitchOption ? .on : .off
        ClipboardSwitchCommand.state = state.clipboardSwitchCommand ? .on : .off
        ClipboardSwitchShift.state = state.clipboardSwitchShift ? .on : .off
        ClipboardSwitchKey.setTextByChar(state.clipboardSwitchKeyChar)
        
        let clipOn = state.clipboardEnabled
        ClipboardAutoPaste.isEnabled = clipOn
        ClipboardHistorySize.isEnabled = clipOn
        ClipboardSizeLabel.isEnabled = clipOn
        ClipboardHotkeyLabel.isEnabled = clipOn
        ClipboardSwitchControl.isEnabled = clipOn
        ClipboardSwitchOption.isEnabled = clipOn
        ClipboardSwitchCommand.isEnabled = clipOn
        ClipboardSwitchShift.isEnabled = clipOn
        ClipboardSwitchKey.isEnabled = clipOn
        ClipboardClearButton.isEnabled = clipOn
        ClipboardHelpLabel.isEnabled = clipOn
        
        // Info
        CheckNewVersionOnStartup.state = state.checkUpdateOnStartup ? .on : .off
        VersionInfo.stringValue = state.versionText
    }
    
    func updatePermissionStatus(isGranted: Bool) {
        appOK.isHidden = true
        permissionWarning.isHidden = isGranted
        retryButton.isEnabled = !isGranted
    }
    
    func showTab(index: Int) {
        guard tabviews.indices.contains(index) else { return }
        let page = tabviews[index]
        if page.superview !== tabContainer {
            tabContainer.subviews.forEach { $0.removeFromSuperview() }
            page.isHidden = false
            page.frame = tabContainer.bounds
            page.autoresizingMask = [.width, .height]
            tabContainer.addSubview(page)
        }
        tabSegment?.selectedSegment = index
    }
    
    func setCheckingUpdateState(isChecking: Bool) {
        CheckNewVersionButton?.isEnabled = !isChecking
        CheckNewVersionButton?.title = isChecking ? "Đang kiểm tra..." : "Kiểm tra bản mới..."
    }

    // MARK: - IBAction Methods matching ViewController.xib
    @IBAction func onTabSegment(_ sender: NSSegmentedControl) {
        presenter?.didSelectTab(index: sender.selectedSegment)
    }
    
    @IBAction func onInputTypeChanged(_ sender: NSPopUpButton) {
        presenter?.didChangeInputType(index: sender.indexOfSelectedItem)
    }
    
    @IBAction func onCodeTableChanged(_ sender: NSPopUpButton) {
        presenter?.didChangeCodeTable(index: sender.indexOfSelectedItem)
    }
    
    @IBAction func onLanguageChanged(_ sender: Any) {
        presenter?.didToggleLanguage(isVietnamese: VietButton.state == .on)
    }
    
    @IBAction func onRestart(_ sender: Any) {
        presenter?.didTapRetryPermission()
    }
    
    @IBAction func onFreeMark(_ sender: NSButton) {
        presenter?.didToggleFreeMark(isOn: sender.state == .on)
    }
    
    @IBAction func onModernOrthography(_ sender: NSButton) {
        presenter?.didToggleModernOrthography(isOn: sender.state == .on)
    }
    
    @IBAction func onCheckSpelling(_ sender: NSButton) {
        presenter?.didToggleCheckSpelling(isOn: sender.state == .on)
    }
    
    @IBAction func onShowUIOnStartup(_ sender: NSButton) {
        presenter?.didToggleShowUIOnStartup(isOn: sender.state == .on)
    }
    
    @IBAction func onRunOnStartup(_ sender: NSButton) {
        presenter?.didToggleRunOnStartup(isOn: sender.state == .on)
    }
    
    @IBAction func onGrayIcon(_ sender: Any) {
        presenter?.didToggleGrayIcon(isOn: UseGrayIcon.state == .on)
    }
    
    @IBAction func onQuickTelex(_ sender: Any) {
        presenter?.didToggleQuickTelex(isOn: QuickTelex.state == .on)
    }
    
    @IBAction func onRestoreIfInvalidWord(_ sender: Any) {
        presenter?.didToggleRestoreIfWrongSpelling(isOn: RestoreIfInvalidWord.state == .on)
    }
    
    @IBAction func omTempOffSpellChecking(_ sender: Any) {
        presenter?.didToggleTempOffSpelling(isOn: TempOffSpellChecking.state == .on)
    }
    
    @IBAction func onFixRecommendBrowser(_ sender: Any) {
        presenter?.didToggleFixRecommendBrowser(isOn: FixRecommendBrowser.state == .on)
    }
    
    @IBAction func onAllowZFWJ(_ sender: Any) {
        presenter?.didToggleAllowConsonantZFWJ(isOn: AllowZWJF.state == .on)
    }
    
    private func updateSwitchModifiers() {
        presenter?.didToggleSwitchModifier(
            control: CustomSwitchControl.state == .on,
            option: CustomSwitchOption.state == .on,
            command: CustomSwitchCommand.state == .on,
            shift: CustomSwitchShift.state == .on
        )
    }
    
    @IBAction func onControlSwitchKey(_ sender: NSButton) { updateSwitchModifiers() }
    @IBAction func onOptionSwitchKey(_ sender: NSButton) { updateSwitchModifiers() }
    @IBAction func onCommandSwitchKey(_ sender: NSButton) { updateSwitchModifiers() }
    @IBAction func onShiftSwitchKey(_ sender: NSButton) { updateSwitchModifiers() }
    @IBAction func onBeepSound(_ sender: NSButton) {
        presenter?.didToggleSwitchBeep(isOn: sender.state == .on)
    }
    
    // Macro actions
    @IBAction func onMacroChanged(_ sender: Any) {
        presenter?.didToggleUseMacro(isOn: UseMacro.state == .on)
    }
    
    @IBAction func onUseMacroInEnglishModeChanged(_ sender: Any) {
        presenter?.didToggleUseMacroInEnglishMode(isOn: UseMacroInEnglishMode.state == .on)
    }
    
    @IBAction func onAutoCapsMacro(_ sender: NSButton) {
        presenter?.didToggleAutoCapsMacro(isOn: sender.state == .on)
    }
    
    @IBAction func onMacroButton(_ sender: Any) {
        presenter?.didTapOpenMacroWindow()
    }
    
    // System actions
    @IBAction func onSendKeyStepByStep(_ sender: Any) {
        presenter?.didToggleSendKeyStepByStep(isOn: SendKeyStepByStep.state == .on)
    }
    
    @IBAction func onAutoRememberSwitchKey(_ sender: Any) {
        presenter?.didToggleUseSmartSwitchKey(isOn: AutoRememberSwitchKey.state == .on)
    }
    
    @IBAction func onUpperCaseFirstChar(_ sender: Any) {
        presenter?.didToggleUpperCaseFirstChar(isOn: UpperCaseFirstChar.state == .on)
    }
    
    @IBAction func onQuickStartConsonant(_ sender: Any) {
        presenter?.didToggleQuickStartConsonant(isOn: QuickStartConsonant.state == .on)
    }
    
    @IBAction func onQuickEndConsonant(_ sender: Any) {
        presenter?.didToggleQuickEndConsonant(isOn: QuickEndConsonant.state == .on)
    }
    
    @IBAction func onRememberTableCode(_ sender: Any) {
        presenter?.didToggleRememberCode(isOn: RememberTableCode.state == .on)
    }
    
    @IBAction func onOtherLanguage(_ sender: Any) {
        presenter?.didToggleOtherLanguage(isOn: OtherLanguage.state == .on)
    }
    
    @IBAction func onTempOffOpenKeyByHotKey(_ sender: Any) {
        presenter?.didToggleTempOffOpenKey(isOn: TempOffOpenKey.state == .on)
    }
    
    @IBAction func onShowIconOnDock(_ sender: Any) {
        presenter?.didToggleShowIconOnDock(isOn: ShowIconOnDock.state == .on)
    }
    
    @IBAction func onFixChromiumBrowser(_ sender: Any) {
        presenter?.didToggleFixChromiumBrowser(isOn: FixChromiumBrowser.state == .on)
    }
    
    @IBAction func onPerformLayoutCompat(_ sender: Any) {
        presenter?.didTogglePerformLayoutCompat(isOn: PerformLayoutCompat.state == .on)
    }
    
    // Sound actions
    @IBAction func onKeySoundEnable(_ sender: NSButton) {
        presenter?.didToggleKeySound(isOn: sender.state == .on)
    }
    
    @IBAction func onKeySoundVoiceChanged(_ sender: NSPopUpButton) {
        presenter?.didChangeKeySoundVoice(index: sender.indexOfSelectedItem)
    }
    
    @IBAction func onKeySoundTest(_ sender: NSButton) {
        presenter?.didTapTestSound()
    }
    
    @IBAction func onKeySoundVolume(_ sender: NSSlider) {
        presenter?.didChangeKeySoundVolume(volume: sender.integerValue)
    }
    
    @IBAction func onKeySoundOnlyVietnamese(_ sender: NSButton) {
        presenter?.didToggleKeySoundOnlyVietnamese(isOn: sender.state == .on)
    }
    
    @IBAction func onKeySoundSpecialKeys(_ sender: NSButton) {
        presenter?.didToggleKeySoundSpecialKeys(isOn: sender.state == .on)
    }
    
    @IBAction func onKeySoundRelease(_ sender: NSButton) {
        presenter?.didToggleKeySoundRelease(isOn: sender.state == .on)
    }
    
    // Clipboard actions
    @IBAction func onClipboardEnable(_ sender: NSButton) {
        presenter?.didToggleClipboard(isOn: sender.state == .on)
    }
    
    @IBAction func onClipboardAutoPaste(_ sender: NSButton) {
        presenter?.didToggleClipboardAutoPaste(isOn: sender.state == .on)
    }
    
    @IBAction func onClipboardHistorySize(_ sender: NSPopUpButton) {
        let sizes = [20, 50, 100, 200, 500]
        let idx = sender.indexOfSelectedItem
        if sizes.indices.contains(idx) {
            presenter?.didChangeClipboardHistorySize(size: sizes[idx])
        }
    }
    
    private func updateClipboardModifiers() {
        presenter?.didToggleClipboardSwitchModifier(
            control: ClipboardSwitchControl.state == .on,
            option: ClipboardSwitchOption.state == .on,
            command: ClipboardSwitchCommand.state == .on,
            shift: ClipboardSwitchShift.state == .on
        )
    }
    
    @IBAction func onClipboardControlSwitchKey(_ sender: NSButton) { updateClipboardModifiers() }
    @IBAction func onClipboardOptionSwitchKey(_ sender: NSButton) { updateClipboardModifiers() }
    @IBAction func onClipboardCommandSwitchKey(_ sender: NSButton) { updateClipboardModifiers() }
    @IBAction func onClipboardShiftSwitchKey(_ sender: NSButton) { updateClipboardModifiers() }
    
    @IBAction func onClipboardClearHistory(_ sender: NSButton) {
        presenter?.didTapClearClipboardHistory()
    }
    
    // Info actions
    @IBAction func onCheckNewVersionOnStartup(_ sender: NSButton) {
        presenter?.didToggleCheckUpdateOnStartup(isOn: sender.state == .on)
    }
    
    @IBAction func onCheckNewVersionButton(_ sender: Any) {
        presenter?.didTapCheckNewVersion(window: self.view.window)
    }
    
    @IBAction func onSourceCode(_ sender: Any) {
        if let url = URL(string: "https://github.com/ToThangGTVT/OpenKeySwift") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func onHomePage(_ sender: Any) {
        if let url = URL(string: "https://github.com/ToThangGTVT/OpenKeySwift") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func onFanPage(_ sender: Any) {
        if let url = URL(string: "https://www.facebook.com/OpenKeyVN") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func onLatestReleaseVersion(_ sender: Any) {
        if let url = URL(string: "https://github.com/ToThangGTVT/OpenKeySwift/releases") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func onDefaultConfig(_ sender: Any) {
        SettingsService.shared.loadDefaultConfig()
        fillData()
    }
    
    @IBAction func onOK(_ sender: Any) {
        self.view.window?.close()
    }
    
    @IBAction func onTerminateApp(_ sender: Any) {
        NSApp.terminate(sender)
    }
    
    @IBAction func onClose(_ sender: Any) {
        self.view.window?.close()
    }
    
    // MARK: - MyTextFieldDelegate
    func myTextField(_ field: MyTextField, didChangeKeyCode keyCode: UInt16, character: UInt16) {
        if field === CustomSwitchKey {
            presenter?.didChangeSwitchKey(keyCode: keyCode, character: character)
        } else if field === ClipboardSwitchKey {
            presenter?.didChangeClipboardSwitchKey(keyCode: keyCode, character: character)
        }
    }
    
    func onMyTextFieldKeyChange(_ keyCode: UInt16, character: UInt16) {
        presenter?.didChangeSwitchKey(keyCode: keyCode, character: character)
    }
}

// MARK: - Module Builder
enum ControlPanelBuilder {
    static func build() -> ViewController {
        let view = ViewController(nibName: "ViewController", bundle: nil)
        return setup(view: view)
    }
    
    @discardableResult
    static func setup(view: ViewController) -> ViewController {
        let presenter = ControlPanelPresenter()
        let interactor = ControlPanelInteractor()
        let router = ControlPanelRouter()

        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        return view
    }
}
