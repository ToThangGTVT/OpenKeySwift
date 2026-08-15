//
//  AboutRouter.swift
//  ModernKey
//
//  VIPER Router for About module.
//

import Cocoa

final class AboutRouter: AboutRouterProtocol {
    func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
    
    func showUpdateAlert(needUpdating: Bool, newVersion: String, parentWindow: NSWindow?, confirmUpdate: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = needUpdating ? "OpenKeySwift có phiên bản mới (\(newVersion)), bạn có muốn cập nhật không?" : "Bạn đang dùng phiên bản mới nhất!"
        alert.informativeText = needUpdating ? "Bấm 'Có' để cập nhật OpenKeySwift." : ""
        
        if !needUpdating {
            alert.addButton(withTitle: "OK")
        } else {
            alert.addButton(withTitle: "Có")
            alert.addButton(withTitle: "Không")
        }
        
        if let parent = parentWindow {
            alert.beginSheetModal(for: parent) { returnCode in
                if returnCode.rawValue == 1000 && needUpdating {
                    confirmUpdate()
                }
            }
        } else {
            alert.window.makeKeyAndOrderFront(nil)
            alert.window.level = .statusBar
            let res = alert.runModal()
            if res.rawValue == 1000 && needUpdating {
                confirmUpdate()
            }
        }
    }
}
