//
//  ClipboardMenu.swift
//  ModernKey
//
//  Status bar submenu for Clipboard history.
//

import Cocoa

class ClipboardMenu: NSMenu, NSSearchFieldDelegate, NSMenuDelegate {
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
        
        ClipboardService.shared.addObserver(observer: self, selector: #selector(clipboardUpdated))
    }
    
    deinit {
        ClipboardService.shared.removeObserver(observer: self)
    }
    
    // MARK: - NSMenuDelegate
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        buildMenuItems(searchText: searchField.stringValue)
    }
    
    func menuWillOpen(_ menu: NSMenu) {
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
        
        let allHistory = ClipboardService.shared.history
        
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
            ClipboardService.shared.copyAndPaste(item: fullText)
        }
        searchField.stringValue = ""
    }
    
    @objc private func clearHistory() {
        ClipboardService.shared.clearHistory()
        searchField.stringValue = ""
    }
}
