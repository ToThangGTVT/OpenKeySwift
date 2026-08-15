//
//  AppDelegate.swift
//  ModernKey
//
//  Application Delegate managing application lifecycle and Status Bar Menu.
//

import Cocoa
import ServiceManagement

@main
@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate {
    
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
    
    private let router = AppRouter.shared
    private let settings = SettingsService.shared
    private let accessibility = AccessibilityService.shared
    private let update = UpdateService.shared
    private let clipboard = ClipboardService.shared
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Register system notifications
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
        
        if !UserDefaults.standard.bool(forKey: "NonFirstTime") {
            settings.loadDefaultConfig()
            UserDefaults.standard.set(true, forKey: "NonFirstTime")
        } else {
            settings.synchronizeAll()
        }
        
        if !accessibility.isAccessibilityEnabled() {
            accessibility.askPermission(completion: nil)
        }
        
        if settings.showIconOnDock {
            settings.setShowIconOnDockEnabled(true)
        }
        
        if (settings.switchKeyStatus & 0x8000) != 0 {
            NSSound.beep()
        }
        
        createStatusBarMenu()
        
        DispatchQueue.main.async {
            if !OpenKeyManager.initEventTap() {
                self.onControlPanelSelected()
            } else {
                if self.settings.showUIOnStartup {
                    self.onControlPanelSelected()
                }
            }
            self.setQuickConvertString()
        }
        
        if settings.checkUpdateOnStartup {
            update.checkNewVersion(parent: nil) { hasUpdate, newVersion, _ in
                if hasUpdate {
                    OpenKeyManager.showUpdateMessage(nil, needUpdating: true, newVersion: newVersion)
                }
            }
        }
        
        clipboard.start()
        settings.setRunOnStartupEnabled(settings.runOnStartup)
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
        
        let menuClipboard = theMenu.addItem(withTitle: "Lịch sử Clipboard", action: nil, keyEquivalent: "")
        theMenu.setSubmenu(ClipboardMenu.shared, for: menuClipboard)
        
        theMenu.addItem(NSMenuItem.separator())
        
        theMenu.addItem(withTitle: "Bảng điều khiển...", action: #selector(onControlPanelSelected), keyEquivalent: "")
        theMenu.addItem(withTitle: "Gõ tắt...", action: #selector(onMacroSelected), keyEquivalent: "")
        theMenu.addItem(withTitle: "Chế độ gõ theo ứng dụng...", action: #selector(onAppInputModeSelected), keyEquivalent: "")
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
    
    func setRunOnStartup(_ val: Bool) {
        settings.runOnStartup = val
    }
    
    func setGrayIcon(_ val: Bool) {
        settings.grayIcon = val
        fillData()
    }
    
    func showIconOnDock(_ val: Bool) {
        settings.showIconOnDock = val
    }
    
    func fillData() {
        let isViet = settings.language == 1
        let isGray = settings.grayIcon
        
        if isViet {
            menuInputMethod.state = .on
            statusItem.button?.image = NSImage(named: "Status")
            statusItem.button?.image?.isTemplate = isGray
            statusItem.button?.alternateImage = NSImage(named: "StatusHighlighted")
        } else {
            menuInputMethod.state = .off
            statusItem.button?.image = NSImage(named: "StatusEng")
            statusItem.button?.image?.isTemplate = isGray
            statusItem.button?.alternateImage = NSImage(named: "StatusHighlightedEng")
        }
        
        let it = settings.inputType
        mnuTelex.state = (it == 0) ? .on : .off
        mnuVNI.state = (it == 1) ? .on : .off
        mnuSimpleTelex1.state = (it == 2) ? .on : .off
        mnuSimpleTelex2.state = (it == 3) ? .on : .off
        
        let ct = settings.codeTable
        mnuUnicode.state = (ct == 0) ? .on : .off
        mnuTCVN.state = (ct == 1) ? .on : .off
        mnuVNIWindows.state = (ct == 2) ? .on : .off
        mnuUnicodeComposite.state = (ct == 3) ? .on : .off
        mnuVietnameseLocaleCP1258.state = (ct == 4) ? .on : .off
    }
    
    @objc func onImputMethodChanged(_ willNotify: Bool) {
        settings.language = (settings.language == 0) ? 1 : 0
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
        settings.inputType = index
        fillData()
        viewController?.fillData()
    }
    
    func onCodeTableChanged(_ index: Int32) {
        settings.codeTable = index
        fillData()
        viewController?.fillData()
        OnTableCodeChange()
    }
    
    @objc func onCodeSelected(_ sender: NSMenuItem) {
        onCodeTableChanged(Int32(sender.tag))
    }
    
    @objc func onConvertTool() {
        router.openConvertToolWindow()
    }
    
    @objc func onQuickConvert() {
        let success = OpenKeyManager.quickConvert()
        router.showQuickConvertResult(success: success)
    }
    
    @objc func showClipboardHistory() {
        guard clipboard.isEnabled else { return }
        DispatchQueue.main.async {
            ClipboardPanel.shared.present()
        }
    }
    
    @objc func onControlPanelSelected() {
        router.openControlPanel()
    }

    @objc func onMacroSelected() {
        router.openMacroWindow()
    }

    @objc func onAppInputModeSelected() {
        router.openAppInputModeWindow()
    }

    @objc func onAboutSelected() {
        router.openAboutWindow()
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
