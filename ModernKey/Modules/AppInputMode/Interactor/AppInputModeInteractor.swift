//
//  AppInputModeInteractor.swift
//  ModernKey
//
//  VIPER Interactor for AppInputMode module.
//

import Cocoa

final class AppInputModeInteractor: AppInputModeInteractorInputProtocol {
    weak var presenter: AppInputModeInteractorOutputProtocol?
    
    func fetchApps() {
        var items: [AppInputModeItem] = []
        let count = OK_GetSmartSwitchKeyCount()
        
        for i in 0..<count {
            guard let cStr = OK_GetSmartSwitchKeyBundleId(i) else { continue }
            let bundleId = String(cString: cStr)
            guard !bundleId.isEmpty else { continue }
            
            let val = OK_GetSmartSwitchKeyLanguage(i)
            let isVietnamese = (val & 0x01) == 1
            let codeTable = Int(val >> 1)
            
            let appName = resolveAppName(for: bundleId)
            let icon = resolveAppIcon(for: bundleId)
            
            items.append(AppInputModeItem(
                bundleId: bundleId,
                appName: appName,
                icon: icon,
                isVietnamese: isVietnamese,
                codeTable: codeTable
            ))
        }
        
        // Sort items by appName
        items.sort { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
        presenter?.didFetchApps(items)
    }
    
    func setAppLanguage(bundleId: String, isVietnamese: Bool) {
        let currentStatus = OK_GetAppInputMethodStatus(bundleId, isVietnamese ? 1 : 0)
        let codeTable = (currentStatus != -1) ? (currentStatus >> 1) : Int32(vCodeTable)
        let newStatus = (isVietnamese ? 1 : 0) | (Int(codeTable) << 1)
        
        OK_SetAppInputMethodStatus(bundleId, Int32(newStatus))
        saveSmartSwitchKeyData()
        fetchApps()
    }
    
    func addApp(bundleId: String, isVietnamese: Bool) {
        let codeTable = Int(vCodeTable)
        let newStatus = (isVietnamese ? 1 : 0) | (codeTable << 1)
        OK_SetAppInputMethodStatus(bundleId, Int32(newStatus))
        saveSmartSwitchKeyData()
        fetchApps()
    }
    
    func removeApp(bundleId: String) {
        OK_RemoveAppInputMethodStatus(bundleId)
        saveSmartSwitchKeyData()
        fetchApps()
    }
    
    func clearAllApps() {
        OK_ClearAllAppInputMethodStatus()
        saveSmartSwitchKeyData()
        fetchApps()
    }
    
    func getRunningApps() -> [(bundleId: String, appName: String, icon: NSImage?)] {
        let running = NSWorkspace.shared.runningApplications
        var result: [(bundleId: String, appName: String, icon: NSImage?)] = []
        
        for app in running {
            guard let bid = app.bundleIdentifier, !bid.isEmpty,
                  let name = app.localizedName, !name.isEmpty,
                  app.activationPolicy == .regular else { continue }
            
            let icon = app.icon
            result.append((bundleId: bid, appName: name, icon: icon))
        }
        
        result.sort { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
        return result
    }
    
    // MARK: - App Helpers
    private func resolveAppName(for bundleId: String) -> String {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            let appBundle = Bundle(url: appUrl)
            if let displayName = appBundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !displayName.isEmpty {
                return displayName
            }
            if let bundleName = appBundle?.object(forInfoDictionaryKey: "CFBundleName") as? String, !bundleName.isEmpty {
                return bundleName
            }
            return appUrl.deletingPathExtension().lastPathComponent
        }
        // Fallback: extract readable name from bundleId (e.g. com.apple.dt.Xcode -> Xcode)
        let parts = bundleId.split(separator: ".")
        return parts.last.map(String.init) ?? bundleId
    }
    
    private func resolveAppIcon(for bundleId: String) -> NSImage? {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: appUrl.path)
        }
        if #available(macOS 12.0, *) {
            return NSWorkspace.shared.icon(for: .application)
        } else {
            return NSWorkspace.shared.icon(forFileType: "app")
        }
    }
}
