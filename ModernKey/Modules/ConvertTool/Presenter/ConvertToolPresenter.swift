//
//  ConvertToolPresenter.swift
//  ModernKey
//
//  VIPER Presenter for ConvertTool module.
//

import Cocoa

final class ConvertToolPresenter: ConvertToolPresenterProtocol {
    weak var view: ConvertToolViewProtocol?
    var interactor: ConvertToolInteractorInputProtocol?
    var router: ConvertToolRouterProtocol?
    
    private var codeTables: [String] = []
    
    func viewDidLoad() {
        if let tables = interactor?.getCodeTableNames() {
            self.codeTables = tables
        }
        interactor?.loadConfig()
    }
    
    func didChangeFromCode(index: Int) {
        interactor?.setFromCode(index: index)
    }
    
    func didChangeToCode(index: Int) {
        interactor?.setToCode(index: index)
    }
    
    func didTapReverseCode() {
        interactor?.reverseCodes()
    }
    
    func didToggleAlertWhenCompleted(isOn: Bool) {
        interactor?.setAlertWhenCompleted(enabled: isOn)
    }
    
    func didSelectAllCaps() {
        interactor?.setToAllCaps()
    }
    
    func didSelectAllNonCaps() {
        interactor?.setToAllNonCaps()
    }
    
    func didSelectCapsFirstLetter() {
        interactor?.setToCapsFirstLetter()
    }
    
    func didSelectCapsEachWord() {
        interactor?.setToCapsEachWord()
    }
    
    func didToggleRemoveMark(isOn: Bool) {
        interactor?.setRemoveMark(enabled: isOn)
    }
    
    func didToggleModifier(control: Bool, option: Bool, command: Bool, shift: Bool) {
        interactor?.setHotKeyModifiers(control: control, option: option, command: command, shift: shift)
    }
    
    func didChangeHotKey(keyCode: UInt16, character: UInt16) {
        interactor?.setHotKeyKey(keyCode: keyCode, character: character)
    }
    
    func didTapConvertInClipboard() {
        let success = interactor?.convertInClipboard() ?? false
        let window = (view as? NSViewController)?.view.window
        if success {
            if !convertToolDontAlertWhenCompleted {
                router?.showAlert(message: "Chuyển mã thành công!", subMsg: "Kết quả đã được lưu trong clipboard.", window: window)
            }
        } else {
            router?.showAlert(message: "Không có dữ liệu trong clipboard!", subMsg: "Hãy sao chép một đoạn text để chuyển đổi!", window: window)
        }
    }
}

// MARK: - Interactor Output
extension ConvertToolPresenter: ConvertToolInteractorOutputProtocol {
    func didUpdateConfig(_ config: ConvertToolConfig) {
        view?.displayConfig(config, codeTables: codeTables)
    }
}
