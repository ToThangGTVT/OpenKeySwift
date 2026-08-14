import Cocoa

/// Global reference used by AppDelegate / the engine callbacks to refresh the panel.
weak var viewController: ViewController?

@objc(ViewController)
class ViewController: NSViewController, MyTextFieldDelegate {

    @IBOutlet weak var viewParent: NSView!
    @IBOutlet weak var tabbuttonPrimary: NSButton!
    @IBOutlet weak var tabbuttonMacro: NSButton!
    @IBOutlet weak var tabbuttonSystem: NSButton!
    @IBOutlet weak var tabbuttonSound: NSButton!
    @IBOutlet weak var tabbuttonInfo: NSButton!
    @IBOutlet weak var tabviewPrimary: NSBox!
    @IBOutlet weak var tabviewMacro: NSBox!
    @IBOutlet weak var tabviewSystem: NSBox!
    @IBOutlet weak var tabviewSound: NSBox!
    @IBOutlet weak var tabviewInfo: NSBox!
    
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

    var tabviews: [NSBox] = []
    var tabbuttons: [NSButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        viewController = self
        CustomSwitchKey.parent = self
        appOK.isHidden = true
        permissionWarning.isHidden = true
        retryButton.isEnabled = false

        tabviews = [tabviewPrimary, tabviewMacro, tabviewSystem, tabviewSound, tabviewInfo]
        tabbuttons = [tabbuttonPrimary, tabbuttonMacro, tabbuttonSystem, tabbuttonSound, tabbuttonInfo]

        showTab(0)

        let inputTypeData = ["Telex", "VNI", "Simple Telex 1", "Simple Telex 2"]
        let codeData = OpenKeyManager.getTableCodes()

        popupInputType.removeAllItems()
        popupInputType.addItems(withTitles: inputTypeData)

        popupCode.removeAllItems()
        popupCode.addItems(withTitles: codeData)

        KeySoundVoice.removeAllItems()
        KeySoundVoice.addItems(withTitles: KeySoundPlayer.voices.map { $0.name })

        initKey()
        fillData()
        
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        VersionInfo.stringValue = "Phiên bản \(shortVersion) (build \(version)) - Ngày cập nhật \(OpenKeyManager.getBuildDate())"
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        self.view.window?.title = "OpenKey \(shortVersion) - Bộ gõ Tiếng Việt"
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        initKey()
    }
    
    func initKey() {
        DispatchQueue.main.async {
            if !OpenKeyManager.initEventTap() {
                // self.permissionWarning.isHidden = false
                // self.retryButton.isEnabled = true
            } else {
                // self.appOK.isHidden = false
            }
        }
    }
    
    /// The tab pages all share the same frame; only the selected one is visible.
    func showTab(_ index: Int) {
        for (i, box) in tabviews.enumerated() {
            box.isHidden = (i != index)
        }
        for (i, button) in tabbuttons.enumerated() {
            button.state = (i == index) ? .on : .off
        }
    }
    
    @IBAction func onTabButton(_ sender: NSButton) {
        showTab(sender.tag)
    }
    
