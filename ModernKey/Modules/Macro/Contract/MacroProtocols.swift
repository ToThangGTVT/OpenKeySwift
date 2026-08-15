//
//  MacroProtocols.swift
//  ModernKey
//
//  VIPER Protocols for Macro module.
//

import Cocoa

// MARK: - View
protocol MacroViewProtocol: AnyObject {
    func displayMacros(_ items: [MacroItem])
    func setInputFields(key: String, content: String, isEditing: Bool)
    func clearInputFields()
    func setAutoCapsState(isOn: Bool)
    func showMessage(_ message: String)
}

// MARK: - Presenter
protocol MacroPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didSelectMacro(at index: Int)
    func didChangeKeyInput(_ key: String)
    func didTapAddOrUpdate(key: String, content: String)
    func didTapDelete(key: String)
    func didTapLoadFromFile()
    func didTapExportToFile()
    func didToggleAutoCaps(isOn: Bool)
}

// MARK: - Interactor
protocol MacroInteractorInputProtocol: AnyObject {
    func fetchMacros()
    func addMacro(key: String, content: String)
    func deleteMacro(key: String)
    func importFromFile(path: String, keepExisting: Bool)
    func exportToFile(path: String)
    func setAutoCaps(enabled: Bool)
    func isAutoCapsEnabled() -> Bool
    func findMacro(byKey key: String) -> MacroItem?
}

protocol MacroInteractorOutputProtocol: AnyObject {
    func didUpdateMacros(_ items: [MacroItem])
    func didFailWithError(_ message: String)
}

// MARK: - Router
protocol MacroRouterProtocol: AnyObject {
    func showOpenFilePanel(window: NSWindow?, completion: @escaping (String?) -> Void)
    func showSaveFilePanel(window: NSWindow?, completion: @escaping (String?) -> Void)
    func showConfirmKeepExistingDialog(window: NSWindow?, completion: @escaping (Bool) -> Void)
    func showAlert(message: String, window: NSWindow?)
}
