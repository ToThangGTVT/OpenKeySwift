//
//  ConvertToolViewController.swift
//  ModernKey
//
//  VIPER View for ConvertTool module.
//

import Cocoa

@objc(ConvertToolViewController)
class ConvertToolViewController: NSViewController, ConvertToolViewProtocol, MyTextFieldDelegate {

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

    var presenter: ConvertToolPresenterProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        SHotKey.parent = self
        if presenter == nil {
            _ = ConvertToolBuilder.setup(view: self)
        }
        presenter?.viewDidLoad()
    }
    
    // MARK: - ConvertToolViewProtocol
    func displayConfig(_ config: ConvertToolConfig, codeTables: [String]) {
        if FromCode.numberOfItems != codeTables.count {
            FromCode.removeAllItems()
            FromCode.addItems(withTitles: codeTables)
            ToCode.removeAllItems()
            ToCode.addItems(withTitles: codeTables)
        }
        
        FromCode.selectItem(at: config.fromCode)
        ToCode.selectItem(at: config.toCode)
        
        AlertWhenComplete.state = config.alertWhenComplete ? .on : .off
        
        ToAllCaps.state = config.toAllCaps ? .on : .off
        ToNonCaps.state = config.toNonCaps ? .on : .off
        ToCapsFirstLetter.state = config.toCapsFirstLetter ? .on : .off
        ToCapsCharEachWord.state = config.toCapsEachWord ? .on : .off
        
        ToRemoveSign.state = config.removeMark ? .on : .off
        
        SControl.state = (config.hotKey & 0x100) != 0 ? .on : .off
        SOption.state = (config.hotKey & 0x200) != 0 ? .on : .off
        SCommand.state = (config.hotKey & 0x400) != 0 ? .on : .off
        SShift.state = (config.hotKey & 0x800) != 0 ? .on : .off
        SHotKey.setTextByChar(UInt16((config.hotKey >> 24) & 0xFF))
    }
    
    func showResultMessage(message: String, subMsg: String) {
        OpenKeyManager.showMessage(self.view.window, message: message, subMsg: subMsg)
    }

    // MARK: - Actions matching ConvertToolViewController.xib
    @IBAction func onAlertWhenCompleted(_ sender: NSButton) {
        presenter?.didToggleAlertWhenCompleted(isOn: sender.state == .on)
    }
    
    @IBAction func onToAllCaps(_ sender: NSButton) {
        presenter?.didSelectAllCaps()
    }
    
    @IBAction func onToNonCaps(_ sender: NSButton) {
        presenter?.didSelectAllNonCaps()
    }
    
    @IBAction func onToCapsFirstLetter(_ sender: NSButton) {
        presenter?.didSelectCapsFirstLetter()
    }
    
    @IBAction func onToCapsCharEachWord(_ sender: NSButton) {
        presenter?.didSelectCapsEachWord()
    }
    
    @IBAction func onToRemoveSign(_ sender: NSButton) {
        presenter?.didToggleRemoveMark(isOn: sender.state == .on)
    }
    
    @IBAction func onRemoveSign(_ sender: NSButton) {
        presenter?.didToggleRemoveMark(isOn: sender.state == .on)
    }
    
    @IBAction func onReverseCode(_ sender: Any) {
        presenter?.didTapReverseCode()
    }
    
    @IBAction func onFromCodeSelected(_ sender: NSPopUpButton) {
        presenter?.didChangeFromCode(index: sender.indexOfSelectedItem)
    }
    
    @IBAction func onFromCodeChanged(_ sender: NSPopUpButton) {
        presenter?.didChangeFromCode(index: sender.indexOfSelectedItem)
    }
    
    @IBAction func onToCodeSelected(_ sender: NSPopUpButton) {
        presenter?.didChangeToCode(index: sender.indexOfSelectedItem)
    }
    
    @IBAction func onToCodeChanged(_ sender: NSPopUpButton) {
        presenter?.didChangeToCode(index: sender.indexOfSelectedItem)
    }
    
    @IBAction func onConvertButton(_ sender: Any) {
        presenter?.didTapConvertInClipboard()
    }
    
    @IBAction func onConvertInClipboard(_ sender: Any) {
        presenter?.didTapConvertInClipboard()
    }
    
    private func updateModifiers() {
        presenter?.didToggleModifier(
            control: SControl.state == .on,
            option: SOption.state == .on,
            command: SCommand.state == .on,
            shift: SShift.state == .on
        )
    }
    
    @IBAction func onSControl(_ sender: NSButton) { updateModifiers() }
    @IBAction func onSOption(_ sender: NSButton) { updateModifiers() }
    @IBAction func onSCommand(_ sender: NSButton) { updateModifiers() }
    @IBAction func onSShift(_ sender: NSButton) { updateModifiers() }
    
    @IBAction func onCustomKeyControl(_ sender: NSButton) { updateModifiers() }
    @IBAction func onCustomKeyOption(_ sender: NSButton) { updateModifiers() }
    @IBAction func onCustomKeyCommand(_ sender: NSButton) { updateModifiers() }
    @IBAction func onCustomKeyShift(_ sender: NSButton) { updateModifiers() }
    
    @IBAction func onOKButton(_ sender: Any) {
        self.view.window?.close()
    }
    
    @IBAction func onClose(_ sender: Any) {
        self.view.window?.close()
    }
    
    // MARK: - MyTextFieldDelegate
    func onMyTextFieldKeyChange(_ keyCode: UInt16, character: UInt16) {
        presenter?.didChangeHotKey(keyCode: keyCode, character: character)
    }
}

// MARK: - Module Builder
enum ConvertToolBuilder {
    static func build() -> ConvertToolViewController {
        let view = ConvertToolViewController(nibName: "ConvertToolViewController", bundle: nil)
        return setup(view: view)
    }
    
    @discardableResult
    static func setup(view: ConvertToolViewController) -> ConvertToolViewController {
        let presenter = ConvertToolPresenter()
        let interactor = ConvertToolInteractor()
        let router = ConvertToolRouter()

        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        return view
    }
}
