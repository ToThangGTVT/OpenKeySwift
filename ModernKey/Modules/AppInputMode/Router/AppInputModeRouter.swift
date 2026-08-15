//
//  AppInputModeRouter.swift
//  ModernKey
//
//  VIPER Router for AppInputMode module.
//

import Cocoa
import UniformTypeIdentifiers

final class AppInputModeRouter: AppInputModeRouterProtocol {
    func showAddAppOptions(runningApps: [(bundleId: String, appName: String, icon: NSImage?)], window: NSWindow?, completion: @escaping (String?) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Thêm Ứng dụng"
        alert.informativeText = "Chọn một ứng dụng đang mở hoặc duyệt file từ thư mục /Applications."
        alert.addButton(withTitle: "Thêm")
        alert.addButton(withTitle: "Duyệt tìm...")
        alert.addButton(withTitle: "Huỷ")
        
        let popUp = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 26))
        
        if runningApps.isEmpty {
            popUp.addItem(withTitle: "Không có ứng dụng nào khác đang chạy")
            popUp.isEnabled = false
        } else {
            for app in runningApps {
                let item = NSMenuItem(title: app.appName, action: nil, keyEquivalent: "")
                item.representedObject = app.bundleId
                if let icon = app.icon {
                    icon.size = NSSize(width: 16, height: 16)
                    item.image = icon
                }
                popUp.menu?.addItem(item)
            }
        }
        
        alert.accessoryView = popUp
        
        let handleResponse: (NSApplication.ModalResponse) -> Void = { [weak self] (response: NSApplication.ModalResponse) in
            if response == .alertFirstButtonReturn {
                // "Thêm"
                if let selectedBundleId = popUp.selectedItem?.representedObject as? String {
                    completion(selectedBundleId)
                } else {
                    completion(nil)
                }
            } else if response == .alertSecondButtonReturn {
                // "Duyệt tìm..."
                self?.showAppFileOpenPanel(window: window, completion: completion)
            } else {
                completion(nil)
            }
        }
        
        if let win = window {
            alert.beginSheetModal(for: win, completionHandler: handleResponse)
        } else {
            let res = alert.runModal()
            handleResponse(res)
        }
    }
    
    func showAppFileOpenPanel(window: NSWindow?, completion: @escaping (String?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.message = "Chọn ứng dụng (.app) để cấu hình chế độ gõ"
        openPanel.prompt = "Chọn"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        if #available(macOS 11.0, *) {
            openPanel.allowedContentTypes = [UTType.applicationBundle, UTType.application]
        } else {
            openPanel.allowedFileTypes = ["app"]
        }
        
        let handlePanelResult = { (response: NSApplication.ModalResponse) in
            guard response == .OK, let url = openPanel.url,
                  let bundle = Bundle(url: url),
                  let bundleId = bundle.bundleIdentifier else {
                completion(nil)
                return
            }
            completion(bundleId)
        }
        
        if let win = window {
            openPanel.beginSheetModal(for: win, completionHandler: handlePanelResult)
        } else {
            openPanel.makeKeyAndOrderFront(nil)
            openPanel.level = .floating
            let res = openPanel.runModal()
            handlePanelResult(res)
        }
    }
    
    func showConfirmClearAllDialog(window: NSWindow?, completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Xoá danh sách ứng dụng?"
        alert.informativeText = "Tất cả các cài đặt chế độ gõ riêng cho từng ứng dụng sẽ bị xoá."
        alert.addButton(withTitle: "Xoá tất cả")
        alert.addButton(withTitle: "Huỷ")
        alert.alertStyle = .warning
        
        if let win = window {
            alert.beginSheetModal(for: win) { response in
                completion(response == .alertFirstButtonReturn)
            }
        } else {
            let res = alert.runModal()
            completion(res == .alertFirstButtonReturn)
        }
    }
}
