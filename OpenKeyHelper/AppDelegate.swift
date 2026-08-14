import Cocoa
import Darwin

let OPENKEY_BUNDLE = "com.utc.open.key"

@main
@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let currentUID = getuid()
        let runningApps = NSWorkspace.shared.runningApplications
        var isRunning = false
        
        for app in runningApps {
            if app.bundleIdentifier == OPENKEY_BUNDLE {
                let pid = app.processIdentifier
                var proc = proc_bsdinfo()
                let size = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &proc, Int32(MemoryLayout<proc_bsdinfo>.size))
                
                if size == MemoryLayout<proc_bsdinfo>.size && proc.pbi_uid == currentUID {
                    isRunning = true
                    break
                }
            }
        }
        
        if !isRunning {
            var path = Bundle.main.bundlePath
            for _ in 0..<4 {
                path = (path as NSString).deletingLastPathComponent
            }
            NSWorkspace.shared.launchApplication(path)
        }
        
        // Terminate helper once the main app is launched or already running
        NSApplication.shared.terminate(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
