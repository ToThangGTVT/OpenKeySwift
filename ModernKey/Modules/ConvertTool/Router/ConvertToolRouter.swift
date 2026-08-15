//
//  ConvertToolRouter.swift
//  ModernKey
//
//  VIPER Router for ConvertTool module.
//

import Cocoa

final class ConvertToolRouter: ConvertToolRouterProtocol {
    func showAlert(message: String, subMsg: String, window: NSWindow?) {
        OpenKeyManager.showMessage(window, message: message, subMsg: subMsg)
    }
}
