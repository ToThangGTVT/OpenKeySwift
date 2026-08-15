//
//  AccessibilityService.swift
//  ModernKey
//
//  Service to check and request macOS Accessibility permissions.
//

import Cocoa
import ApplicationServices

protocol AccessibilityServiceProtocol {
    func isAccessibilityEnabled() -> Bool
    func openAccessibilityPanel()
    func askPermission(completion: ((Bool) -> Void)?)
}

final class AccessibilityService: AccessibilityServiceProtocol {
    static let shared = AccessibilityService()
    
    private init() {}
    
    func isAccessibilityEnabled() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func openAccessibilityPanel() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    func askPermission(completion: ((Bool) -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = "OpenKeySwift cần bạn cấp quyền để có thể hoạt động!"
        alert.informativeText = "Không cấp quyền ứng dụng vẫn chạy nhưng không gõ được Tiếng Việt."
        alert.addButton(withTitle: "Không")
        alert.addButton(withTitle: "Cấp quyền")
        
        alert.window.makeKeyAndOrderFront(nil)
        alert.window.level = .statusBar
        
        let res = alert.runModal()
        if res.rawValue == 1001 {
            openAccessibilityPanel()
            completion?(true)
        } else {
            completion?(false)
        }
    }
}

// MARK: - Global Compatibility Helpers
func MJAccessibilityIsEnabled() -> Bool {
    return AccessibilityService.shared.isAccessibilityEnabled()
}

func MJAccessibilityOpenPanel() {
    AccessibilityService.shared.openAccessibilityPanel()
}
