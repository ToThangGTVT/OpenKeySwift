//
//  AppInputModePresenter.swift
//  ModernKey
//
//  VIPER Presenter for AppInputMode module.
//

import Cocoa

final class AppInputModePresenter: AppInputModePresenterProtocol, AppInputModeInteractorOutputProtocol {
    weak var view: AppInputModeViewProtocol?
    var interactor: AppInputModeInteractorInputProtocol?
    var router: AppInputModeRouterProtocol?
    
    private var allItems: [AppInputModeItem] = []
    private var currentQuery: String = ""
    
    func viewDidLoad() {
        interactor?.fetchApps()
    }
    
    func didSearch(query: String) {
        self.currentQuery = query.trimmingCharacters(in: .whitespaces)
        publishState()
    }
    
    func didToggleLanguage(bundleId: String, isVietnamese: Bool) {
        interactor?.setAppLanguage(bundleId: bundleId, isVietnamese: isVietnamese)
    }
    
    func didTapAddApp(window: NSWindow?) {
        guard let runningApps = interactor?.getRunningApps() else { return }
        
        // Filter out apps that are already in allItems
        let existingBundleIds = Set(allItems.map { $0.bundleId })
        let availableRunning = runningApps.filter { !existingBundleIds.contains($0.bundleId) }
        
        router?.showAddAppOptions(runningApps: availableRunning, window: window) { [weak self] selectedBundleId in
            guard let self = self, let bundleId = selectedBundleId, !bundleId.isEmpty else { return }
            self.interactor?.addApp(bundleId: bundleId, isVietnamese: false) // Default to English [E] for added dev/special apps
        }
    }
    
    func didTapDelete(bundleId: String) {
        interactor?.removeApp(bundleId: bundleId)
    }
    
    func didTapClearAll(window: NSWindow?) {
        router?.showConfirmClearAllDialog(window: window) { [weak self] confirmed in
            guard let self = self, confirmed else { return }
            self.interactor?.clearAllApps()
        }
    }
    
    // MARK: - Interactor Output
    func didFetchApps(_ items: [AppInputModeItem]) {
        self.allItems = items
        publishState()
    }
    
    private func publishState() {
        let filtered: [AppInputModeItem]
        if currentQuery.isEmpty {
            filtered = allItems
        } else {
            let normalizedQuery = currentQuery.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            filtered = allItems.filter {
                let name = $0.appName.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                let bid = $0.bundleId.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                return name.contains(normalizedQuery) || bid.contains(normalizedQuery)
            }
        }
        
        let vietCount = allItems.filter { $0.isVietnamese }.count
        let engCount = allItems.count - vietCount
        let stats = AppInputModeStats(
            totalCount: allItems.count,
            vietnameseCount: vietCount,
            englishCount: engCount
        )
        
        view?.displayItems(filtered, stats: stats)
    }
}
