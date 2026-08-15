//
//  ConvertToolInteractor.swift
//  ModernKey
//
//  VIPER Interactor for ConvertTool module.
//

import Cocoa

final class ConvertToolInteractor: ConvertToolInteractorInputProtocol {
    weak var presenter: ConvertToolInteractorOutputProtocol?
    
    private let defaults = UserDefaults.standard
    
    func loadConfig() {
        let config = currentConfig()
        presenter?.didUpdateConfig(config)
    }
    
    private func currentConfig() -> ConvertToolConfig {
        return ConvertToolConfig(
            fromCode: Int(convertToolFromCode),
            toCode: Int(convertToolToCode),
            alertWhenComplete: !convertToolDontAlertWhenCompleted,
            toAllCaps: convertToolToAllCaps,
            toNonCaps: convertToolToAllNonCaps,
            toCapsFirstLetter: convertToolToCapsFirstLetter,
            toCapsEachWord: convertToolToCapsEachWord,
            removeMark: convertToolRemoveMark,
            hotKey: convertToolHotKey
        )
    }
    
    func getCodeTableNames() -> [String] {
        return OpenKeyManager.getTableCodes()
    }
    
    func setFromCode(index: Int) {
        convertToolFromCode = UInt8(index)
        defaults.set(index, forKey: "convertToolFromCode")
        loadConfig()
    }
    
    func setToCode(index: Int) {
        convertToolToCode = UInt8(index)
        defaults.set(index, forKey: "convertToolToCode")
        loadConfig()
    }
    
    func reverseCodes() {
        let temp = convertToolFromCode
        convertToolFromCode = convertToolToCode
        convertToolToCode = temp
        defaults.set(Int(convertToolFromCode), forKey: "convertToolFromCode")
        defaults.set(Int(convertToolToCode), forKey: "convertToolToCode")
        loadConfig()
    }
    
    func setAlertWhenCompleted(enabled: Bool) {
        convertToolDontAlertWhenCompleted = !enabled
        defaults.set(convertToolDontAlertWhenCompleted ? 1 : 0, forKey: "convertToolDontAlertWhenCompleted")
        loadConfig()
    }
    
    private func turnOffAllCasingOptions() {
        convertToolToAllCaps = false
        defaults.set(false, forKey: "convertToolToAllCaps")
        convertToolToAllNonCaps = false
        defaults.set(false, forKey: "convertToolToAllNonCaps")
        convertToolToCapsFirstLetter = false
        defaults.set(false, forKey: "convertToolToCapsFirstLetter")
        convertToolToCapsEachWord = false
        defaults.set(false, forKey: "convertToolToCapsEachWord")
    }
    
    func setToAllCaps() {
        let next = !convertToolToAllCaps
        turnOffAllCasingOptions()
        convertToolToAllCaps = next
        defaults.set(next, forKey: "convertToolToAllCaps")
        loadConfig()
    }
    
    func setToAllNonCaps() {
        let next = !convertToolToAllNonCaps
        turnOffAllCasingOptions()
        convertToolToAllNonCaps = next
        defaults.set(next, forKey: "convertToolToAllNonCaps")
        loadConfig()
    }
    
    func setToCapsFirstLetter() {
        let next = !convertToolToCapsFirstLetter
        turnOffAllCasingOptions()
        convertToolToCapsFirstLetter = next
        defaults.set(next, forKey: "convertToolToCapsFirstLetter")
        loadConfig()
    }
    
    func setToCapsEachWord() {
        let next = !convertToolToCapsEachWord
        turnOffAllCasingOptions()
        convertToolToCapsEachWord = next
        defaults.set(next, forKey: "convertToolToCapsEachWord")
        loadConfig()
    }
    
    func setRemoveMark(enabled: Bool) {
        convertToolRemoveMark = enabled
        defaults.set(enabled, forKey: "convertToolRemoveMark")
        loadConfig()
    }
    
    func setHotKeyModifiers(control: Bool, option: Bool, command: Bool, shift: Bool) {
        var key = convertToolHotKey & Int32(bitPattern: 0xFF0000FF) // keep char and keyCode
        if control { key |= 0x100 }
        if option { key |= 0x200 }
        if command { key |= 0x400 }
        if shift { key |= 0x800 }
        
        convertToolHotKey = key
        defaults.set(Int(key), forKey: "convertToolHotKey")
        loadConfig()
        (NSApplication.shared.delegate as? AppDelegate)?.setQuickConvertString()
    }
    
    func setHotKeyKey(keyCode: UInt16, character: UInt16) {
        var key = convertToolHotKey & 0x0000FF00 // keep modifiers
        key |= (Int32(character & 0xFF) << 24) | Int32(keyCode & 0xFF)
        convertToolHotKey = key
        defaults.set(Int(key), forKey: "convertToolHotKey")
        loadConfig()
        (NSApplication.shared.delegate as? AppDelegate)?.setQuickConvertString()
    }
    
    func convertInClipboard() -> Bool {
        return OpenKeyManager.quickConvert()
    }
}