    @IBAction func onInputTypeChanged(_ sender: NSPopUpButton) {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.onInputTypeSelectedIndex(Int32(popupInputType.indexOfSelectedItem))
        }
    }
    
    @IBAction func onCodeTableChanged(_ sender: NSPopUpButton) {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.onCodeTableChanged(Int32(popupCode.indexOfSelectedItem))
        }
    }
    
    @IBAction func onLanguageChanged(_ sender: Any) {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.onInputMethodSelected()
        }
    }
    
    @IBAction func onRestart(_ sender: Any) {
        appOK.isHidden = true
        permissionWarning.isHidden = true
        retryButton.isEnabled = false
        initKey()
    }
    
    @IBAction func onFreeMark(_ sender: NSButton) {
        vFreeMark = Int32(setCustomValue(sender, keyToSet: "FreeMark"))
    }
    
    @IBAction func onModernOrthography(_ sender: NSButton) {
        vUseModernOrthography = Int32(setCustomValue(sender, keyToSet: "ModernOrthography"))
    }
    
    @IBAction func onCheckSpelling(_ sender: NSButton) {
        let val = setCustomValue(sender, keyToSet: "Spelling")
        vCheckSpelling = Int32(val)
        let isEnabled = val != 0
        RestoreIfInvalidWord.isEnabled = isEnabled
        AllowZWJF.isEnabled = isEnabled
        TempOffSpellChecking.isEnabled = isEnabled
        OnSpellCheckingChanged()
    }
    
    @IBAction func onShowUIOnStartup(_ sender: NSButton) {
        _ = setCustomValue(sender, keyToSet: "ShowUIOnStartup")
    }
    
    @IBAction func onRunOnStartup(_ sender: NSButton) {
        let val = setCustomValue(sender, keyToSet: "RunOnStartup")
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setRunOnStartup(val != 0)
        }
    }
    
    @IBAction func onGrayIcon(_ sender: Any) {
        let val = setCustomValue(sender as? NSButton, keyToSet: "GrayIcon")
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setGrayIcon(val != 0)
        }
    }
    
    @IBAction func onQuickTelex(_ sender: Any) {
        vQuickTelex = Int32(setCustomValue(sender as? NSButton, keyToSet: "QuickTelex"))
    }
    
    @IBAction func onRestoreIfInvalidWord(_ sender: Any) {
        vRestoreIfWrongSpelling = Int32(setCustomValue(sender as? NSButton, keyToSet: "RestoreIfInvalidWord"))
    }
    
    @IBAction func omTempOffSpellChecking(_ sender: Any) {
        vTempOffSpelling = Int32(setCustomValue(sender as? NSButton, keyToSet: "vTempOffSpelling"))
    }
    
    @IBAction func onAllowZFWJ(_ sender: Any) {
        vAllowConsonantZFWJ = Int32(setCustomValue(sender as? NSButton, keyToSet: "vAllowConsonantZFWJ"))
    }
    
    @IBAction func onFixRecommendBrowser(_ sender: Any) {
        let val = setCustomValue(sender as? NSButton, keyToSet: "FixRecommendBrowser")
        vFixRecommendBrowser = Int32(val)
        FixChromiumBrowser.isEnabled = val != 0
    }
    
    @IBAction func onControlSwitchKey(_ sender: NSButton) {
        let val = setCustomValue(sender, keyToSet: nil)
        vSwitchKeyStatus &= ~0x100
        vSwitchKeyStatus |= Int32(val) << 8
        UserDefaults.standard.set(vSwitchKeyStatus, forKey: "SwitchKeyStatus")
    }
    
    @IBAction func onOptionSwitchKey(_ sender: NSButton) {
        let val = setCustomValue(sender, keyToSet: nil)
        vSwitchKeyStatus &= ~0x200
        vSwitchKeyStatus |= Int32(val) << 9
        UserDefaults.standard.set(vSwitchKeyStatus, forKey: "SwitchKeyStatus")
    }
    
    @IBAction func onCommandSwitchKey(_ sender: NSButton) {
        let val = setCustomValue(sender, keyToSet: nil)
        vSwitchKeyStatus &= ~0x400
        vSwitchKeyStatus |= Int32(val) << 10
        UserDefaults.standard.set(vSwitchKeyStatus, forKey: "SwitchKeyStatus")
    }
    
    @IBAction func onShiftSwitchKey(_ sender: NSButton) {
        let val = setCustomValue(sender, keyToSet: nil)
        vSwitchKeyStatus &= ~0x800
        vSwitchKeyStatus |= Int32(val) << 11
        UserDefaults.standard.set(vSwitchKeyStatus, forKey: "SwitchKeyStatus")
    }
    
    func onMyTextFieldKeyChange(_ keyCode: UInt16, character: UInt16) {
        vSwitchKeyStatus &= ~0xFF
        vSwitchKeyStatus |= Int32(keyCode)
        vSwitchKeyStatus &= 0x00FFFFFF
        vSwitchKeyStatus |= (Int32(character) << 24)
        UserDefaults.standard.set(vSwitchKeyStatus, forKey: "SwitchKeyStatus")
    }
    
    @IBAction func onBeepSound(_ sender: NSButton) {
        let val = setCustomValue(sender, keyToSet: nil)
        vSwitchKeyStatus &= ~0x8000
        vSwitchKeyStatus |= Int32(val) << 15
        UserDefaults.standard.set(vSwitchKeyStatus, forKey: "SwitchKeyStatus")
    }
    
    // MARK: - Keystroke sound

    /// Greys out the sound settings while the feature is off.
    private func updateKeySoundControls() {
        let on = vKeySound != 0
        KeySoundVoice?.isEnabled = on
        KeySoundVoiceLabel?.isEnabled = on
        KeySoundTestButton?.isEnabled = on
        KeySoundVolume?.isEnabled = on
        KeySoundVolumeLabel?.isEnabled = on
        KeySoundVolumeValue?.isEnabled = on
        KeySoundOnlyVietnamese?.isEnabled = on
        KeySoundSpecialKeys?.isEnabled = on
    }

    @IBAction func onKeySoundEnable(_ sender: NSButton) {
        vKeySound = Int32(setCustomValue(sender, keyToSet: "vKeySound"))
        updateKeySoundControls()
        KeySoundPlayer.shared.applySettings()
        if vKeySound != 0 {
            KeySoundPlayer.shared.preview()
        }
    }

    @IBAction func onKeySoundVoiceChanged(_ sender: NSPopUpButton) {
        vKeySoundVoice = Int32(sender.indexOfSelectedItem)
        UserDefaults.standard.set(vKeySoundVoice, forKey: "vKeySoundVoice")
        KeySoundPlayer.shared.preview()
    }

    @IBAction func onKeySoundVolume(_ sender: NSSlider) {
        vKeySoundVolume = Int32(sender.intValue)
        UserDefaults.standard.set(vKeySoundVolume, forKey: "vKeySoundVolume")
        KeySoundVolumeValue.stringValue = "\(vKeySoundVolume)%"
        KeySoundPlayer.shared.applySettings()
        // Only audition on mouse-up, otherwise dragging the slider machine-guns notes.
        if NSApp.currentEvent?.type == .leftMouseUp {
            KeySoundPlayer.shared.preview()
        }
    }

    @IBAction func onKeySoundTest(_ sender: Any) {
        KeySoundPlayer.shared.preview()
    }

    @IBAction func onKeySoundOnlyVietnamese(_ sender: NSButton) {
        vKeySoundOnlyVietnamese = Int32(setCustomValue(sender, keyToSet: "vKeySoundOnlyVietnamese"))
    }

    @IBAction func onKeySoundSpecialKeys(_ sender: NSButton) {
        vKeySoundSpecialKeys = Int32(setCustomValue(sender, keyToSet: "vKeySoundSpecialKeys"))
    }

    @IBAction func onSendKeyStepByStep(_ sender: Any) {
        vSendKeyStepByStep = Int32(setCustomValue(sender as? NSButton, keyToSet: "SendKeyStepByStep"))
    }
    
    @IBAction func onPerformLayoutCompat(_ sender: Any) {
        vPerformLayoutCompat = Int32(setCustomValue(sender as? NSButton, keyToSet: "vPerformLayoutCompat"))
    }
    
    func setCustomValue(_ sender: NSButton?, keyToSet: String?) -> Int {
        guard let button = sender else { return 0 }
        let val = button.state == .on ? 1 : 0
        if let key = keyToSet {
            UserDefaults.standard.set(val, forKey: key)
        }
        return val
    }
    
    @IBAction func onMacroButton(_ sender: Any) {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.onMacroSelected()
        }
    }
    
    @IBAction func onMacroChanged(_ sender: NSButton) {
        vUseMacro = Int32(setCustomValue(sender, keyToSet: "UseMacro"))
    }
    
    @IBAction func onUseMacroInEnglishModeChanged(_ sender: NSButton) {
        vUseMacroInEnglishMode = Int32(setCustomValue(sender, keyToSet: "UseMacroInEnglishMode"))
    }
    
    @IBAction func onAutoRememberSwitchKey(_ sender: NSButton) {
        vUseSmartSwitchKey = Int32(setCustomValue(sender, keyToSet: "UseSmartSwitchKey"))
    }
    
    @IBAction func onUpperCaseFirstChar(_ sender: NSButton) {
        vUpperCaseFirstChar = Int32(setCustomValue(sender, keyToSet: "UpperCaseFirstChar"))
    }
    
    @IBAction func onQuickStartConsonant(_ sender: Any) {
        vQuickStartConsonant = Int32(setCustomValue(sender as? NSButton, keyToSet: "vQuickStartConsonant"))
    }
    
    @IBAction func onQuickEndConsonant(_ sender: Any) {
        vQuickEndConsonant = Int32(setCustomValue(sender as? NSButton, keyToSet: "vQuickEndConsonant"))
    }
    
    @IBAction func onTempOffOpenKeyByHotKey(_ sender: Any) {
        vTempOffOpenKey = Int32(setCustomValue(sender as? NSButton, keyToSet: "vTempOffOpenKey"))
    }
    
    @IBAction func onRememberTableCode(_ sender: Any) {
        vRememberCode = Int32(setCustomValue(sender as? NSButton, keyToSet: "vRememberCode"))
    }
    
    @IBAction func onOtherLanguage(_ sender: Any) {
        vOtherLanguage = Int32(setCustomValue(sender as? NSButton, keyToSet: "vOtherLanguage"))
    }
    
    @IBAction func onAutoCapsMacro(_ sender: Any) {
        vAutoCapsMacro = Int32(setCustomValue(sender as? NSButton, keyToSet: "vAutoCapsMacro"))
    }
    
    @IBAction func onShowIconOnDock(_ sender: Any) {
        vShowIconOnDock = Int32(setCustomValue(sender as? NSButton, keyToSet: "vShowIconOnDock"))
        if vShowIconOnDock == 0 {
            self.view.window?.close()
        }
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.showIconOnDock(vShowIconOnDock != 0)
        }
    }
    
    @IBAction func onCheckNewVersionOnStartup(_ sender: NSButton) {
        let val = sender.state == .on ? 0 : 1
        UserDefaults.standard.set(val, forKey: "DontCheckUpdate")
    }
    
    @IBAction func onFixChromiumBrowser(_ sender: NSButton) {
        vFixChromiumBrowser = Int32(setCustomValue(sender, keyToSet: "vFixChromiumBrowser"))
    }
    
    @IBAction func onTerminateApp(_ sender: Any) {
        NSApp.terminate(nil)
    }
    
    func fillData() {
        let intInputMethod = UserDefaults.standard.integer(forKey: "InputMethod")
        if intInputMethod == 1 {
            VietButton?.state = .on
        } else if intInputMethod == 0 {
            EngButton?.state = .on
        }
        
        let intInputType = UserDefaults.standard.integer(forKey: "InputType")
        popupInputType?.selectItem(at: intInputType)
        
        let intCodeTable = UserDefaults.standard.integer(forKey: "CodeTable")
        popupCode?.selectItem(at: intCodeTable)
        
        let showui = UserDefaults.standard.integer(forKey: "ShowUIOnStartup")
        ShowUIButton?.state = showui != 0 ? .on : .off
        
        let freeMark = UserDefaults.standard.integer(forKey: "FreeMark")
        FreeMarkButton?.state = freeMark != 0 ? .on : .off
        
        let useModernOrthography = UserDefaults.standard.integer(forKey: "ModernOrthography")
        UseModernOrthography?.state = useModernOrthography != 0 ? .on : .off
        
        let spelling = UserDefaults.standard.integer(forKey: "Spelling")
        CheckSpellingButton?.state = spelling != 0 ? .on : .off
        
        let runOnStartup = UserDefaults.standard.integer(forKey: "RunOnStartup")
        RunOnStartupButton?.state = runOnStartup != 0 ? .on : .off
        
        let useGrayIcon = UserDefaults.standard.integer(forKey: "GrayIcon")
        UseGrayIcon?.state = useGrayIcon != 0 ? .on : .off
        
        let quickTelex = UserDefaults.standard.integer(forKey: "QuickTelex")
        QuickTelex?.state = quickTelex != 0 ? .on : .off
        
        let restoreIfInvalidWord = UserDefaults.standard.integer(forKey: "RestoreIfInvalidWord")
        RestoreIfInvalidWord?.state = restoreIfInvalidWord != 0 ? .on : .off
        RestoreIfInvalidWord?.isEnabled = spelling != 0
        
        let tempOffSpelling = UserDefaults.standard.integer(forKey: "vTempOffSpelling")
        TempOffSpellChecking?.state = tempOffSpelling != 0 ? .on : .off
        TempOffSpellChecking?.isEnabled = spelling != 0
        
        let allowZFWJ = UserDefaults.standard.integer(forKey: "vAllowConsonantZFWJ")
        AllowZWJF?.state = allowZFWJ != 0 ? .on : .off
        AllowZWJF?.isEnabled = spelling != 0
        
        let fixRecommendBrowser = UserDefaults.standard.integer(forKey: "FixRecommendBrowser")
        FixRecommendBrowser?.state = fixRecommendBrowser != 0 ? .on : .off
        
        let useMacro = UserDefaults.standard.integer(forKey: "UseMacro")
        UseMacro?.state = useMacro != 0 ? .on : .off
        
        let useMacroInEnglish = UserDefaults.standard.integer(forKey: "UseMacroInEnglishMode")
        UseMacroInEnglishMode?.state = useMacroInEnglish != 0 ? .on : .off
        
        let sendKeySbS = UserDefaults.standard.integer(forKey: "SendKeyStepByStep")
        SendKeyStepByStep?.state = sendKeySbS != 0 ? .on : .off
        
        let useSmartSwitchKey = UserDefaults.standard.integer(forKey: "UseSmartSwitchKey")
        AutoRememberSwitchKey?.state = useSmartSwitchKey != 0 ? .on : .off
        
        let upperCaseFirstChar = UserDefaults.standard.integer(forKey: "UpperCaseFirstChar")
        UpperCaseFirstChar?.state = upperCaseFirstChar != 0 ? .on : .off
        
        let quickStartConsonant = UserDefaults.standard.integer(forKey: "vQuickStartConsonant")
        QuickStartConsonant?.state = quickStartConsonant != 0 ? .on : .off
        
        let quickEndConsonant = UserDefaults.standard.integer(forKey: "vQuickEndConsonant")
        QuickEndConsonant?.state = quickEndConsonant != 0 ? .on : .off
        
        let rememberCode = UserDefaults.standard.integer(forKey: "vRememberCode")
        RememberTableCode?.state = rememberCode != 0 ? .on : .off
        
        let otherLanguage = UserDefaults.standard.integer(forKey: "vOtherLanguage")
        OtherLanguage?.state = otherLanguage != 0 ? .on : .off
        
        let tempOffOpenKey = UserDefaults.standard.integer(forKey: "vTempOffOpenKey")
        TempOffOpenKey?.state = tempOffOpenKey != 0 ? .on : .off
        
        let autoCapsMacro = UserDefaults.standard.integer(forKey: "vAutoCapsMacro")
        AutoCapsMacro?.state = autoCapsMacro != 0 ? .on : .off
        
        let showIconOnDock = UserDefaults.standard.integer(forKey: "vShowIconOnDock")
        ShowIconOnDock?.state = showIconOnDock != 0 ? .on : .off
        
        let dontCheckUpdate = UserDefaults.standard.integer(forKey: "DontCheckUpdate")
        CheckNewVersionOnStartup?.state = dontCheckUpdate != 0 ? .off : .on
        
        let fixChromiumBrowser = UserDefaults.standard.integer(forKey: "vFixChromiumBrowser")
        FixChromiumBrowser?.state = fixChromiumBrowser != 0 ? .on : .off
        FixChromiumBrowser?.isEnabled = fixRecommendBrowser != 0
        
        let performLayoutCompat = UserDefaults.standard.integer(forKey: "vPerformLayoutCompat")
        PerformLayoutCompat?.state = performLayoutCompat != 0 ? .on : .off
        
        KeySoundEnable?.state = vKeySound != 0 ? .on : .off
        KeySoundVoice?.selectItem(at: max(0, min(KeySoundPlayer.voices.count - 1, Int(vKeySoundVoice))))
        KeySoundVolume?.intValue = Int32(vKeySoundVolume)
        KeySoundVolumeValue?.stringValue = "\(vKeySoundVolume)%"
        KeySoundOnlyVietnamese?.state = vKeySoundOnlyVietnamese != 0 ? .on : .off
        KeySoundSpecialKeys?.state = vKeySoundSpecialKeys != 0 ? .on : .off
        updateKeySoundControls()

        CustomSwitchControl?.state = (vSwitchKeyStatus & 0x100) != 0 ? .on : .off
        CustomSwitchOption?.state = (vSwitchKeyStatus & 0x200) != 0 ? .on : .off
        CustomSwitchCommand?.state = (vSwitchKeyStatus & 0x400) != 0 ? .on : .off
        CustomSwitchShift?.state = (vSwitchKeyStatus & 0x800) != 0 ? .on : .off
        CustomBeepSound?.state = (vSwitchKeyStatus & 0x8000) != 0 ? .on : .off
        CustomSwitchKey?.setTextByChar(UInt16((vSwitchKeyStatus >> 24) & 0xFF))
    }
    
    @IBAction func onOK(_ sender: Any) {
        self.view.window?.close()
    }
    
    @IBAction func onDefaultConfig(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = "Bạn có chắc chắn muốn thiết lập lại cấu hình mặc định?"
        alert.addButton(withTitle: "Có")
        alert.addButton(withTitle: "Không")
        if let window = self.view.window {
            alert.beginSheetModal(for: window) { returnCode in
                if returnCode.rawValue == 1000 {
                    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        appDelegate.loadDefaultConfig()
                    }
                    UserDefaults.standard.set(0, forKey: "ShowUIOnStartup")
                    self.ShowUIButton.state = .off
                    UserDefaults.standard.set(1, forKey: "RunOnStartup")
                    self.RunOnStartupButton.state = .on
                }
            }
        }
    }
    
    @IBAction func onHomePageLink(_ sender: Any) {
        if let url = URL(string: "https://open-key.org") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func onFanpageLink(_ sender: Any) {
        if let url = URL(string: "https://www.facebook.com/OpenKeyVN") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func onEmailLink(_ sender: Any) {
        if let url = URL(string: "mailto:maivutuyen.91@gmail.com") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func onSourceCode(_ sender: Any) {
        if let url = URL(string: "https://github.com/ToThangGTVT/OpenKeySwift") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func onCheckNewVersionButton(_ sender: Any) {
        CheckNewVersionButton.title = "Đang kiểm tra..."
        CheckNewVersionButton.isEnabled = false
        OpenKeyManager.checkNewVersion(self.view.window) { [weak self] in
            self?.CheckNewVersionButton.isEnabled = true
            self?.CheckNewVersionButton.title = "Kiểm tra bản mới..."
        }
    }
}
