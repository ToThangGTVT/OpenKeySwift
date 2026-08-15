//
//  ClipboardPresenter.swift
//  ModernKey
//
//  VIPER Presenter for Clipboard module.
//

import Cocoa
import Carbon

final class ClipboardPresenter: ClipboardPresenterProtocol {
    weak var view: ClipboardPanelViewProtocol?
    var interactor: ClipboardInteractorInputProtocol?
    var router: ClipboardRouterProtocol?
    
    private var filteredItems: [String] = []
    private var query = ""
    private var _isOpen = false
    
    var isOpen: Bool {
        return _isOpen
    }
    
    func viewDidLoad() {
        // Initial load
    }
    
    func toggle(at caretPoint: CGPoint?) {
        if isOpen {
            close()
        } else {
            open(at: caretPoint)
        }
    }
    
    func open(at caretPoint: CGPoint?) {
        query = ""
        let history = interactor?.getHistory() ?? []
        filteredItems = history
        _isOpen = true
        view?.displayItems(filteredItems)
        view?.showPanel(at: caretPoint)
        if !filteredItems.isEmpty {
            view?.updateSelection(index: 0)
        }
    }
    
    func close() {
        _isOpen = false
        view?.hidePreview()
        view?.hidePanel()
        router?.closePanel()
    }
    
    func didSearch(query: String) {
        self.query = query
        filteredItems = interactor?.filterHistory(query: query) ?? []
        view?.displayItems(filteredItems)
        if !filteredItems.isEmpty {
            view?.updateSelection(index: 0)
        }
    }
    
    func didSelectRow(_ index: Int) {
        guard filteredItems.indices.contains(index) else { return }
        view?.showPreview(text: filteredItems[index], forRow: index)
    }
    
    func didConfirmSelection(index: Int) {
        guard filteredItems.indices.contains(index) else { return }
        let text = filteredItems[index]
        close()
        interactor?.pasteItem(text: text)
    }
    
    func didClearHistory() {
        interactor?.clearHistory()
        filteredItems = []
        view?.displayItems([])
    }
    
    func handleKeyDown(keyCode: UInt16, flags: NSEvent.ModifierFlags) -> Bool {
        guard isOpen else { return false }
        
        switch Int(keyCode) {
        case kVK_Escape:
            close()
            return true
            
        case kVK_Return, kVK_ANSI_KeypadEnter:
            // Handled by view's current selection
            return true
            
        case kVK_Delete:
            if !query.isEmpty {
                query.removeLast()
                didSearch(query: query)
            }
            return true
            
        default:
            return false
        }
    }
}

// MARK: - Interactor Output
extension ClipboardPresenter: ClipboardInteractorOutputProtocol {
    func didUpdateHistory(_ items: [String]) {
        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = interactor?.filterHistory(query: query) ?? []
        }
        if isOpen {
            view?.displayItems(filteredItems)
        }
    }
}
