//
//  ClipboardService.swift
//  ModernKey
//
//  Service managing clipboard history tracking, persistence and pasting.
//

import Cocoa

protocol ClipboardServiceProtocol {
    var history: [String] { get }
    var isEnabled: Bool { get set }
    var historySize: Int { get set }
    var isAutoPaste: Bool { get set }
    
    func start()
    func stop()
    func clearHistory()
    func trimHistory()
    func copyAndPaste(item: String)
    func addObserver(observer: Any, selector: Selector)
    func removeObserver(observer: Any)
}

final class ClipboardService: ClipboardServiceProtocol {
    static let shared = ClipboardService()
    
    static let historyUpdatedNotification = NSNotification.Name("ClipboardHistoryUpdated")
    
    private init() {}
    
    var history: [String] {
        return ClipboardManager.shared.history
    }
    
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: ClipboardManager.shared.enableKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: ClipboardManager.shared.enableKey)
            if newValue {
                ClipboardManager.shared.start()
            }
        }
    }
    
    var historySize: Int {
        get { UserDefaults.standard.integer(forKey: ClipboardManager.shared.historySizeKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: ClipboardManager.shared.historySizeKey)
            ClipboardManager.shared.trimHistory()
        }
    }
    
    var isAutoPaste: Bool {
        get { UserDefaults.standard.bool(forKey: ClipboardManager.shared.autoPasteKey) }
        set { UserDefaults.standard.set(newValue, forKey: ClipboardManager.shared.autoPasteKey) }
    }
    
    func start() {
        ClipboardManager.shared.start()
    }
    
    func stop() {
        ClipboardManager.shared.stop()
    }
    
    func clearHistory() {
        ClipboardManager.shared.clearHistory()
    }
    
    func trimHistory() {
        ClipboardManager.shared.trimHistory()
    }
    
    func copyAndPaste(item: String) {
        ClipboardManager.shared.copyAndPaste(item: item)
    }
    
    func addObserver(observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: Self.historyUpdatedNotification, object: nil)
    }
    
    func removeObserver(observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: Self.historyUpdatedNotification, object: nil)
    }
}
