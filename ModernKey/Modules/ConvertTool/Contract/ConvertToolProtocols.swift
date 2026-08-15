//
//  ConvertToolProtocols.swift
//  ModernKey
//
//  VIPER Protocols for ConvertTool module.
//

import Cocoa

// MARK: - View
protocol ConvertToolViewProtocol: AnyObject {
    func displayConfig(_ config: ConvertToolConfig, codeTables: [String])
    func showResultMessage(message: String, subMsg: String)
}

// MARK: - Presenter
protocol ConvertToolPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didChangeFromCode(index: Int)
    func didChangeToCode(index: Int)
    func didTapReverseCode()
    func didToggleAlertWhenCompleted(isOn: Bool)
    func didSelectAllCaps()
    func didSelectAllNonCaps()
    func didSelectCapsFirstLetter()
    func didSelectCapsEachWord()
    func didToggleRemoveMark(isOn: Bool)
    func didToggleModifier(control: Bool, option: Bool, command: Bool, shift: Bool)
    func didChangeHotKey(keyCode: UInt16, character: UInt16)
    func didTapConvertInClipboard()
}

// MARK: - Interactor
protocol ConvertToolInteractorInputProtocol: AnyObject {
    func loadConfig()
    func getCodeTableNames() -> [String]
    func setFromCode(index: Int)
    func setToCode(index: Int)
    func reverseCodes()
    func setAlertWhenCompleted(enabled: Bool)
    func setToAllCaps()
    func setToAllNonCaps()
    func setToCapsFirstLetter()
    func setToCapsEachWord()
    func setRemoveMark(enabled: Bool)
    func setHotKeyModifiers(control: Bool, option: Bool, command: Bool, shift: Bool)
    func setHotKeyKey(keyCode: UInt16, character: UInt16)
    func convertInClipboard() -> Bool
}

protocol ConvertToolInteractorOutputProtocol: AnyObject {
    func didUpdateConfig(_ config: ConvertToolConfig)
}

// MARK: - Router
protocol ConvertToolRouterProtocol: AnyObject {
    func showAlert(message: String, subMsg: String, window: NSWindow?)
}
