import Cocoa

class ClipboardMenu: NSMenu, NSSearchFieldDelegate, NSMenuDelegate {
    /// Hangs off the status bar item. The hotkey uses `ClipboardPanel` instead.
    static let shared = ClipboardMenu()

    private let searchField = NSSearchField()
    private var filteredHistory: [String] = []

    override init(title: String) {
        super.init(title: title)
        setupMenu()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupMenu()
    }
    
    private func setupMenu() {
        self.delegate = self
        
        searchField.delegate = self
        searchField.placeholderString = "Tìm kiếm..."
        searchField.frame = NSRect(x: 10, y: 5, width: 280, height: 22)
        searchField.bezelStyle = .roundedBezel
        
        // Add listener for clipboard updates
        NotificationCenter.default.addObserver(self, selector: #selector(clipboardUpdated), name: NSNotification.Name("ClipboardHistoryUpdated"), object: nil)
    }
    
    // MARK: - NSMenuDelegate
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        buildMenuItems(searchText: searchField.stringValue)
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        // Focus the search field when menu opens
        DispatchQueue.main.async {
            if let window = menu.items.first?.view?.window {
                window.makeFirstResponder(self.searchField)
            }
        }
    }

    
    // MARK: - NSSearchFieldDelegate
    
    func controlTextDidChange(_ obj: Notification) {
        buildMenuItems(searchText: searchField.stringValue)
    }
    
    @objc private func clipboardUpdated() {
        // Option to reload if menu is currently open, but menuNeedsUpdate will handle it next time.
    }
    
    private func buildMenuItems(searchText: String) {
        self.removeAllItems()
        
        // 1. Search Field Item
        let searchItem = NSMenuItem()
        let searchView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 32))
        searchView.addSubview(searchField)
        searchItem.view = searchView
        self.addItem(searchItem)
        self.addItem(NSMenuItem.separator())
        
        let allHistory = ClipboardManager.shared.history
        
        if searchText.isEmpty {
            filteredHistory = allHistory
        } else {
            let lowerSearch = searchText.lowercased()
            filteredHistory = allHistory.filter { $0.lowercased().contains(lowerSearch) }
        }
        
        if filteredHistory.isEmpty {
            let emptyItem = NSMenuItem(title: "Không có dữ liệu", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            self.addItem(emptyItem)
        } else {
            for (index, itemText) in filteredHistory.enumerated() {
                // Truncate for display
                var displayTitle = itemText.replacingOccurrences(of: "\n", with: " ")
                if displayTitle.count > 50 {
                    displayTitle = String(displayTitle.prefix(50)) + "..."
                }
                
                let menuItem = NSMenuItem(title: displayTitle, action: #selector(itemSelected(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.tag = index
                
                if index < 9 {
                    menuItem.keyEquivalent = String(index + 1)
                    menuItem.keyEquivalentModifierMask = .command
                }
                
                // Add a tooltip for full text
                menuItem.toolTip = itemText
                
                self.addItem(menuItem)
            }
        }
        
        self.addItem(NSMenuItem.separator())
        let clearItem = NSMenuItem(title: "Xóa lịch sử", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        self.addItem(clearItem)
    }
    
    @objc private func itemSelected(_ sender: NSMenuItem) {
        let index = sender.tag
        if index >= 0 && index < filteredHistory.count {
            let fullText = filteredHistory[index]
            ClipboardManager.shared.copyAndPaste(item: fullText)
        }
        // Clear search field after selection
        searchField.stringValue = ""
    }
    
    @objc private func clearHistory() {
        ClipboardManager.shared.clearHistory()
        searchField.stringValue = ""
    }
    
}
