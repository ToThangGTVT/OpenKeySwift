import Cocoa

@objc(MacroViewController)
class MacroViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var macroName: NSTextField!
    @IBOutlet weak var macroContent: NSTextField!
    
    @IBOutlet weak var buttonAdd: NSButton!
    @IBOutlet weak var AutoCapsMacro: NSButton!
    
    let MACRO_ADD_TEXT = "Thêm"
    let MACRO_EDIT_TEXT = "Sửa"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        macroName.delegate = self
        macroContent.delegate = self
        
        AutoCapsMacro.state = vAutoCapsMacro != 0 ? .on : .off

        // load data
        Macro_Reload()
    }

    func saveAndReload() {
        Macro_Reload()
        tableView.reloadData()

        var length: Int32 = 0
        if let bytes = Macro_SaveData(&length), length > 0 {
            UserDefaults.standard.set(Data(bytes: bytes, count: Int(length)), forKey: "macroData")
        } else {
            UserDefaults.standard.removeObject(forKey: "macroData")
        }
        buttonAdd.title = MACRO_ADD_TEXT
    }

    @IBAction func onDeleteMacro(_ sender: Any) {
        if macroName.stringValue.isEmpty {
            showMessage("Bạn hãy chọn từ cần xoá!")
            return
        }
        
        let text = macroName.stringValue
        if Macro_Delete(text) {
            saveAndReload()
            macroName.stringValue = ""
            macroContent.stringValue = ""
            macroName.becomeFirstResponder()
        }
    }

    @IBAction func onAddMacro(_ sender: Any) {
        if macroName.stringValue.isEmpty || macroContent.stringValue.isEmpty {
            showMessage("Bạn hãy nhập từ cần gõ tắt!")
            return
        }
        
        let text = macroName.stringValue
        let content = macroContent.stringValue
        
        Macro_Add(text, content)
        
        macroName.stringValue = ""
        macroContent.stringValue = ""
        macroName.becomeFirstResponder()
        saveAndReload()
    }

    @IBAction func onLoadFromFile(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.message = "Chọn file dữ liệu gõ tắt"
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = ["txt"]
        openPanel.isExtensionHidden = false
        openPanel.nameFieldStringValue = "OpenKeyMacro"
        openPanel.makeKeyAndOrderFront(nil)
        openPanel.level = .statusBar
        
        if openPanel.runModal() == .OK {
            let alert = NSAlert()
            alert.informativeText = "Bạn có muốn giữ lại các dữ liệu hiện tại không?"
            alert.addButton(withTitle: "Có")
            alert.addButton(withTitle: "Không")
            alert.messageText = "Dữ liệu gõ tắt"
            alert.alertStyle = .critical
            
            if let window = self.view.window {
                alert.beginSheetModal(for: window) { returnCode in
                    if let path = openPanel.url?.path {
                        Macro_ReadFromFile(path, returnCode.rawValue == 1000)
                        self.saveAndReload()
                    }
                }
            }
        }
    }

    @IBAction func onExportToFile(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.message = "Chọn nơi lưu dữ liệu gõ tắt"
        savePanel.title = "Chọn nơi lưu dữ liệu gõ tắt"
        savePanel.allowedFileTypes = ["txt"]
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "OpenKeyMacro"
        
        if savePanel.runModal() == .OK {
            if let path = savePanel.url?.path {
                Macro_SaveToFile(path)
            }
        }
    }
    
    func showMessage(_ msg: String) {
        let alert = NSAlert()
        alert.informativeText = msg
        alert.addButton(withTitle: "OK")
        alert.messageText = "Gõ tắt"
        alert.alertStyle = .critical
        if let window = self.view.window {
            alert.beginSheetModal(for: window) { _ in }
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, textField == macroName {
            let text = macroName.stringValue
            if Macro_Has(text) {
                buttonAdd.title = MACRO_EDIT_TEXT
            } else {
                buttonAdd.title = MACRO_ADD_TEXT
            }
        }
    }

    @IBAction func onAutoCapButton(_ sender: NSButton) {
        let val = sender.state == .on ? 1 : 0
        vAutoCapsMacro = Int32(val)
        UserDefaults.standard.set(val, forKey: "vAutoCapsMacro")
    }
    
    // MARK: - TableView
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return Int(Macro_GetCount())
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellId = ""
        var v: NSTableCellView?
        
        if tableColumn == tableView.tableColumns[0] {
            cellId = "MacroCell"
            v = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellId), owner: self) as? NSTableCellView
            if let ptr = Macro_GetText(Int32(row)) {
                v?.textField?.stringValue = String(cString: ptr)
            }
        } else if tableView.tableColumns.count > 1 && tableColumn == tableView.tableColumns[1] {
            cellId = "ContentCell"
            v = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellId), owner: self) as? NSTableCellView
            if let ptr = Macro_GetContent(Int32(row)) {
                v?.textField?.stringValue = String(cString: ptr)
            }
        }
        return v
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if let ptrText = Macro_GetText(Int32(row)) {
            macroName.stringValue = String(cString: ptrText)
        }
        if let ptrContent = Macro_GetContent(Int32(row)) {
            macroContent.stringValue = String(cString: ptrContent)
        }
        buttonAdd.title = MACRO_EDIT_TEXT
        return true
    }
}
