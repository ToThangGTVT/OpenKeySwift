//
//  MacroInteractor.swift
//  ModernKey
//
//  VIPER Interactor for Macro module.
//

import Cocoa

final class MacroInteractor: MacroInteractorInputProtocol {
    weak var presenter: MacroInteractorOutputProtocol?
    
    private var settingsService: SettingsServiceProtocol
    
    init(settingsService: SettingsServiceProtocol = SettingsService.shared) {
        self.settingsService = settingsService
    }
    
    func fetchMacros() {
        Macro_Reload()
        let items = loadMacroItemsFromEngine()
        presenter?.didUpdateMacros(items)
    }
    
    private func loadMacroItemsFromEngine() -> [MacroItem] {
        var items: [MacroItem] = []
        let count = Macro_GetCount()
        for i in 0..<count {
            if let kPtr = Macro_GetText(Int32(i)), let cPtr = Macro_GetContent(Int32(i)) {
                let key = String(cString: kPtr)
                let content = String(cString: cPtr)
                items.append(MacroItem(key: key, content: content))
            }
        }
        return items
    }
    
    private func saveToUserDefaultsAndReload() {
        Macro_Reload()
        var length: Int32 = 0
        if let bytes = Macro_SaveData(&length), length > 0 {
            UserDefaults.standard.set(Data(bytes: bytes, count: Int(length)), forKey: "macroData")
        } else {
            UserDefaults.standard.removeObject(forKey: "macroData")
        }
        let items = loadMacroItemsFromEngine()
        presenter?.didUpdateMacros(items)
    }
    
    func addMacro(key: String, content: String) {
        Macro_Add(key, content)
        saveToUserDefaultsAndReload()
    }
    
    func deleteMacro(key: String) {
        if Macro_Delete(key) {
            saveToUserDefaultsAndReload()
        } else {
            presenter?.didFailWithError("Không tìm thấy từ cần xoá!")
        }
    }
    
    func importFromFile(path: String, keepExisting: Bool) {
        Macro_ReadFromFile(path, keepExisting)
        saveToUserDefaultsAndReload()
    }
    
    func exportToFile(path: String) {
        Macro_SaveToFile(path)
    }
    
    func setAutoCaps(enabled: Bool) {
        settingsService.autoCapsMacro = enabled
    }
    
    func isAutoCapsEnabled() -> Bool {
        return settingsService.autoCapsMacro
    }
    
    func findMacro(byKey key: String) -> MacroItem? {
        let items = loadMacroItemsFromEngine()
        return items.first { $0.key == key }
    }
}
