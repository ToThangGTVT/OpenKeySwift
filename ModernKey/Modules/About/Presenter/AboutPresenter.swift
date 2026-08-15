//
//  AboutPresenter.swift
//  ModernKey
//
//  VIPER Presenter for About module.
//

import Cocoa

final class AboutPresenter: AboutPresenterProtocol {
    weak var view: AboutViewProtocol?
    var interactor: AboutInteractorInputProtocol?
    var router: AboutRouterProtocol?
    
    private var currentInfo: AboutInfo?
    
    func viewDidLoad() {
        interactor?.loadAboutInfo()
    }
    
    func didTapHomePage() {
        guard let url = currentInfo?.homePageURL else { return }
        router?.openURL(url)
    }
    
    func didTapFanPage() {
        guard let url = currentInfo?.fanPageURL else { return }
        router?.openURL(url)
    }
    
    func didTapReleases() {
        guard let url = currentInfo?.releasesURL else { return }
        router?.openURL(url)
    }
    
    func didToggleCheckUpdateOnStartup(isOn: Bool) {
        interactor?.setCheckUpdateOnStartup(enabled: isOn)
    }
    
    func didTapCheckNewVersion(window: NSWindow?) {
        view?.setCheckingState(isChecking: true)
        interactor?.checkNewVersion(parentWindow: window)
    }
}

// MARK: - Interactor Output
extension AboutPresenter: AboutInteractorOutputProtocol {
    func didLoadAboutInfo(_ info: AboutInfo) {
        self.currentInfo = info
        view?.displayAboutInfo(info)
    }
    
    func didCheckVersionResult(hasUpdate: Bool, newVersion: String, parentWindow: NSWindow?) {
        view?.setCheckingState(isChecking: false)
        router?.showUpdateAlert(needUpdating: hasUpdate, newVersion: newVersion, parentWindow: parentWindow) {
            UpdateService.shared.launchUpdateHelper()
        }
    }
}
