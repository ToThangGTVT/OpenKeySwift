//
//  ClipboardInteractor.swift
//  ModernKey
//
//  VIPER Interactor for Clipboard module.
//

import Cocoa

final class ClipboardInteractor: ClipboardInteractorInputProtocol {
    weak var presenter: ClipboardInteractorOutputProtocol?
    
    private let clipboardService: ClipboardServiceProtocol
    
    init(clipboardService: ClipboardServiceProtocol = ClipboardService.shared) {
        self.clipboardService = clipboardService
        clipboardService.addObserver(observer: self, selector: #selector(onHistoryUpdated))
    }
    
    deinit {
        clipboardService.removeObserver(observer: self)
    }
    
    @objc private func onHistoryUpdated() {
        presenter?.didUpdateHistory(clipboardService.history)
    }
    
    func getHistory() -> [String] {
        return clipboardService.history
    }
    
    func filterHistory(query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return clipboardService.history }
        return clipboardService.history.filter {
            $0.localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    func pasteItem(text: String) {
        clipboardService.copyAndPaste(item: text)
    }
    
    func clearHistory() {
        clipboardService.clearHistory()
    }
    
    func startMonitoring() {
        clipboardService.start()
    }
    
    func stopMonitoring() {
        clipboardService.stop()
    }
}
