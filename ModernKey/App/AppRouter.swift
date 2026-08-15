//
//  AppRouter.swift
//  ModernKey
//
//  Global App Router / Wireframe to instantiate and present VIPER module windows.
//

import Cocoa

protocol AppRouterProtocol {
    func openControlPanel()
    func openMacroWindow()
    func openConvertToolWindow()
    func openAboutWindow()
    func openAppInputModeWindow()
    func showQuickConvertResult(success: Bool)
}

final class AppRouter: AppRouterProtocol {
    static let shared = AppRouter()
    
    private var mainWC: NSWindowController?
    private var macroWC: NSWindowController?
    private var convertWC: NSWindowController?
    private var aboutWC: NSWindowController?
    private var appInputModeWC: NSWindowController?
    
    private init() {}
    
    /// Wraps a XIB-loaded view controller in a floating utility window.
    private func makeWindowController(_ viewController: NSViewController,
                                      title: String,
                                      styleMask: NSWindow.StyleMask = [.titled, .closable]) -> NSWindowController {
        let window = NSWindow(contentViewController: viewController)
        window.styleMask = styleMask
        window.title = title
        window.isReleasedWhenClosed = false
        window.center()
        return NSWindowController(window: window)
    }
    
    /// Creates the window controller on first use, then brings it to the front.
    private func show(_ windowController: inout NSWindowController?,
                      make: () -> NSWindowController) {
        if windowController == nil {
            windowController = make()
        }
        guard let window = windowController?.window, !window.isVisible else { return }
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
    }
    
    func openControlPanel() {
        show(&mainWC) {
            let vc = ControlPanelBuilder.build()
            let wc = self.makeWindowController(vc, title: "Bảng điều khiển", styleMask: [.titled, .closable, .miniaturizable])
            let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            wc.window?.title = "OpenKeySwift \(shortVersion) - Bộ gõ Tiếng Việt"
            return wc
        }
    }
    
    func openMacroWindow() {
        show(&macroWC) {
            let vc = MacroBuilder.build()
            return self.makeWindowController(vc, title: "Bảng gõ tắt")
        }
    }
    
    func openConvertToolWindow() {
        show(&convertWC) {
            let vc = ConvertToolBuilder.build()
            return self.makeWindowController(vc, title: "Công cụ chuyển mã")
        }
    }
    
    func openAboutWindow() {
        show(&aboutWC) {
            let vc = AboutBuilder.build()
            return self.makeWindowController(vc, title: "Thông tin phần mềm")
        }
    }
    
    func openAppInputModeWindow() {
        show(&appInputModeWC) {
            let vc = AppInputModeBuilder.build()
            return self.makeWindowController(vc, title: "Quản lý Chế độ Gõ theo Ứng dụng", styleMask: [.titled, .closable, .miniaturizable, .resizable])
        }
    }
    
    func showQuickConvertResult(success: Bool) {
        if success {
            if !convertToolDontAlertWhenCompleted {
                OpenKeyManager.showMessage(nil, message: "Chuyển mã thành công!", subMsg: "Kết quả đã được lưu trong clipboard.")
            }
        } else {
            OpenKeyManager.showMessage(nil, message: "Không có dữ liệu trong clipboard!", subMsg: "Hãy sao chép một đoạn text để chuyển đổi!")
        }
    }
}
