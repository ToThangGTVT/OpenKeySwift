import Cocoa
import CoreGraphics

class OpenKeyManager: NSObject {
    static var _isInited = false
    static var eventTap: CFMachPort?
    static var runLoopSource: CFRunLoopSource?
    
    @objc class func isInited() -> Bool {
        return _isInited
    }
    
    @objc class func initEventTap() -> Bool {
        if _isInited { return true }
        
        OpenKeyInit()
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue) |
                        (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.rightMouseDown.rawValue) |
                        (1 << CGEventType.leftMouseDragged.rawValue) |
                        (1 << CGEventType.rightMouseDragged.rawValue)
        
        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                     place: .headInsertEventTap,
                                     options: .defaultTap,
                                     eventsOfInterest: CGEventMask(eventMask),
                                     callback: OpenKeyCallback,
                                     userInfo: nil)

        guard let eventTap = eventTap else {
            FileHandle.standardError.write("failed to create event tap\n".data(using: .utf8)!)
            return false
        }

        _isInited = true

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        return true
    }

    /// The system disables the tap when our callback is too slow; turn it back on.
    class func reEnableEventTap() {
        guard let eventTap = eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    @objc class func stopEventTap() -> Bool {
        if _isInited {
            if let rl = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rl, .commonModes)
                runLoopSource = nil
            }
            if let et = eventTap {
                CGEvent.tapEnable(tap: et, enable: false)
                CFMachPortInvalidate(et)
                eventTap = nil
            }
            _isInited = false
        }
        return true
    }
    
    @objc class func getTableCodes() -> [String] {
        return [
            "Unicode",
            "TCVN3 (ABC)",
            "VNI Windows",
            "Unicode tổ hợp",
            "Vietnamese Locale CP 1258"
        ]
    }
    
    @objc class func getBuildDate() -> String {
        guard let date = OK_BuildDate() else { return "" }
        return String(cString: date)
    }
    
    @objc class func showMessage(_ window: NSWindow?, message: String, subMsg: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = subMsg
        alert.addButton(withTitle: "OK")
        
        if let win = window {
            alert.beginSheetModal(for: win) { _ in }
        } else {
            alert.runModal()
        }
    }
    
    @objc class func quickConvert() -> Bool {
        let pasteboard = NSPasteboard.general
        var htmlString = pasteboard.string(forType: .html)
        var rawString = pasteboard.string(forType: .string)
        var converted = false
        
        if let hs = htmlString {
            htmlString = ConvertUtil(hs)
            converted = true
        }
        if let rs = rawString {
            rawString = ConvertUtil(rs)
            converted = true
        }
        
        if converted {
            pasteboard.clearContents()
            if let hs = htmlString {
                pasteboard.setString(hs, forType: .html)
            }
            if let rs = rawString {
                pasteboard.setString(rs, forType: .string)
            }
            return true
        }
        return false
    }
    
    @objc class func checkNewVersion(_ parent: NSWindow?, callbackFunc: (() -> Void)?) {
        guard let url = URL(string: "https://raw.githubusercontent.com/tuyenvm/OpenKey/master/version.json") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else { return }
            
            do {
                if let results = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let ver = results["latestVersion"] as? [String: Any],
                   let versionCodeString = ver["versionCode"] as? String,
                   let versionCode = Int(versionCodeString) {
                    
                    let currentVersionCodeString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
                    let currentVersionCode = Int(currentVersionCodeString) ?? 0
                    
                    DispatchQueue.main.async {
                        callbackFunc?()
                        if versionCode > currentVersionCode || callbackFunc != nil {
                            showUpdateMessage(parent, needUpdating: versionCode > currentVersionCode, newVersion: ver["versionName"] as? String ?? "")
                        }
                    }
                }
            } catch {
                print("JSON parsing error")
            }
        }.resume()
    }
    
    class func showUpdateMessage(_ parent: NSWindow?, needUpdating: Bool, newVersion: String) {
        let alert = NSAlert()
        alert.messageText = needUpdating ? "OpenKey Có phiên bản mới (\(newVersion)), bạn có muốn cập nhật không?" : "Bạn đang dùng phiên bản mới nhất!"
        alert.informativeText = needUpdating ? "Bấm 'Có' để cập nhật OpenKey." : ""
        
        if !needUpdating {
            alert.addButton(withTitle: "OK")
        } else {
            alert.addButton(withTitle: "Có")
            alert.addButton(withTitle: "Không")
        }
        
        if let p = parent {
            alert.beginSheetModal(for: p) { returnCode in
                if returnCode.rawValue == 1000 && needUpdating {
                    launchUpdateHelper()
                }
            }
        } else {
            alert.window.makeKeyAndOrderFront(nil)
            alert.window.level = .statusBar
            let res = alert.runModal()
            if res.rawValue == 1000 && needUpdating {
                launchUpdateHelper()
            }
        }
    }
    
    class func launchUpdateHelper() {
        let target = getApplicationSupportFolder() + "/OpenKeyUpdate.app"
        try? FileManager.default.removeItem(atPath: target)
        
        if !FileManager.default.fileExists(atPath: target) {
            try? FileManager.default.createDirectory(atPath: getApplicationSupportFolder(), withIntermediateDirectories: true, attributes: nil)
            try? FileManager.default.copyItem(atPath: getUpdateBundlePath(), toPath: target)
        }
        
        // NOTE: must be a file URL — the Application Support path contains a space.
        let workspace = NSWorkspace.shared
        let url = URL(fileURLWithPath: target)
        let config = [NSWorkspace.LaunchConfigurationKey.arguments: ["yeah"]]
        _ = try? workspace.launchApplication(at: url, options: [], configuration: config)
        
        NSApp.terminate(nil)
    }
    
    class func getApplicationSupportFolder() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        return (paths.first ?? "") + "/OpenKey"
    }
    
    class func getUpdateBundlePath() -> String {
        return Bundle.main.bundlePath + "/Contents/Library/LoginItems/OpenKeyUpdate.app"
    }
}
