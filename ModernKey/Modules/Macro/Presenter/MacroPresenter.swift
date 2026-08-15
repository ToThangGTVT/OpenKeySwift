//
//  MacroPresenter.swift
//  ModernKey
//
//  VIPER Presenter for Macro module.
//

import Cocoa

final class MacroPresenter: MacroPresenterProtocol {
    weak var view: MacroViewProtocol?
    var interactor: MacroInteractorInputProtocol?
    var router: MacroRouterProtocol?
    
    private var macros: [MacroItem] = []
    
    func viewDidLoad() {
        if let isAutoCaps = interactor?.isAutoCapsEnabled() {
            view?.setAutoCapsState(isOn: isAutoCaps)
        }
        interactor?.fetchMacros()
    }
    
    func didSelectMacro(at index: Int) {
        guard macros.indices.contains(index) else { return }
        let item = macros[index]
        view?.setInputFields(key: item.key, content: item.content, isEditing: true)
    }
    
    func didChangeKeyInput(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = interactor?.findMacro(byKey: trimmed) {
            view?.setInputFields(key: existing.key, content: existing.content, isEditing: true)
        } else {
            view?.setInputFields(key: key, content: "", isEditing: false)
        }
    }
    
    func didTapAddOrUpdate(key: String, content: String) {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty && !trimmedContent.isEmpty else {
            view?.showMessage("Bạn hãy nhập từ cần gõ tắt!")
            return
        }
        
        interactor?.addMacro(key: trimmedKey, content: trimmedContent)
        view?.clearInputFields()
    }
    
    func didTapDelete(key: String) {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            view?.showMessage("Bạn hãy chọn từ cần xoá!")
            return
        }
        
        interactor?.deleteMacro(key: trimmedKey)
        view?.clearInputFields()
    }
    
    func didTapLoadFromFile() {
        let window = (view as? NSViewController)?.view.window
        router?.showOpenFilePanel(window: window) { [weak self] filePath in
            guard let self = self, let path = filePath else { return }
            self.router?.showConfirmKeepExistingDialog(window: window) { keepExisting in
                self.interactor?.importFromFile(path: path, keepExisting: keepExisting)
                self.view?.clearInputFields()
            }
        }
    }
    
    func didTapExportToFile() {
        let window = (view as? NSViewController)?.view.window
        router?.showSaveFilePanel(window: window) { [weak self] filePath in
            guard let self = self, let path = filePath else { return }
            self.interactor?.exportToFile(path: path)
        }
    }
    
    func didToggleAutoCaps(isOn: Bool) {
        interactor?.setAutoCaps(enabled: isOn)
    }
}

// MARK: - Interactor Output
extension MacroPresenter: MacroInteractorOutputProtocol {
    func didUpdateMacros(_ items: [MacroItem]) {
        self.macros = items
        view?.displayMacros(items)
    }
    
    func didFailWithError(_ message: String) {
        let window = (view as? NSViewController)?.view.window
        router?.showAlert(message: message, window: window)
    }
}
