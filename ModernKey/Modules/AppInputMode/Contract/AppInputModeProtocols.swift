//
//  AppInputModeProtocols.swift
//  ModernKey
//
//  VIPER Protocols for AppInputMode module.
//

import Cocoa

// MARK: - View Protocol
protocol AppInputModeViewProtocol: AnyObject {
    var presenter: AppInputModePresenterProtocol? { get set }
    
    func displayItems(_ items: [AppInputModeItem], stats: AppInputModeStats)
    func showMessage(_ message: String)
}

// MARK: - Presenter Protocol
protocol AppInputModePresenterProtocol: AnyObject {
    var view: AppInputModeViewProtocol? { get set }
    var interactor: AppInputModeInteractorInputProtocol? { get set }
    var router: AppInputModeRouterProtocol? { get set }
    
    func viewDidLoad()
    func didSearch(query: String)
    func didToggleLanguage(bundleId: String, isVietnamese: Bool)
    func didTapAddApp(window: NSWindow?)
    func didTapDelete(bundleId: String)
    func didTapClearAll(window: NSWindow?)
}

// MARK: - Interactor Protocols
protocol AppInputModeInteractorInputProtocol: AnyObject {
    var presenter: AppInputModeInteractorOutputProtocol? { get set }
    
    func fetchApps()
    func setAppLanguage(bundleId: String, isVietnamese: Bool)
    func addApp(bundleId: String, isVietnamese: Bool)
    func removeApp(bundleId: String)
    func clearAllApps()
    func getRunningApps() -> [(bundleId: String, appName: String, icon: NSImage?)]
}

protocol AppInputModeInteractorOutputProtocol: AnyObject {
    func didFetchApps(_ items: [AppInputModeItem])
}

// MARK: - Router Protocol
protocol AppInputModeRouterProtocol: AnyObject {
    func showAddAppOptions(runningApps: [(bundleId: String, appName: String, icon: NSImage?)], window: NSWindow?, completion: @escaping (String?) -> Void)
    func showAppFileOpenPanel(window: NSWindow?, completion: @escaping (String?) -> Void)
    func showConfirmClearAllDialog(window: NSWindow?, completion: @escaping (Bool) -> Void)
}
