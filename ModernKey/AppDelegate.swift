import Cocoa
import ServiceManagement

@main
@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWC: NSWindowController?
    var macroWC: NSWindowController?
    var convertWC: NSWindowController?
    var aboutWC: NSWindowController?
    
    var statusItem: NSStatusItem!
    var theMenu: NSMenu!
    
    var menuInputMethod: NSMenuItem!
    var mnuTelex: NSMenuItem!
    var mnuVNI: NSMenuItem!
    var mnuSimpleTelex1: NSMenuItem!
    var mnuSimpleTelex2: NSMenuItem!
    
    var mnuUnicode: NSMenuItem!
    var mnuTCVN: NSMenuItem!
    var mnuVNIWindows: NSMenuItem!
    var mnuUnicodeComposite: NSMenuItem!
    var mnuVietnameseLocaleCP1258: NSMenuItem!
    
    var mnuQuickConvert: NSMenuItem!
    
    // Globals are accessed from Globals.cpp via bridging header
    
    func askPermission() {
        let alert = NSAlert()
        alert.messageText = "OpenKey cần bạn cấp quyền để có thể hoạt động!"
        alert.informativeText = "Vui lòng chạy lại ứng dụng sau khi cấp quyền."
        alert.addButton(withTitle: "Không")
        alert.addButton(withTitle: "Cấp quyền")
        
        alert.window.makeKeyAndOrderFront(nil)
        alert.window.level = .statusBar
        
        let res = alert.runModal()
        if res.rawValue == 1001 {
            MJAccessibilityOpenPanel()
        }
        NSApp.terminate(nil)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Register notifications
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(receiveWakeNote(_:)), name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(receiveSleepNote(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(receiveActiveSpaceChanged(_:)), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(activeAppChanged(_:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        
        UserDefaults.standard.set(50, forKey: "NSInitialToolTipDelay")
        
        // Check if already running
        let currentUID = getuid()
        let runningApps = NSWorkspace.shared.runningApplications
        let myPID = ProcessInfo.processInfo.processIdentifier
        var alreadyRunning = false
        
        for app in runningApps {
            if app.bundleIdentifier == OPENKEY_BUNDLE && app.processIdentifier != myPID {
                let pid = app.processIdentifier
                var proc = proc_bsdinfo()
                let size = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &proc, Int32(MemoryLayout<proc_bsdinfo>.size))
                if size == MemoryLayout<proc_bsdinfo>.size && proc.pbi_uid == currentUID {
                    alreadyRunning = true
                    break
                }
            }
        }
        
        if alreadyRunning {
            NSApp.terminate(nil)
            return
        }
        
        if !MJAccessibilityIsEnabled() {
            askPermission()
            return
        }
        
        vShowIconOnDock = Int32(UserDefaults.standard.integer(forKey: "vShowIconOnDock"))
        if vShowIconOnDock != 0 {
            NSApp.setActivationPolicy(.regular)
        }
        
        if (vSwitchKeyStatus & 0x8000) != 0 {
            NSSound.beep()
        }
        
        createStatusBarMenu()
        
        DispatchQueue.main.async {
            if !OpenKeyManager.initEventTap() {
                self.onControlPanelSelected()
            } else {
                let showui = UserDefaults.standard.integer(forKey: "ShowUIOnStartup")
                if showui == 1 {
                    self.onControlPanelSelected()
                }
            }
            self.setQuickConvertString()
        }
        
        if !UserDefaults.standard.bool(forKey: "NonFirstTime") {
            loadDefaultConfig()
        }
        UserDefaults.standard.set(1, forKey: "NonFirstTime")
        
        let dontCheckUpdate = UserDefaults.standard.integer(forKey: "DontCheckUpdate")
        if dontCheckUpdate == 0 {
            OpenKeyManager.checkNewVersion(nil, callbackFunc: nil)
        }
        
        let val = UserDefaults.standard.integer(forKey: "RunOnStartup")
        setRunOnStartup(val != 0)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        onControlPanelSelected()
        return true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    func createStatusBarMenu() {
        let statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(named: "Status")
        statusItem.button?.alternateImage = NSImage(named: "StatusHighlighted")
        
        theMenu = NSMenu(title: "")
        theMenu.autoenablesItems = false
        
        menuInputMethod = theMenu.addItem(withTitle: "Bật Tiếng Việt", action: #selector(onInputMethodSelected), keyEquivalent: "")
        theMenu.addItem(NSMenuItem.separator())
        let menuInputType = theMenu.addItem(withTitle: "Kiểu gõ", action: nil, keyEquivalent: "")
        
        theMenu.addItem(NSMenuItem.separator())
        
        mnuUnicode = theMenu.addItem(withTitle: "Unicode dựng sẵn", action: #selector(onCodeSelected(_:)), keyEquivalent: "")
        mnuUnicode.tag = 0
        mnuTCVN = theMenu.addItem(withTitle: "TCVN3 (ABC)", action: #selector(onCodeSelected(_:)), keyEquivalent: "")
        mnuTCVN.tag = 1
        mnuVNIWindows = theMenu.addItem(withTitle: "VNI Windows", action: #selector(onCodeSelected(_:)), keyEquivalent: "")
        mnuVNIWindows.tag = 2
        let menuCode = theMenu.addItem(withTitle: "Bảng mã khác", action: nil, keyEquivalent: "")
        
        theMenu.addItem(NSMenuItem.separator())
        
        theMenu.addItem(withTitle: "Công cụ chuyển mã...", action: #selector(onConvertTool), keyEquivalent: "")
        mnuQuickConvert = theMenu.addItem(withTitle: "Chuyển mã nhanh", action: #selector(onQuickConvert), keyEquivalent: "")
        
        theMenu.addItem(NSMenuItem.separator())
        
        theMenu.addItem(withTitle: "Bảng điều khiển...", action: #selector(onControlPanelSelected), keyEquivalent: "")
        theMenu.addItem(withTitle: "Gõ tắt...", action: #selector(onMacroSelected), keyEquivalent: "")
        theMenu.addItem(withTitle: "Giới thiệu", action: #selector(onAboutSelected), keyEquivalent: "")
        theMenu.addItem(NSMenuItem.separator())
        
        theMenu.addItem(withTitle: "Thoát", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        setInputTypeMenu(menuInputType)
        setCodeMenu(menuCode)
        
        statusItem.menu = theMenu
        fillData()
    }
    
    func setInputTypeMenu(_ parent: NSMenuItem) {
        let sub = NSMenu(title: "")
        sub.autoenablesItems = false
        mnuTelex = sub.addItem(withTitle: "Telex", action: #selector(onInputTypeSelected(_:)), keyEquivalent: "")
        mnuTelex.tag = 0
        mnuVNI = sub.addItem(withTitle: "VNI", action: #selector(onInputTypeSelected(_:)), keyEquivalent: "")
        mnuVNI.tag = 1
        mnuSimpleTelex1 = sub.addItem(withTitle: "Simple Telex 1", action: #selector(onInputTypeSelected(_:)), keyEquivalent: "")
        mnuSimpleTelex1.tag = 2
        mnuSimpleTelex2 = sub.addItem(withTitle: "Simple Telex 2", action: #selector(onInputTypeSelected(_:)), keyEquivalent: "")
        mnuSimpleTelex2.tag = 3
        theMenu.setSubmenu(sub, for: parent)
    }
    
    func setCodeMenu(_ parent: NSMenuItem) {
        let sub = NSMenu(title: "")
        sub.autoenablesItems = false
        mnuUnicodeComposite = sub.addItem(withTitle: "Unicode tổ hợp", action: #selector(onCodeSelected(_:)), keyEquivalent: "")
        mnuUnicodeComposite.tag = 3
        mnuVietnameseLocaleCP1258 = sub.addItem(withTitle: "Vietnamese Locale CP 1258", action: #selector(onCodeSelected(_:)), keyEquivalent: "")
        mnuVietnameseLocaleCP1258.tag = 4
        theMenu.setSubmenu(sub, for: parent)
    }
    
    func setQuickConvertString() {
        var hotKey = ""
        var hasAdd = false
        let ck = Int(convertToolHotKey)
        
        if (ck & 0x100) != 0 {
            hotKey += "⌃"
            hasAdd = true
        }
        if (ck & 0x200) != 0 {
            if hasAdd { hotKey += " + " }
            hotKey += "⌥"
            hasAdd = true
        }
        if (ck & 0x400) != 0 {
            if hasAdd { hotKey += " + " }
            hotKey += "⌘"
            hasAdd = true
        }
        if (ck & 0x800) != 0 {
            if hasAdd { hotKey += " + " }
            hotKey += "⇧"
            hasAdd = true
        }
        
        let k = (ck >> 24) & 0xFF
        if k != 0xFE {
            if hasAdd { hotKey += " + " }
            if k == kVK_Space {
                hotKey += "␣ "
            } else {
                hotKey += String(Character(UnicodeScalar(k)!))
            }
        }
        mnuQuickConvert.title = hasAdd ? "Chuyển mã nhanh - [\(hotKey.uppercased())]" : "Chuyển mã nhanh"
    }
    
    func loadDefaultConfig() {
        vLanguage = 1
        UserDefaults.standard.set(vLanguage, forKey: "InputMethod")
        vInputType = 0
        UserDefaults.standard.set(vInputType, forKey: "InputType")
        vFreeMark = 0
        UserDefaults.standard.set(vFreeMark, forKey: "FreeMark")
        vCheckSpelling = 1
        UserDefaults.standard.set(vCheckSpelling, forKey: "Spelling")
        vCodeTable = 0
        UserDefaults.standard.set(vCodeTable, forKey: "CodeTable")
        vSwitchKeyStatus = 0x7A000206
        UserDefaults.standard.set(vSwitchKeyStatus, forKey: "SwitchKeyStatus")
        vQuickTelex = 0
        UserDefaults.standard.set(vQuickTelex, forKey: "QuickTelex")
        vUseModernOrthography = 0
        UserDefaults.standard.set(vUseModernOrthography, forKey: "ModernOrthography")
        vRestoreIfWrongSpelling = 0
        UserDefaults.standard.set(vRestoreIfWrongSpelling, forKey: "RestoreIfInvalidWord")
        vFixRecommendBrowser = 1
        UserDefaults.standard.set(vFixRecommendBrowser, forKey: "FixRecommendBrowser")
        vUseMacro = 1
        UserDefaults.standard.set(vUseMacro, forKey: "UseMacro")
        vUseMacroInEnglishMode = 0
        UserDefaults.standard.set(vUseMacroInEnglishMode, forKey: "UseMacroInEnglishMode")
        vSendKeyStepByStep = 0
        UserDefaults.standard.set(vSendKeyStepByStep, forKey: "SendKeyStepByStep")
        vUseSmartSwitchKey = 1
        UserDefaults.standard.set(vUseSmartSwitchKey, forKey: "UseSmartSwitchKey")
        vUpperCaseFirstChar = 0
        UserDefaults.standard.set(vUpperCaseFirstChar, forKey: "UpperCaseFirstChar")
        vTempOffSpelling = 0
        UserDefaults.standard.set(vTempOffSpelling, forKey: "vTempOffSpelling")
        vAllowConsonantZFWJ = 0
        UserDefaults.standard.set(vAllowConsonantZFWJ, forKey: "vAllowConsonantZFWJ")
        vQuickStartConsonant = 0
        UserDefaults.standard.set(vQuickStartConsonant, forKey: "vQuickStartConsonant")
        vQuickEndConsonant = 0
        UserDefaults.standard.set(vQuickEndConsonant, forKey: "vQuickEndConsonant")
        vRememberCode = 1
        UserDefaults.standard.set(vRememberCode, forKey: "vRememberCode")
        vOtherLanguage = 1
        UserDefaults.standard.set(vOtherLanguage, forKey: "vOtherLanguage")
        vTempOffOpenKey = 0
        UserDefaults.standard.set(vTempOffOpenKey, forKey: "vTempOffOpenKey")
        vShowIconOnDock = 0
        UserDefaults.standard.set(vShowIconOnDock, forKey: "vShowIconOnDock")
        vFixChromiumBrowser = 0
        UserDefaults.standard.set(vFixChromiumBrowser, forKey: "vFixChromiumBrowser")
        vPerformLayoutCompat = 0
        UserDefaults.standard.set(vPerformLayoutCompat, forKey: "vPerformLayoutCompat")
        
        UserDefaults.standard.set(1, forKey: "GrayIcon")
        UserDefaults.standard.set(1, forKey: "RunOnStartup")
        
        fillData()
        viewController?.fillData()
    }
    
    func setRunOnStartup(_ val: Bool) {
        let appId = OPENKEY_HELPER_BUNDLE as CFString
        SMLoginItemSetEnabled(appId, val)
    }
    
    func setGrayIcon(_ val: Bool) {
        fillData()
    }
    
    func showIconOnDock(_ val: Bool) {
        NSApp.setActivationPolicy(val ? .regular : .accessory)
    }
    
    func fillData() {
        let intInputMethod = UserDefaults.standard.integer(forKey: "InputMethod")
        let grayIcon = UserDefaults.standard.integer(forKey: "GrayIcon")
        if intInputMethod == 1 {
            menuInputMethod.state = .on
            statusItem.button?.image = NSImage(named: "Status")
            statusItem.button?.image?.isTemplate = (grayIcon != 0)
            statusItem.button?.alternateImage = NSImage(named: "StatusHighlighted")
        } else {
            menuInputMethod.state = .off
            statusItem.button?.image = NSImage(named: "StatusEng")
            statusItem.button?.image?.isTemplate = (grayIcon != 0)
            statusItem.button?.alternateImage = NSImage(named: "StatusHighlightedEng")
        }
        vLanguage = Int32(intInputMethod)
        
        let intInputType = UserDefaults.standard.integer(forKey: "InputType")
        mnuTelex.state = .off
        mnuVNI.state = .off
        mnuSimpleTelex1.state = .off
        mnuSimpleTelex2.state = .off
        if intInputType == 0 { mnuTelex.state = .on }
        else if intInputType == 1 { mnuVNI.state = .on }
        else if intInputType == 2 { mnuSimpleTelex1.state = .on }
        else if intInputType == 3 { mnuSimpleTelex2.state = .on }
        vInputType = Int32(intInputType)
        
        var intSwitchKeyStatus = UserDefaults.standard.integer(forKey: "SwitchKeyStatus")
        if intSwitchKeyStatus == 0 { intSwitchKeyStatus = 0x7A000206 }
        vSwitchKeyStatus = Int32(intSwitchKeyStatus)
        
        let intCode = UserDefaults.standard.integer(forKey: "CodeTable")
        mnuUnicode.state = .off
        mnuTCVN.state = .off
        mnuVNIWindows.state = .off
        mnuUnicodeComposite.state = .off
        mnuVietnameseLocaleCP1258.state = .off
        if intCode == 0 { mnuUnicode.state = .on }
        else if intCode == 1 { mnuTCVN.state = .on }
        else if intCode == 2 { mnuVNIWindows.state = .on }
        else if intCode == 3 { mnuUnicodeComposite.state = .on }
        else if intCode == 4 { mnuVietnameseLocaleCP1258.state = .on }
        vCodeTable = Int32(intCode)
        
        let intRunOnStartup = UserDefaults.standard.integer(forKey: "RunOnStartup")
        setRunOnStartup(intRunOnStartup != 0)
    }
    
    @objc func onImputMethodChanged(_ willNotify: Bool) {
        var intInputMethod = UserDefaults.standard.integer(forKey: "InputMethod")
        intInputMethod = (intInputMethod == 0) ? 1 : 0
        vLanguage = Int32(intInputMethod)
        UserDefaults.standard.set(intInputMethod, forKey: "InputMethod")
        
        fillData()
        viewController?.fillData()
        
        if willNotify {
            OnInputMethodChanged()
        }
    }
    
    @objc func onInputMethodSelected() {
        onImputMethodChanged(true)
    }
    
    @objc func onInputTypeSelected(_ sender: NSMenuItem) {
        onInputTypeSelectedIndex(Int32(sender.tag))
    }
    
    func onInputTypeSelectedIndex(_ index: Int32) {
        UserDefaults.standard.set(Int(index), forKey: "InputType")
        vInputType = index
        fillData()
        viewController?.fillData()
    }
    
    func onCodeTableChanged(_ index: Int32) {
        UserDefaults.standard.set(Int(index), forKey: "CodeTable")
        vCodeTable = index
        fillData()
        viewController?.fillData()
        OnTableCodeChange()
    }
    
    @objc func onCodeSelected(_ sender: NSMenuItem) {
        onCodeTableChanged(Int32(sender.tag))
    }
    
    /// Wraps a XIB-loaded view controller in a floating utility window.
    private func makeWindowController(_ viewController: NSViewController,
                                      title: String,
                                      styleMask: NSWindow.StyleMask = [.titled, .closable]) -> NSWindowController {
        let window = NSWindow(contentViewController: viewController)
        window.styleMask = styleMask
        window.title = title
        window.isReleasedWhenClosed = false
        window.center()
        return NSWindowController(window: window)
    }

    /// Creates the window controller on first use, then brings it to the front.
    private func show(_ windowController: inout NSWindowController?,
                      make: () -> NSWindowController) {
        if windowController == nil {
            windowController = make()
        }
        guard let window = windowController?.window, !window.isVisible else { return }
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
    }

    @objc func onConvertTool() {
        show(&convertWC) {
            self.makeWindowController(ConvertToolViewController(nibName: "ConvertToolViewController", bundle: nil),
                                      title: "Công cụ chuyển mã")
        }
    }
    
    @objc func onQuickConvert() {
        if OpenKeyManager.quickConvert() {
            if !convertToolDontAlertWhenCompleted {
                OpenKeyManager.showMessage(nil, message: "Chuyển mã thành công!", subMsg: "Kết quả đã được lưu trong clipboard.")
            }
        } else {
            OpenKeyManager.showMessage(nil, message: "Không có dữ liệu trong clipboard!", subMsg: "Hãy sao chép một đoạn text để chuyển đổi!")
        }
    }
    
    @objc func onControlPanelSelected() {
        show(&mainWC) {
            self.makeWindowController(ViewController(nibName: "ViewController", bundle: nil),
                                      title: "OpenKey - Bộ gõ Tiếng Việt")
        }
    }

    @objc func onMacroSelected() {
        show(&macroWC) {
            self.makeWindowController(MacroViewController(nibName: "MacroViewController", bundle: nil),
                                      title: "Thiết lập gõ tắt",
                                      styleMask: [.titled, .closable, .miniaturizable, .resizable])
        }
    }

    @objc func onAboutSelected() {
        show(&aboutWC) {
            self.makeWindowController(AboutViewController(nibName: "AboutViewController", bundle: nil),
                                      title: "Giới thiệu")
        }
    }
    
    @objc func onSwitchLanguage() {
        onInputMethodSelected()
        viewController?.fillData()
    }
    
    @objc func receiveWakeNote(_ note: Notification) {
        _ = OpenKeyManager.initEventTap()
    }
    
    @objc func receiveSleepNote(_ note: Notification) {
        _ = OpenKeyManager.stopEventTap()
    }
    
    @objc func receiveActiveSpaceChanged(_ note: Notification) {
        RequestNewSession()
    }
    
    @objc func activeAppChanged(_ note: Notification) {
        if vUseSmartSwitchKey != 0 && OpenKeyManager.isInited() {
            OnActiveAppChanged()
        }
    }
}
