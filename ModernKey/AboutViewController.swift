import Cocoa

@objc(AboutViewController)
class AboutViewController: NSViewController {

    @IBOutlet weak var VersionInfo: NSTextField!
    @IBOutlet weak var CheckNewVersionButton: NSButton!
    @IBOutlet weak var CheckUpdateOnStatus: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let buildDate = OpenKeyManager.getBuildDate()
        
        VersionInfo.stringValue = "Phiên bản \(shortVersion) (build \(version)) - Ngày cập nhật \(buildDate)"
        
        let dontCheckUpdate = UserDefaults.standard.integer(forKey: "DontCheckUpdate")
        CheckUpdateOnStatus.state = dontCheckUpdate != 0 ? .off : .on
    }

    @IBAction func onHomePage(_ sender: Any) {
        if let url = URL(string: "https://github.com/tuyenvm/OpenKey") {
            NSWorkspace.shared.open(url)
        }
    }

    @IBAction func onFanPage(_ sender: Any) {
        if let url = URL(string: "https://www.facebook.com/OpenKeyVN") {
            NSWorkspace.shared.open(url)
        }
    }

    @IBAction func onLatestReleaseVersion(_ sender: Any) {
        if let url = URL(string: "https://github.com/tuyenvm/OpenKey/releases") {
            NSWorkspace.shared.open(url)
        }
    }

    @IBAction func onCheckUpdateOnStartup(_ sender: NSButton) {
        let val = sender.state == .on ? 0 : 1
        UserDefaults.standard.set(val, forKey: "DontCheckUpdate")
    }

    @IBAction func onCheckNewVersion(_ sender: Any) {
        CheckNewVersionButton.title = "Đang kiểm tra..."
        CheckNewVersionButton.isEnabled = false
        
        OpenKeyManager.checkNewVersion(self.view.window) { [weak self] in
            self?.CheckNewVersionButton.isEnabled = true
            self?.CheckNewVersionButton.title = "Kiểm tra bản mới..."
        }
    }
}
