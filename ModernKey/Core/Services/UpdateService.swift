//
//  UpdateService.swift
//  ModernKey
//
//  Service to check for app updates and launch update helper.
//

import Cocoa

protocol UpdateServiceProtocol {
    func checkNewVersion(parent: NSWindow?, completion: ((_ hasUpdate: Bool, _ newVersion: String, _ currentVersion: String) -> Void)?)
    func launchUpdateHelper()
}

final class UpdateService: UpdateServiceProtocol {
    static let shared = UpdateService()
    
    private let versionURL = "https://raw.githubusercontent.com/tuyenvm/OpenKey/master/version.json"
    
    private init() {}
    
    func checkNewVersion(parent: NSWindow?, completion: ((_ hasUpdate: Bool, _ newVersion: String, _ currentVersion: String) -> Void)? = nil) {
        guard let url = URL(string: versionURL) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let _ = self,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                DispatchQueue.main.async {
                    completion?(false, "", "")
                }
                return
            }
            
            do {
                if let results = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let ver = results["latestVersion"] as? [String: Any],
                   let versionCodeString = ver["versionCode"] as? String,
                   let versionCode = Int(versionCodeString) {
                    
                    let currentVersionCodeString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
                    let currentVersionCode = Int(currentVersionCodeString) ?? 0
                    let versionName = ver["versionName"] as? String ?? ""
                    let hasUpdate = versionCode > currentVersionCode
                    
                    DispatchQueue.main.async {
                        completion?(hasUpdate, versionName, currentVersionCodeString)
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
                DispatchQueue.main.async {
                    completion?(false, "", "")
                }
            }
        }.resume()
    }
    
    func launchUpdateHelper() {
        let target = getApplicationSupportFolder() + "/OpenKeyUpdate.app"
        try? FileManager.default.removeItem(atPath: target)
        
        if !FileManager.default.fileExists(atPath: target) {
            try? FileManager.default.createDirectory(atPath: getApplicationSupportFolder(), withIntermediateDirectories: true, attributes: nil)
            try? FileManager.default.copyItem(atPath: getUpdateBundlePath(), toPath: target)
        }
        
        let url = URL(fileURLWithPath: target)
        if #available(macOS 10.15, *) {
            let config = NSWorkspace.OpenConfiguration()
            config.arguments = ["yeah"]
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
                DispatchQueue.main.async {
                    NSApp.terminate(nil)
                }
            }
        } else {
            let config = [NSWorkspace.LaunchConfigurationKey.arguments: ["yeah"]]
            _ = try? NSWorkspace.shared.launchApplication(at: url, options: [], configuration: config)
            NSApp.terminate(nil)
        }
    }
    
    private func getApplicationSupportFolder() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        return (paths.first ?? "") + "/OpenKey"
    }
    
    private func getUpdateBundlePath() -> String {
        return Bundle.main.bundlePath + "/Contents/Library/LoginItems/OpenKeyUpdate.app"
    }
}
