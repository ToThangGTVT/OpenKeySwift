//
//  AboutProtocols.swift
//  ModernKey
//
//  VIPER Protocols for About module.
//

import Cocoa

// MARK: - View
protocol AboutViewProtocol: AnyObject {
    func displayAboutInfo(_ info: AboutInfo)
    func setCheckingState(isChecking: Bool)
}

// MARK: - Presenter
protocol AboutPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didTapHomePage()
    func didTapFanPage()
    func didTapReleases()
    func didToggleCheckUpdateOnStartup(isOn: Bool)
    func didTapCheckNewVersion(window: NSWindow?)
}

// MARK: - Interactor
protocol AboutInteractorInputProtocol: AnyObject {
    func loadAboutInfo()
    func setCheckUpdateOnStartup(enabled: Bool)
    func checkNewVersion(parentWindow: NSWindow?)
}

protocol AboutInteractorOutputProtocol: AnyObject {
    func didLoadAboutInfo(_ info: AboutInfo)
    func didCheckVersionResult(hasUpdate: Bool, newVersion: String, parentWindow: NSWindow?)
}

// MARK: - Router
protocol AboutRouterProtocol: AnyObject {
    func openURL(_ url: URL)
    func showUpdateAlert(needUpdating: Bool, newVersion: String, parentWindow: NSWindow?, confirmUpdate: @escaping () -> Void)
}
