//
//  MacroRouter.swift
//  ModernKey
//
//  VIPER Router for Macro module.
//

import Cocoa
import UniformTypeIdentifiers

final class MacroRouter: MacroRouterProtocol {
    func showOpenFilePanel(window: NSWindow?, completion: @escaping (String?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.message = "Chọn file dữ liệu gõ tắt"
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        if #available(macOS 11.0, *) {
            openPanel.allowedContentTypes = [.plainText]
        } else {
            openPanel.allowedFileTypes = ["txt"]
        }
        openPanel.isExtensionHidden = false
        openPanel.nameFieldStringValue = "OpenKeyMacro"
        
        if let win = window {
            openPanel.beginSheetModal(for: win) { response in
                completion(response == .OK ? openPanel.url?.path : nil)
            }
        } else {
            openPanel.makeKeyAndOrderFront(nil)
            openPanel.level = .statusBar
            let res = openPanel.runModal()
            completion(res == .OK ? openPanel.url?.path : nil)
        }
    }
    
    func showSaveFilePanel(window: NSWindow?, completion: @escaping (String?) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.message = "Lưu file dữ liệu gõ tắt"
        if #available(macOS 11.0, *) {
            savePanel.allowedContentTypes = [.plainText]
        } else {
            savePanel.allowedFileTypes = ["txt"]
        }
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "OpenKeyMacro"
        
        if let win = window {
            savePanel.beginSheetModal(for: win) { response in
                completion(response == .OK ? savePanel.url?.path : nil)
            }
        } else {
            savePanel.makeKeyAndOrderFront(nil)
            savePanel.level = .statusBar
            let res = savePanel.runModal()
            completion(res == .OK ? savePanel.url?.path : nil)
        }
    }
    
    func showConfirmKeepExistingDialog(window: NSWindow?, completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.informativeText = "Bạn có muốn giữ lại các dữ liệu hiện tại không?"
        alert.addButton(withTitle: "Có")
        alert.addButton(withTitle: "Không")
        alert.messageText = "Dữ liệu gõ tắt"
        alert.alertStyle = .critical
        
        if let win = window {
            alert.beginSheetModal(for: win) { returnCode in
                completion(returnCode.rawValue == 1000)
            }
        } else {
            let res = alert.runModal()
            completion(res.rawValue == 1000)
        }
    }
    
    func showAlert(message: String, window: NSWindow?) {
        let alert = NSAlert()
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.messageText = "Dữ liệu gõ tắt"
        alert.alertStyle = .critical
        
        if let win = window {
            alert.beginSheetModal(for: win) { _ in }
        } else {
            alert.runModal()
        }
    }
}
