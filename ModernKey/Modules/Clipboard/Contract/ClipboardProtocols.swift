//
//  ClipboardProtocols.swift
//  ModernKey
//
//  VIPER Protocols for Clipboard module.
//

import Cocoa

// MARK: - View
protocol ClipboardPanelViewProtocol: AnyObject {
    func displayItems(_ items: [String])
    func updateSelection(index: Int)
    func showPreview(text: String, forRow: Int)
    func hidePreview()
    func hidePanel()
    func showPanel(at caretPoint: CGPoint?)
}

// MARK: - Presenter
protocol ClipboardPresenterProtocol: AnyObject {
    var isOpen: Bool { get }
    func viewDidLoad()
    func toggle(at caretPoint: CGPoint?)
    func open(at caretPoint: CGPoint?)
    func close()
    func didSearch(query: String)
    func didSelectRow(_ index: Int)
    func didConfirmSelection(index: Int)
    func didClearHistory()
    func handleKeyDown(keyCode: UInt16, flags: NSEvent.ModifierFlags) -> Bool
}

// MARK: - Interactor
protocol ClipboardInteractorInputProtocol: AnyObject {
    func getHistory() -> [String]
    func filterHistory(query: String) -> [String]
    func pasteItem(text: String)
    func clearHistory()
    func startMonitoring()
    func stopMonitoring()
}

protocol ClipboardInteractorOutputProtocol: AnyObject {
    func didUpdateHistory(_ items: [String])
}

// MARK: - Router
protocol ClipboardRouterProtocol: AnyObject {
    func closePanel()
}
