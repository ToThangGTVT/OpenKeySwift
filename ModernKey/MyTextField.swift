import Cocoa
import Carbon

@objc protocol MyTextFieldDelegate: AnyObject {
    @objc optional func onMyTextFieldKeyChange(_ keyCode: UInt16, character: UInt16)
    /// Same thing, but says which field changed — needed once a controller owns
    /// more than one hotkey field. Takes precedence when implemented.
    @objc optional func myTextField(_ field: MyTextField, didChangeKeyCode keyCode: UInt16, character: UInt16)
}

@objc(MyTextField)
class MyTextField: NSTextField, NSTextFieldDelegate {
    weak var parent: MyTextFieldDelegate?
    var lastKeyCode: UInt16 = 0
    var lastKeyChar: UInt16 = 0
    private var eventMonitor: Any?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func becomeFirstResponder() -> Bool {
        let okToChange = super.becomeFirstResponder()
        if okToChange {
            self.setKeyboardFocusRingNeedsDisplay(self.bounds)
            
            if eventMonitor == nil {
                eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    self?.lastKeyCode = UInt16(event.keyCode)
                    if let firstChar = event.characters?.utf16.first {
                        self?.lastKeyChar = firstChar
                    }
                    return event
                }
            }
        }
        return okToChange
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func notifyParent(_ keyCode: UInt16, _ character: UInt16) {
        if let _ = parent?.myTextField?(self, didChangeKeyCode: keyCode, character: character) {
            return
        }
        parent?.onMyTextFieldKeyChange?(keyCode, character: character)
    }

    override func textDidChange(_ notification: Notification) {
        if lastKeyCode == UInt16(kVK_Space) {
            self.stringValue = "Space"
            notifyParent(UInt16(kVK_Space), UInt16(kVK_Space))
        } else if lastKeyCode == UInt16(kVK_Delete) || lastKeyCode == UInt16(kVK_ForwardDelete) {
            self.stringValue = ""
            notifyParent(0xFE, 0xFE)
        } else {
            self.stringValue = ""
            notifyParent(lastKeyCode, lastKeyChar)
            if let scalar = UnicodeScalar(lastKeyChar) {
                self.stringValue = String(Character(scalar))
            }
        }
    }

    func setTextByChar(_ chr: UInt16) {
        if chr == UInt16(kVK_Space) {
            self.stringValue = "Space"
        } else if chr == 0xFE {
            self.stringValue = ""
        } else {
            if let scalar = UnicodeScalar(chr) {
                self.stringValue = String(Character(scalar))
            }
        }
    }
}
