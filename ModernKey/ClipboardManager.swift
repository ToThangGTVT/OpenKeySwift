import Cocoa

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    
    var history: [String] = []
    
    // UserDefaults keys
    private let historyKey = "ClipboardHistoryData"
    let enableKey = "EnableClipboardHistory"
    let historySizeKey = "ClipboardHistorySize"
    let autoPasteKey = "ClipboardAutoPaste"
    
    private init() {
        lastChangeCount = pasteboard.changeCount
        loadHistory()
        
        // Setup defaults
        UserDefaults.standard.register(defaults: [
            enableKey: true,
            historySizeKey: 50,
            autoPasteKey: true
        ])
    }
    
    func start() {
        if timer != nil { return }
        timer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(checkPasteboard), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func checkPasteboard() {
        guard UserDefaults.standard.bool(forKey: enableKey) else { return }
        
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            if let newString = pasteboard.string(forType: .string) {
                let trimmed = newString.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    add(string: newString)
                }
            }
        }
    }
    
    private func add(string: String) {
        // Remove if exists to bring to top
        if let index = history.firstIndex(of: string) {
            history.remove(at: index)
        }
        
        history.insert(string, at: 0)
        
        let maxSize = UserDefaults.standard.integer(forKey: historySizeKey)
        if history.count > maxSize && maxSize > 0 {
            history = Array(history.prefix(maxSize))
        }
        
        saveHistory()
        NotificationCenter.default.post(name: NSNotification.Name("ClipboardHistoryUpdated"), object: nil)
    }
    
    /// Drops anything past the current limit, e.g. right after the user lowers it.
    func trimHistory() {
        let maxSize = UserDefaults.standard.integer(forKey: historySizeKey)
        guard maxSize > 0, history.count > maxSize else { return }
        history = Array(history.prefix(maxSize))
        saveHistory()
        NotificationCenter.default.post(name: NSNotification.Name("ClipboardHistoryUpdated"), object: nil)
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
        NotificationCenter.default.post(name: NSNotification.Name("ClipboardHistoryUpdated"), object: nil)
    }
    
    private func saveHistory() {
        UserDefaults.standard.set(history, forKey: historyKey)
    }
    
    private func loadHistory() {
        if let saved = UserDefaults.standard.array(forKey: historyKey) as? [String] {
            history = saved
        }
    }
    
    func copyAndPaste(item: String) {
        // Cập nhật pasteboard
        pasteboard.clearContents()
        pasteboard.setString(item, forType: .string)
        lastChangeCount = pasteboard.changeCount
        
        // Di chuyển mục này lên đầu lịch sử
        if let index = history.firstIndex(of: item) {
            history.remove(at: index)
            history.insert(item, at: 0)
            saveHistory()
        }
        
        if UserDefaults.standard.bool(forKey: autoPasteKey) {
            simulatePaste()
        }
    }
    
    private func simulatePaste() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let eventSource = CGEventSource(stateID: .hidSystemState)
            
            let vKey = CGKeyCode(0x09) // phím 'v'
            let down = CGEvent(keyboardEventSource: eventSource, virtualKey: vKey, keyDown: true)
            let up = CGEvent(keyboardEventSource: eventSource, virtualKey: vKey, keyDown: false)
            
            down?.flags = .maskCommand
            up?.flags = .maskCommand
            
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
    }
}
