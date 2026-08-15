//
//  AboutViewController.swift
//  ModernKey
//
//  VIPER View for About module.
//

import Cocoa

@objc(AboutViewController)
class AboutViewController: NSViewController, AboutViewProtocol {

    @IBOutlet weak var VersionInfo: NSTextField!
    @IBOutlet weak var CheckNewVersionButton: NSButton!
    @IBOutlet weak var CheckUpdateOnStatus: NSButton!

    var presenter: AboutPresenterProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        if presenter == nil {
            _ = AboutBuilder.setup(view: self)
        }
        presenter?.viewDidLoad()
    }

    // MARK: - AboutViewProtocol
    func displayAboutInfo(_ info: AboutInfo) {
        VersionInfo?.stringValue = info.versionText
        CheckUpdateOnStatus?.state = info.isCheckUpdateOnStartup ? .on : .off
    }

    func setCheckingState(isChecking: Bool) {
        CheckNewVersionButton?.isEnabled = !isChecking
        CheckNewVersionButton?.title = isChecking ? "Đang kiểm tra..." : "Kiểm tra bản mới..."
    }

    // MARK: - Actions
    @IBAction func onHomePage(_ sender: Any) {
        presenter?.didTapHomePage()
    }

    @IBAction func onFanPage(_ sender: Any) {
        presenter?.didTapFanPage()
    }

    @IBAction func onLatestReleaseVersion(_ sender: Any) {
        presenter?.didTapReleases()
    }

    @IBAction func onCheckUpdateOnStartup(_ sender: NSButton) {
        presenter?.didToggleCheckUpdateOnStartup(isOn: sender.state == .on)
    }

    @IBAction func onCheckNewVersion(_ sender: Any) {
        presenter?.didTapCheckNewVersion(window: self.view.window)
    }
}

// MARK: - Module Builder
enum AboutBuilder {
    static func build() -> AboutViewController {
        let view = AboutViewController(nibName: "AboutViewController", bundle: nil)
        return setup(view: view)
    }
    
    @discardableResult
    static func setup(view: AboutViewController) -> AboutViewController {
        let presenter = AboutPresenter()
        let interactor = AboutInteractor()
        let router = AboutRouter()

        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        return view
    }
}
