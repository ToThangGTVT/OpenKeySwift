//
//  AboutInteractor.swift
//  ModernKey
//
//  VIPER Interactor for About module.
//

import Cocoa

final class AboutInteractor: AboutInteractorInputProtocol {
    weak var presenter: AboutInteractorOutputProtocol?
    
    private let updateService: UpdateServiceProtocol
    private let settingsService: SettingsServiceProtocol
    
    init(updateService: UpdateServiceProtocol = UpdateService.shared,
         settingsService: SettingsServiceProtocol = SettingsService.shared) {
        self.updateService = updateService
        self.settingsService = settingsService
    }
    
    func loadAboutInfo() {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let buildDate = OpenKeyManager.getBuildDate()
        let versionText = "Phiên bản \(shortVersion) (build \(version)) - Ngày cập nhật \(buildDate)"
        
        let info = AboutInfo(
            versionText: versionText,
            isCheckUpdateOnStartup: settingsService.checkUpdateOnStartup,
            homePageURL: URL(string: "https://github.com/ToThangGTVT/OpenKeySwift"),
            fanPageURL: URL(string: "https://www.facebook.com/OpenKeyVN"),
            releasesURL: URL(string: "https://github.com/ToThangGTVT/OpenKeySwift/releases")
        )
        presenter?.didLoadAboutInfo(info)
    }
    
    func setCheckUpdateOnStartup(enabled: Bool) {
        settingsService.checkUpdateOnStartup = enabled
    }
    
    func checkNewVersion(parentWindow: NSWindow?) {
        updateService.checkNewVersion(parent: parentWindow) { [weak self] hasUpdate, newVersion, _ in
            self?.presenter?.didCheckVersionResult(hasUpdate: hasUpdate, newVersion: newVersion, parentWindow: parentWindow)
        }
    }
}
