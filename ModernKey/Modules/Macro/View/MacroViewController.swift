//
//  MacroViewController.swift
//  ModernKey
//
//  VIPER View for Macro module.
//

import Cocoa

@objc(MacroViewController)
class MacroViewController: NSViewController, MacroViewProtocol, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var macroName: NSTextField!
    @IBOutlet weak var macroContent: NSTextField!
    
    @IBOutlet weak var buttonAdd: NSButton!
    @IBOutlet weak var AutoCapsMacro: NSButton!
    
    let MACRO_ADD_TEXT = "Thêm"
    let MACRO_EDIT_TEXT = "Sửa"
    
    var presenter: MacroPresenterProtocol?
    private var macroItems: [MacroItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        macroName.delegate = self
        macroContent.delegate = self
        
        if presenter == nil {
            _ = MacroBuilder.setup(view: self)
        }
        presenter?.viewDidLoad()
    }

    // MARK: - MacroViewProtocol
    func displayMacros(_ items: [MacroItem]) {
        self.macroItems = items
        tableView.reloadData()
    }

    func setInputFields(key: String, content: String, isEditing: Bool) {
        macroName.stringValue = key
        macroContent.stringValue = content
        buttonAdd.title = isEditing ? MACRO_EDIT_TEXT : MACRO_ADD_TEXT
    }

    func clearInputFields() {
        macroName.stringValue = ""
        macroContent.stringValue = ""
        buttonAdd.title = MACRO_ADD_TEXT
        macroName.becomeFirstResponder()
    }

    func setAutoCapsState(isOn: Bool) {
        AutoCapsMacro.state = isOn ? .on : .off
    }

    func showMessage(_ message: String) {
        let alert = NSAlert()
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.messageText = "Dữ liệu gõ tắt"
        alert.alertStyle = .critical
        
        if let window = self.view.window {
            alert.beginSheetModal(for: window) { _ in }
        } else {
            alert.runModal()
        }
    }

    // MARK: - Actions matching MacroViewController.xib
    @IBAction func onDeleteMacro(_ sender: Any) {
        presenter?.didTapDelete(key: macroName.stringValue)
    }

    @IBAction func onAddMacro(_ sender: Any) {
        presenter?.didTapAddOrUpdate(key: macroName.stringValue, content: macroContent.stringValue)
    }

    @IBAction func onLoadFromFile(_ sender: Any) {
        presenter?.didTapLoadFromFile()
    }

    @IBAction func onExportToFile(_ sender: Any) {
        presenter?.didTapExportToFile()
    }

    @IBAction func onAutoCapButton(_ sender: NSButton) {
        presenter?.didToggleAutoCaps(isOn: sender.state == .on)
    }

    @IBAction func onAutoCapsMacro(_ sender: NSButton) {
        presenter?.didToggleAutoCaps(isOn: sender.state == .on)
    }

    @IBAction func onClose(_ sender: Any) {
        self.view.window?.close()
    }

    // MARK: - NSTableViewDataSource & Delegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return macroItems.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard macroItems.indices.contains(row) else { return nil }
        let item = macroItems[row]
        
        if tableColumn == tableView.tableColumns.first {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("macroKey"), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = item.key
                return cell
            }
        } else {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("macroContent"), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = item.content
                return cell
            }
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 && selectedRow < macroItems.count {
            presenter?.didSelectMacro(at: selectedRow)
        }
    }

    // MARK: - NSTextFieldDelegate
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, textField == macroName {
            presenter?.didChangeKeyInput(macroName.stringValue)
        }
    }
}

// MARK: - Module Builder
enum MacroBuilder {
    static func build() -> MacroViewController {
        let view = MacroViewController(nibName: "MacroViewController", bundle: nil)
        return setup(view: view)
    }
    
    @discardableResult
    static func setup(view: MacroViewController) -> MacroViewController {
        let presenter = MacroPresenter()
        let interactor = MacroInteractor()
        let router = MacroRouter()

        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        return view
    }
}
