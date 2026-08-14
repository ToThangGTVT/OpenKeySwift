import Cocoa

@objc(ConvertToolViewController)
class ConvertToolViewController: NSViewController, MyTextFieldDelegate {

    @IBOutlet weak var AlertWhenComplete: NSButton!
    @IBOutlet weak var ToAllCaps: NSButton!
    @IBOutlet weak var ToNonCaps: NSButton!
    @IBOutlet weak var ToCapsFirstLetter: NSButton!
    @IBOutlet weak var ToCapsCharEachWord: NSButton!
    @IBOutlet weak var ToRemoveSign: NSButton!
    
    @IBOutlet weak var ConvertInClipBoard: NSButton!
    
    @IBOutlet weak var SControl: NSButton!
    @IBOutlet weak var SOption: NSButton!
    @IBOutlet weak var SCommand: NSButton!
    @IBOutlet weak var SShift: NSButton!
    @IBOutlet weak var SHotKey: MyTextField!
    
    @IBOutlet weak var FromCode: NSPopUpButton!
    @IBOutlet weak var ToCode: NSPopUpButton!
    @IBOutlet weak var ReverseCode: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        SHotKey.parent = self
        fillData()
    }
    
    func fillData() {
        let codeData = OpenKeyManager.getTableCodes()
        FromCode.removeAllItems()
        FromCode.addItems(withTitles: codeData)
        ToCode.removeAllItems()
        ToCode.addItems(withTitles: codeData)
        
        AlertWhenComplete.state = !convertToolDontAlertWhenCompleted ? .on : .off
        
        ToAllCaps.state = convertToolToAllCaps ? .on : .off
        ToNonCaps.state = convertToolToAllNonCaps ? .on : .off
        ToCapsFirstLetter.state = convertToolToCapsFirstLetter ? .on : .off
        ToCapsCharEachWord.state = convertToolToCapsEachWord ? .on : .off
        
        ToRemoveSign.state = convertToolRemoveMark ? .on : .off
        
        FromCode.selectItem(at: Int(convertToolFromCode))
        ToCode.selectItem(at: Int(convertToolToCode))
        
        SControl.state = (convertToolHotKey & 0x100) != 0 ? .on : .off
        SOption.state = (convertToolHotKey & 0x200) != 0 ? .on : .off
        SCommand.state = (convertToolHotKey & 0x400) != 0 ? .on : .off
        SShift.state = (convertToolHotKey & 0x800) != 0 ? .on : .off
        SHotKey.setTextByChar(UInt16((convertToolHotKey >> 24) & 0xFF))
    }
    
    func turnOffAllOption() {
        convertToolToAllCaps = false
        UserDefaults.standard.set(convertToolToAllCaps, forKey: "convertToolToAllCaps")
        convertToolToAllNonCaps = false
        UserDefaults.standard.set(convertToolToAllNonCaps, forKey: "convertToolToAllNonCaps")
        convertToolToCapsFirstLetter = false
        UserDefaults.standard.set(convertToolToCapsFirstLetter, forKey: "convertToolToCapsFirstLetter")
        convertToolToCapsEachWord = false
        UserDefaults.standard.set(convertToolToCapsEachWord, forKey: "convertToolToCapsEachWord")
    }

    @IBAction func onAlertWhenCompleted(_ sender: NSButton) {
        let val = setCustomValue(sender, keyToSet: "convertToolDontAlertWhenCompleted")
        convertToolDontAlertWhenCompleted = val == 0
    }
    
    @IBAction func onToAllCaps(_ sender: NSButton) {
        turnOffAllOption()
        let val = setCustomValue(sender, keyToSet: "convertToolToAllCaps")
        convertToolToAllCaps = val != 0
        fillData()
    }
    
    @IBAction func onToNonCaps(_ sender: NSButton) {
        turnOffAllOption()
        let val = setCustomValue(sender, keyToSet: "convertToolToAllNonCaps")
        convertToolToAllNonCaps = val != 0
        fillData()
    }
    
    @IBAction func onToCapsFirstLetter(_ sender: NSButton) {
        turnOffAllOption()
        let val = setCustomValue(sender, keyToSet: "convertToolToCapsFirstLetter")
        convertToolToCapsFirstLetter = val != 0
        fillData()
    }
    
    @IBAction func onToCapsCharEachWord(_ sender: NSButton) {
        turnOffAllOption()
        let val = setCustomValue(sender, keyToSet: "convertToolToCapsEachWord")
        convertToolToCapsEachWord = val != 0
        fillData()
    }
    
    @IBAction func onToRemoveSign(_ sender: NSButton) {
        let val = setCustomValue(sender, keyToSet: "convertToolRemoveMark")
        convertToolRemoveMark = val != 0
    }
    
    @IBAction func onFromCodeSelected(_ sender: NSPopUpButton) {
        convertToolFromCode = UInt8(FromCode.indexOfSelectedItem)
        UserDefaults.standard.set(Int(convertToolFromCode), forKey: "convertToolFromCode")
    }
    
    @IBAction func onToCodeSelected(_ sender: NSPopUpButton) {
        convertToolToCode = UInt8(ToCode.indexOfSelectedItem)
        UserDefaults.standard.set(Int(convertToolToCode), forKey: "convertToolToCode")
    }
    
    func setCustomValue(_ sender: NSButton?, keyToSet: String?) -> Int {
        guard let button = sender else { return 0 }
        let val = button.state == .on ? 1 : 0
        if let key = keyToSet {
            UserDefaults.standard.set(val, forKey: key)
        }
        return val
    }
    
    @IBAction func onReverseCode(_ sender: Any) {
        let code = ToCode.indexOfSelectedItem
        ToCode.selectItem(at: FromCode.indexOfSelectedItem)
        FromCode.selectItem(at: code)
        convertToolFromCode = UInt8(FromCode.indexOfSelectedItem)
        convertToolToCode = UInt8(ToCode.indexOfSelectedItem)
    }
    
    @IBAction func onSControl(_ sender: NSButton) {
        let val = sender.state == .on ? 1 : 0
        convertToolHotKey &= ~0x100
        convertToolHotKey |= Int32(val) << 8
        UserDefaults.standard.set(convertToolHotKey, forKey: "convertToolHotKey")
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setQuickConvertString()
        }
    }
    
    @IBAction func onSOption(_ sender: NSButton) {
        let val = sender.state == .on ? 1 : 0
        convertToolHotKey &= ~0x200
        convertToolHotKey |= Int32(val) << 9
        UserDefaults.standard.set(convertToolHotKey, forKey: "convertToolHotKey")
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setQuickConvertString()
        }
    }
    
    @IBAction func onSCommand(_ sender: NSButton) {
        let val = sender.state == .on ? 1 : 0
        convertToolHotKey &= ~0x400
        convertToolHotKey |= Int32(val) << 10
        UserDefaults.standard.set(convertToolHotKey, forKey: "convertToolHotKey")
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setQuickConvertString()
        }
    }
    
    @IBAction func onSShift(_ sender: NSButton) {
        let val = sender.state == .on ? 1 : 0
        convertToolHotKey &= ~0x800
        convertToolHotKey |= Int32(val) << 11
        UserDefaults.standard.set(convertToolHotKey, forKey: "convertToolHotKey")
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setQuickConvertString()
        }
    }
    
    func onMyTextFieldKeyChange(_ keyCode: UInt16, character: UInt16) {
        convertToolHotKey &= ~0xFF
        convertToolHotKey |= Int32(keyCode)
        convertToolHotKey &= 0x00FFFFFF
        convertToolHotKey |= (Int32(character) << 24)
        UserDefaults.standard.set(convertToolHotKey, forKey: "convertToolHotKey")
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setQuickConvertString()
        }
    }
    
    @IBAction func onConvertButton(_ sender: Any) {
        if OpenKeyManager.quickConvert() {
            if !convertToolDontAlertWhenCompleted {
                OpenKeyManager.showMessage(self.view.window, message: "Chuyển mã thành công!", subMsg: "Kết quả đã được lưu trong clipboard.")
            }
        } else {
            OpenKeyManager.showMessage(self.view.window, message: "Không có dữ liệu trong clipboard!", subMsg: "Hãy sao chép một đoạn text để chuyển đổi!")
        }
    }
    
    @IBAction func onOKButton(_ sender: Any) {
        self.view.window?.close()
    }
}
