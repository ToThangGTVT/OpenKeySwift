//
//  ControlPanelRouter.swift
//  ModernKey
//
//  VIPER Router for ControlPanel module.
//

import Cocoa

final class ControlPanelRouter: ControlPanelRouterProtocol {
    func openMacroWindow() {
        AppRouter.shared.openMacroWindow()
    }
    
    func openConvertToolWindow() {
        AppRouter.shared.openConvertToolWindow()
    }
    
    func openAboutWindow() {
        AppRouter.shared.openAboutWindow()
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
