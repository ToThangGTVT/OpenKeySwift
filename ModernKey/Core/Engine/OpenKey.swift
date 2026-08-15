//
//  OpenKey.swift
//  OpenKey
//
//  Swift port of OpenKey.mm — the bridge between the CGEventTap and the C++ engine.
//

import Cocoa
import Carbon
import CoreGraphics

// MARK: - Constants

let OPENKEY_BUNDLE = Bundle.main.bundleIdentifier ?? "com.utc.open.key"
let OPENKEY_HELPER_BUNDLE = "com.utc.open.key.helper"

private let MAX_UNICODE_STRING = 20
let EMPTY_HOTKEY: Int32 = Int32(bitPattern: 0xFE0000FE)

// engine data masks (see DataType.h)
private let CAPS_MASK: UInt32 = 0x10000
private let CHAR_CODE_MASK: UInt32 = 0x2000000
private let PURE_CHARACTER_MASK: UInt32 = 0x80000000
private let MAX_BUFF: Int = 32

// HoolCodeState (see DataType.h)
private let vDoNothing: UInt8 = 0
private let vWillProcess: UInt8 = 1
private let vBreakWord: UInt8 = 2
private let vRestore: UInt8 = 3
private let vReplaceMaro: UInt8 = 4
private let vRestoreAndStartNewSession: UInt8 = 5

/// app which must be sent a special empty character
private let _niceSpaceApp: Set<String> = ["com.sublimetext.3", "com.sublimetext.2"]

/// app which has trouble with unicode compound
private let _unicodeCompoundApp = ["com.apple.",
                                   "com.google.Chrome", "com.brave.Browser",
                                   "com.microsoft.edgemac.Dev", "com.microsoft.edgemac.Beta",
                                   "com.microsoft.Edge.Dev", "com.microsoft.Edge"]

private let _recommendWorkaroundDisabledApp: Set<String> = ["com.apple.Spotlight"]

// Ignore code for Modifier keys and numpad
// Reference: https://eastmanreference.com/complete-list-of-applescript-key-codes
private let keyStringToKeyCodeMap: [String: CGKeyCode] = [
    "`": 50, "~": 50, "1": 18, "!": 18, "2": 19, "@": 19, "3": 20, "#": 20, "4": 21, "$": 21,
    "5": 23, "%": 23, "6": 22, "^": 22, "7": 26, "&": 26, "8": 28, "*": 28, "9": 25, "(": 25,
    "0": 29, ")": 29, "-": 27, "_": 27, "=": 24, "+": 24,
    "q": 12, "w": 13, "e": 14, "r": 15, "t": 17, "y": 16, "u": 32, "i": 34, "o": 31, "p": 35,
    "[": 33, "{": 33, "]": 30, "}": 30, "\\": 42, "|": 42,
    "a": 0, "s": 1, "d": 2, "f": 3, "g": 5, "h": 4, "j": 38, "k": 40, "l": 37,
    ";": 41, ":": 41, "'": 39, "\"": 39,
    "z": 6, "x": 7, "c": 8, "v": 9, "b": 11, "n": 45, "m": 46,
    ",": 43, "<": 43, ".": 47, ">": 47, "/": 44, "?": 44
]

// MARK: - Mutable state

private var myEventSource: CGEventSource?
private var eventBackSpaceDown: CGEvent?
private var eventBackSpaceUp: CGEvent?

private var _keycode: CGKeyCode = 0
private var _flag: CGEventFlags = []
private var _lastFlag: CGEventFlags = []
private var _proxy: CGEventTapProxy?

private var _newCharString = [UInt16](repeating: 0, count: MAX_UNICODE_STRING)
private var _newCharSize: Int = 0
private var _willContinuteSending = false
private var _willSendControlKey = false
private var _k: Int = 0

private var _syncKey = [UInt16]()
private var _hasJustUsedHotKey = false
private var _languageTemp: Int32 = 0

private var _frontMostApp = "UnknownApp"

// MARK: - Small helpers

@inline(__always) private func IS_DOUBLE_CODE(_ code: Int32) -> Bool {
    return code == 2 || code == 3
}

@inline(__always) private func GET_SWITCH_KEY(_ data: Int32) -> CGKeyCode {
    return CGKeyCode(data & 0xFF)
}

@inline(__always) private func HAS_CONTROL(_ data: Int32) -> Bool { return (data & 0x100) != 0 }
@inline(__always) private func HAS_OPTION(_ data: Int32) -> Bool { return (data & 0x200) != 0 }
@inline(__always) private func HAS_COMMAND(_ data: Int32) -> Bool { return (data & 0x400) != 0 }
@inline(__always) private func HAS_SHIFT(_ data: Int32) -> Bool { return (data & 0x800) != 0 }
@inline(__always) private func HAS_BEEP(_ data: Int32) -> Bool { return (data & 0x8000) != 0 }

@inline(__always) private func frontMostAppBundleId() -> String? {
    return NSWorkspace.shared.frontmostApplication?.bundleIdentifier
}

@inline(__always) private var OTHER_CONTROL_KEY: Bool {
    return _flag.contains(.maskCommand) || _flag.contains(.maskControl) ||
           _flag.contains(.maskAlternate) || _flag.contains(.maskSecondaryFn) ||
           _flag.contains(.maskNumericPad) || _flag.contains(.maskHelp)
}

@inline(__always) private func post(_ event: CGEvent?) {
    guard let proxy = _proxy, let event = event else { return }
    event.tapPostEvent(proxy)
}

@inline(__always) private func makeKeyEvent(_ virtualKey: CGKeyCode, _ down: Bool) -> CGEvent? {
    return CGEvent(keyboardEventSource: myEventSource, virtualKey: virtualKey, keyDown: down)
}

@inline(__always) private func setUnicode(_ event: CGEvent?, _ chars: [UInt16], _ length: Int) {
    guard let event = event, length > 0 else { return }
    chars.withUnsafeBufferPointer { buffer in
        event.keyboardSetUnicodeString(stringLength: min(length, buffer.count),
                                       unicodeString: buffer.baseAddress)
    }
}

// MARK: - Init

func OpenKeyInit() {
    let prefs = UserDefaults.standard

    vFreeMark = 0
    vCodeTable = Int32(prefs.integer(forKey: "CodeTable")); if vCodeTable < 0 { vCodeTable = 0 }
    vCheckSpelling = Int32(prefs.integer(forKey: "Spelling"))
    vQuickTelex = Int32(prefs.integer(forKey: "QuickTelex"))
    vUseModernOrthography = Int32(prefs.integer(forKey: "ModernOrthography"))
    vRestoreIfWrongSpelling = Int32(prefs.integer(forKey: "RestoreIfInvalidWord"))
    vFixRecommendBrowser = Int32(prefs.integer(forKey: "FixRecommendBrowser"))
    vUseMacro = Int32(prefs.integer(forKey: "UseMacro"))
    vUseMacroInEnglishMode = Int32(prefs.integer(forKey: "UseMacroInEnglishMode"))
    vAutoCapsMacro = Int32(prefs.integer(forKey: "vAutoCapsMacro"))
    vSendKeyStepByStep = Int32(prefs.integer(forKey: "SendKeyStepByStep"))
    vUseSmartSwitchKey = Int32(prefs.integer(forKey: "UseSmartSwitchKey"))
    vUpperCaseFirstChar = Int32(prefs.integer(forKey: "UpperCaseFirstChar"))

    vTempOffSpelling = Int32(prefs.integer(forKey: "vTempOffSpelling"))
    vAllowConsonantZFWJ = Int32(prefs.integer(forKey: "vAllowConsonantZFWJ"))
    vQuickEndConsonant = Int32(prefs.integer(forKey: "vQuickEndConsonant"))
    vQuickStartConsonant = Int32(prefs.integer(forKey: "vQuickStartConsonant"))
    vRememberCode = Int32(prefs.integer(forKey: "vRememberCode"))
    vOtherLanguage = Int32(prefs.integer(forKey: "vOtherLanguage"))
    vTempOffOpenKey = Int32(prefs.integer(forKey: "vTempOffOpenKey"))
    vFixChromiumBrowser = Int32(prefs.integer(forKey: "vFixChromiumBrowser"))
    vPerformLayoutCompat = Int32(prefs.integer(forKey: "vPerformLayoutCompat"))

    // Keystroke sound. Registered rather than set so upgrading users — who already
    // have NonFirstTime, and so never run loadDefaultConfig() again — still get a
    // sensible volume instead of 0.
    prefs.register(defaults: ["vKeySoundVolume": 60, "vKeySoundSpecialKeys": 1, "vKeySoundRelease": 1])
    vKeySound = Int32(prefs.integer(forKey: "vKeySound"))
    vKeySoundVoice = Int32(prefs.integer(forKey: "vKeySoundVoice"))
    vKeySoundVolume = Int32(prefs.integer(forKey: "vKeySoundVolume"))
    vKeySoundOnlyVietnamese = Int32(prefs.integer(forKey: "vKeySoundOnlyVietnamese"))
    vKeySoundSpecialKeys = Int32(prefs.integer(forKey: "vKeySoundSpecialKeys"))
    vKeySoundRelease = Int32(prefs.integer(forKey: "vKeySoundRelease"))
    KeySoundPlayer.shared.applySettings()

    myEventSource = CGEventSource(stateID: .privateState)
    OK_KeyInit()

    eventBackSpaceDown = makeKeyEvent(CGKeyCode(kVK_Delete), true)
    eventBackSpaceUp = makeKeyEvent(CGKeyCode(kVK_Delete), false)

    // init and load macro data
    if let data = prefs.data(forKey: "macroData"), !data.isEmpty {
        data.withUnsafeBytes { raw in
            OK_InitMacroMap(raw.bindMemory(to: UInt8.self).baseAddress, Int32(data.count))
        }
    } else {
        OK_InitMacroMap(nil, 0)
    }

    // init and load smart switch key data
    if let data = prefs.data(forKey: "smartSwitchKey"), !data.isEmpty {
        data.withUnsafeBytes { raw in
            OK_InitSmartSwitchKey(raw.bindMemory(to: UInt8.self).baseAddress, Int32(data.count))
        }
    } else {
        OK_InitSmartSwitchKey(nil, 0)
    }

    // init convert tool
    convertToolDontAlertWhenCompleted = !prefs.bool(forKey: "convertToolDontAlertWhenCompleted")
    convertToolToAllCaps = prefs.bool(forKey: "convertToolToAllCaps")
    convertToolToAllNonCaps = prefs.bool(forKey: "convertToolToAllNonCaps")
    convertToolToCapsFirstLetter = prefs.bool(forKey: "convertToolToCapsFirstLetter")
    convertToolToCapsEachWord = prefs.bool(forKey: "convertToolToCapsEachWord")
    convertToolRemoveMark = prefs.bool(forKey: "convertToolRemoveMark")
    convertToolFromCode = UInt8(truncatingIfNeeded: prefs.integer(forKey: "convertToolFromCode"))
    convertToolToCode = UInt8(truncatingIfNeeded: prefs.integer(forKey: "convertToolToCode"))
    convertToolHotKey = Int32(truncatingIfNeeded: prefs.integer(forKey: "convertToolHotKey"))
    if convertToolHotKey == 0 {
        convertToolHotKey = EMPTY_HOTKEY
    }
    
    // init clipboard hotkey
    clipboardHotKey = Int32(truncatingIfNeeded: prefs.integer(forKey: clipboardHotKeyKey))
    if clipboardHotKey == 0 {
        // Default Cmd+Shift+V
        clipboardHotKey = (Int32(118) << 24) | 0x09
        clipboardHotKey |= 0x400
        clipboardHotKey |= 0x800
    }
}

let clipboardHotKeyKey = "ClipboardHotkeyData"
var clipboardHotKey: Int32 = 0

// MARK: - Utilities

func ConvertUtil(_ str: String) -> String {
    guard let result = OK_ConvertUtil(str) else { return str }
    return String(cString: result)
}

func RequestNewSession() {
    // send event signal to Engine
    OK_HandleMouseEvent()

    if IS_DOUBLE_CODE(vCodeTable) {
        _syncKey.removeAll()
    }
}

private func queryFrontMostApp() {
    guard let front = NSWorkspace.shared.frontmostApplication else { return }
    if front.bundleIdentifier != OPENKEY_BUNDLE {
        _frontMostApp = front.bundleIdentifier ?? front.localizedName ?? "UnknownApp"
    }
}

private func containUnicodeCompoundApp(_ topApp: String?) -> Bool {
    guard let topApp = topApp else { return false }
    for prefix in _unicodeCompoundApp {
        if topApp.hasPrefix(prefix) || prefix == topApp {
            return true
        }
    }
    return false
}

private func isSpotlightVisible() -> Bool {
    guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                                   kCGNullWindowID) as? [[String: Any]] else {
        return false
    }
    for window in windows {
        if let owner = window[kCGWindowOwnerName as String] as? String, owner == "Spotlight" {
            return true
        }
    }
    return false
}

private func shouldUseRecommendWorkaround(_ topApp: String?) -> Bool {
    if vFixRecommendBrowser == 0 { return false }
    if isSpotlightVisible() { return false }
    guard let topApp = topApp else { return true }
    return !_recommendWorkaroundDisabledApp.contains(topApp)
}

private func shouldUseSelectionReplacement(_ topApp: String?) -> Bool {
    if isSpotlightVisible() { return true }
    guard let topApp = topApp else { return false }
    return _recommendWorkaroundDisabledApp.contains(topApp)
}

func saveSmartSwitchKeyData() {
    var length: Int32 = 0
    guard let bytes = OK_SmartSwitchKeySaveData(&length), length > 0 else { return }
    let data = Data(bytes: bytes, count: Int(length))
    UserDefaults.standard.set(data, forKey: "smartSwitchKey")
}

// MARK: - Smart switch key / table code callbacks

/// use for smart switch key; improved on Sep 28th, 2019
func OnActiveAppChanged() {
    queryFrontMostApp()
    _languageTemp = OK_GetAppInputMethodStatus(_frontMostApp, vLanguage | (vCodeTable << 1))

    if (_languageTemp & 0x01) != vLanguage { // for input method
        if _languageTemp != -1 {
            vLanguage = _languageTemp
            (NSApp.delegate as? AppDelegate)?.onImputMethodChanged(false)
            OK_StartNewSession()
        } else {
            saveSmartSwitchKeyData()
        }
    }

    if vRememberCode != 0 && (_languageTemp >> 1) != vCodeTable { // for remember table code feature
        if _languageTemp != -1 {
            (NSApp.delegate as? AppDelegate)?.onCodeTableChanged(_languageTemp >> 1)
        } else {
            saveSmartSwitchKeyData()
        }
    }
}

func OnTableCodeChange() {
    OK_OnTableCodeChange()
    if vRememberCode != 0 {
        queryFrontMostApp()
        OK_SetAppInputMethodStatus(_frontMostApp, vLanguage | (vCodeTable << 1))
        saveSmartSwitchKeyData()
    }
}

func OnInputMethodChanged() {
    if vUseSmartSwitchKey != 0 {
        queryFrontMostApp()
        OK_SetAppInputMethodStatus(_frontMostApp, vLanguage | (vCodeTable << 1))
        saveSmartSwitchKeyData()
    }
}

func OnSpellCheckingChanged() {
    OK_SetCheckSpelling()
}

// MARK: - Sending characters

private func InsertKeyLength(_ len: UInt16) {
    _syncKey.append(len)
}

private func SendPureCharacter(_ ch: UInt16) {
    let down = makeKeyEvent(0, true)
    let up = makeKeyEvent(0, false)
    setUnicode(down, [ch], 1)
    setUnicode(up, [ch], 1)
    post(down)
    post(up)

    if IS_DOUBLE_CODE(vCodeTable) {
        InsertKeyLength(1)
    }
}

private func SendKeyCode(_ data: UInt32) {
    var newChar = UInt16(truncatingIfNeeded: data)

    if (data & CHAR_CODE_MASK) == 0 {
        if IS_DOUBLE_CODE(vCodeTable) { // VNI
            InsertKeyLength(1)
        }

        let down = makeKeyEvent(CGKeyCode(newChar), true)
        let up = makeKeyEvent(CGKeyCode(newChar), false)

        var privateFlag = down?.flags ?? []
        if (data & CAPS_MASK) != 0 {
            privateFlag.insert(.maskShift)
        } else {
            privateFlag.remove(.maskShift)
        }
        privateFlag.insert(.maskNonCoalesced)

        down?.flags = privateFlag
        up?.flags = privateFlag
        post(down)
        post(up)
        return
    }

    if vCodeTable == 0 { // unicode 2 bytes code
        let down = makeKeyEvent(0, true)
        let up = makeKeyEvent(0, false)
        setUnicode(down, [newChar], 1)
        setUnicode(up, [newChar], 1)
        post(down)
        post(up)
    } else if vCodeTable == 1 || vCodeTable == 2 || vCodeTable == 4 {
        // others such as VNI Windows, TCVN3: 1 byte code
        let newCharHi = (newChar >> 8) & 0xFF
        newChar = newChar & 0xFF

        var down = makeKeyEvent(0, true)
        var up = makeKeyEvent(0, false)
        setUnicode(down, [newChar], 1)
        setUnicode(up, [newChar], 1)
        post(down)
        post(up)

        if newCharHi > 32 {
            if vCodeTable == 2 { // VNI
                InsertKeyLength(2)
            }
            down = makeKeyEvent(0, true)
            up = makeKeyEvent(0, false)
            setUnicode(down, [newCharHi], 1)
            setUnicode(up, [newCharHi], 1)
            post(down)
            post(up)
        } else {
            if vCodeTable == 2 { // VNI
                InsertKeyLength(1)
            }
        }
    } else if vCodeTable == 3 { // Unicode Compound
        let newCharHi = newChar >> 13
        newChar &= 0x1FFF
        let uniChar: [UInt16] = [newChar,
                                 newCharHi > 0 ? OK_UnicodeCompoundMark(Int32(newCharHi) - 1) : 0]
        InsertKeyLength(newCharHi > 0 ? 2 : 1)

        let length = newCharHi > 0 ? 2 : 1
        let down = makeKeyEvent(0, true)
        let up = makeKeyEvent(0, false)
        setUnicode(down, uniChar, length)
        setUnicode(up, uniChar, length)
        post(down)
        post(up)
    }
}

private func SendEmptyCharacter() {
    if IS_DOUBLE_CODE(vCodeTable) { // VNI or Unicode Compound
        InsertKeyLength(1)
    }

    var newChar: UInt16 = 0x202F // empty char
    if let front = frontMostAppBundleId(), _niceSpaceApp.contains(front) {
        newChar = 0x200C // Unicode character with empty space
    }

    let down = makeKeyEvent(0, true)
    let up = makeKeyEvent(0, false)
    setUnicode(down, [newChar], 1)
    setUnicode(up, [newChar], 1)
    post(down)
    post(up)
}

private func SendVirtualKey(_ vKey: CGKeyCode) {
    post(makeKeyEvent(vKey, true))
    post(makeKeyEvent(vKey, false))
}

private func SendBackspace() {
    post(eventBackSpaceDown)
    post(eventBackSpaceUp)

    if IS_DOUBLE_CODE(vCodeTable) { // VNI or Unicode Compound
        guard let last = _syncKey.last else { return }
        if last > 1 {
            if !(vCodeTable == 3 && containUnicodeCompoundApp(frontMostAppBundleId())) {
                post(eventBackSpaceDown)
                post(eventBackSpaceUp)
            }
        }
        _syncKey.removeLast()
    }
}

private func SendShiftAndLeftArrow() {
    let down = makeKeyEvent(CGKeyCode(KEY_LEFT), true)
    let up = makeKeyEvent(CGKeyCode(KEY_LEFT), false)
    var privateFlag = down?.flags ?? []
    privateFlag.insert(.maskShift)
    down?.flags = privateFlag
    up?.flags = privateFlag

    post(down)
    post(up)

    if IS_DOUBLE_CODE(vCodeTable) { // VNI or Unicode Compound
        guard let last = _syncKey.last else { return }
        if last > 1 {
            if !(vCodeTable == 3 && containUnicodeCompoundApp(frontMostAppBundleId())) {
                post(down)
                post(up)
            }
        }
        _syncKey.removeLast()
    }
}

private func SendCutKey() {
    let down = makeKeyEvent(CGKeyCode(KEY_X), true)
    let up = makeKeyEvent(CGKeyCode(KEY_X), false)
    var privateFlag = down?.flags ?? []
    privateFlag.insert(.maskCommand)
    down?.flags = privateFlag
    up?.flags = privateFlag

    post(down)
    post(up)
}

private func SendNewCharString(_ dataFromMacro: Bool = false, _ offset: Int = 0) {
    var j = 0
    _newCharSize = dataFromMacro ? Int(OK_MacroDataSize()) : Int(OK_NewCharCount())
    _willContinuteSending = false
    _willSendControlKey = false

    // append one engine character into _newCharString
    func appendChar(_ tempChar: UInt32) {
        if (tempChar & PURE_CHARACTER_MASK) != 0 {
            _newCharString[j] = UInt16(truncatingIfNeeded: tempChar); j += 1
            if IS_DOUBLE_CODE(vCodeTable) {
                InsertKeyLength(1)
            }
        } else if (tempChar & CHAR_CODE_MASK) == 0 {
            if IS_DOUBLE_CODE(vCodeTable) { // VNI
                InsertKeyLength(1)
            }
            _newCharString[j] = OK_KeyCodeToCharacter(tempChar); j += 1
        } else {
            if vCodeTable == 0 { // unicode 2 bytes code
                _newCharString[j] = UInt16(truncatingIfNeeded: tempChar); j += 1
            } else if vCodeTable == 1 || vCodeTable == 2 || vCodeTable == 4 {
                // others such as VNI Windows, TCVN3: 1 byte code
                let full = UInt16(truncatingIfNeeded: tempChar)
                let hi = (full >> 8) & 0xFF
                _newCharString[j] = full & 0xFF; j += 1

                if hi > 32 {
                    if vCodeTable == 2 { // VNI
                        InsertKeyLength(2)
                    }
                    _newCharString[j] = hi; j += 1
                    _newCharSize += 1
                } else {
                    if vCodeTable == 2 { // VNI
                        InsertKeyLength(1)
                    }
                }
            } else if vCodeTable == 3 { // Unicode Compound
                var full = UInt16(truncatingIfNeeded: tempChar)
                let hi = full >> 13
                full &= 0x1FFF

                InsertKeyLength(hi > 0 ? 2 : 1)
                _newCharString[j] = full; j += 1
                if hi > 0 {
                    _newCharSize += 1
                    _newCharString[j] = OK_UnicodeCompoundMark(Int32(hi) - 1); j += 1
                }
            }
        }
    }

    if _newCharSize > 0 {
        if dataFromMacro {
            _k = offset
            while _k < Int(OK_MacroDataSize()) {
                if j >= 16 {
                    _willContinuteSending = true
                    break
                }
                appendChar(OK_MacroDataAt(Int32(_k)))
                _k += 1
            }
        } else {
            _k = Int(OK_NewCharCount()) - 1 - offset
            while _k >= 0 {
                if j >= 16 {
                    _willContinuteSending = true
                    break
                }
                appendChar(OK_CharDataAt(Int32(_k)))
                _k -= 1
            }
        }
    }

    let code = OK_Code()

    if !_willContinuteSending && (code == vRestore || code == vRestoreAndStartNewSession) {
        // if is restore
        if OK_KeyCodeToCharacter(UInt32(_keycode)) != 0 {
            _newCharSize += 1
            let caps: UInt32 = (_flag.contains(.maskAlphaShift) || _flag.contains(.maskShift)) ? CAPS_MASK : 0
            _newCharString[j] = OK_KeyCodeToCharacter(UInt32(_keycode) | caps); j += 1
        } else {
            _willSendControlKey = true
        }
    }
    if !_willContinuteSending && code == vRestoreAndStartNewSession {
        OK_StartNewSession()
    }

    let length = _willContinuteSending ? 16 : (_newCharSize - offset)
    let down = makeKeyEvent(0, true)
    let up = makeKeyEvent(0, false)
    setUnicode(down, _newCharString, length)
    setUnicode(up, _newCharString, length)
    post(down)
    post(up)

    if _willContinuteSending {
        SendNewCharString(dataFromMacro, dataFromMacro ? _k : 16)
    }

    // the case when hCode is vRestore or vRestoreAndStartNewSession, the word is invalid
    // and the last key is a control key such as TAB, LEFT ARROW, RIGHT ARROW,...
    if _willSendControlKey {
        SendKeyCode(UInt32(_keycode))
    }
}

// MARK: - Hot keys

private func checkHotKey(_ hotKeyData: Int32, _ checkKeyCode: Bool = true) -> Bool {
    if (hotKeyData & ~0x8000) == EMPTY_HOTKEY {
        return false
    }
    if HAS_CONTROL(hotKeyData) != _lastFlag.contains(.maskControl) { return false }
    if HAS_OPTION(hotKeyData) != _lastFlag.contains(.maskAlternate) { return false }
    if HAS_COMMAND(hotKeyData) != _lastFlag.contains(.maskCommand) { return false }
    if HAS_SHIFT(hotKeyData) != _lastFlag.contains(.maskShift) { return false }
    if checkKeyCode {
        if GET_SWITCH_KEY(hotKeyData) != _keycode { return false }
    }
    return true
}

private func switchLanguage() {
    vLanguage = (vLanguage == 0) ? 1 : 0
    if HAS_BEEP(vSwitchKeyStatus) {
        NSSound.beep()
    }
    (NSApp.delegate as? AppDelegate)?.onImputMethodChanged(true)
    OK_StartNewSession()
}

private func handleMacro() {
    // fix autocomplete
    if shouldUseRecommendWorkaround(frontMostAppBundleId()) {
        SendEmptyCharacter()
        OK_SetBackspaceCount(OK_BackspaceCount() &+ 1)
    }

    // send backspace
    let backspaceCount = Int(OK_BackspaceCount())
    if backspaceCount > 0 {
        for _ in 0..<backspaceCount {
            SendBackspace()
        }
    }

    // send real data
    if vSendKeyStepByStep == 0 {
        SendNewCharString(true)
    } else {
        for i in 0..<Int(OK_MacroDataSize()) {
            let data = OK_MacroDataAt(Int32(i))
            if (data & PURE_CHARACTER_MASK) != 0 {
                SendPureCharacter(UInt16(truncatingIfNeeded: data))
            } else {
                SendKeyCode(data)
            }
        }
    }
    SendKeyCode(UInt32(_keycode) | (_flag.contains(.maskShift) ? CAPS_MASK : 0))
}

// MARK: - Keyboard layout compatibility

// TODO: Research API to convert character into CGKeyCode more elegantly!
private func ConvertKeyStringToKeyCode(_ keyString: String?, _ fallback: CGKeyCode) -> CGKeyCode {
    // Information about capitalization (shift/caps) is already included in the original
    // CGEvent, we only need to find out which position on the keyboard a key is pressed.
    guard let lowercased = keyString?.lowercased(),
          let keycode = keyStringToKeyCodeMap[lowercased] else {
        return fallback
    }
    return keycode
}

/// If conversion fails, return fallbackKeyCode
private func ConvertEventToKeyboardLayoutCompatKeyCode(_ keyEvent: CGEvent,
                                                       _ fallbackKeyCode: CGKeyCode) -> CGKeyCode {
    guard let nsEvent = NSEvent(cgEvent: keyEvent) else { return fallbackKeyCode }
    return ConvertKeyStringToKeyCode(nsEvent.charactersIgnoringModifiers, fallbackKeyCode)
}

/// "turn off Vietnamese when in other language" mode
private func isTypingInOtherLanguage() -> Bool {
    guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return false }
    guard let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else { return false }

    let languages = Unmanaged<CFArray>.fromOpaque(raw).takeUnretainedValue() as NSArray
    guard languages.count > 0, let current = languages[0] as? String else { return false }
    return !current.hasPrefix("en")
}

// MARK: - MAIN HOOK

/**
 * MAIN HOOK entry, very important function.
 * MAIN Callback.
 */
func OpenKeyCallback(proxy: CGEventTapProxy,
                     type: CGEventType,
                     event: CGEvent,
                     refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    // the tap gets disabled if we are too slow — turn it back on and drop this event
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        OpenKeyManager.reEnableEventTap()
        return Unmanaged.passUnretained(event)
    }

    // don't handle my own events
    if let source = myEventSource,
       event.getIntegerValueField(.eventSourceStateID) == Int64(source.sourceStateID.rawValue) {
        return Unmanaged.passUnretained(event)
    }

    _flag = event.flags
    _keycode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

    // While the clipboard picker is up it owns the keyboard. It never activates
    // OpenKey — that would pull focus off the app being typed into — so the keys
    // have to be handed to it from here. Modifier changes still pass through.
    if ClipboardPanel.shared.isOpen {
        if type == .keyUp { return nil }
        if type == .keyDown {
            // Pressing the hotkey again closes it.
            if GET_SWITCH_KEY(clipboardHotKey) == _keycode,
               checkHotKey(clipboardHotKey, GET_SWITCH_KEY(clipboardHotKey) != 0xFE) {
                ClipboardPanel.shared.dismiss()
                _lastFlag = []
                _hasJustUsedHotKey = true
                return nil
            }
            var length = 0
            var buffer = [UniChar](repeating: 0, count: 8)
            event.keyboardGetUnicodeString(maxStringLength: 8, actualStringLength: &length, unicodeString: &buffer)
            let characters = String(utf16CodeUnits: buffer, count: length)
            if ClipboardPanel.shared.handleKeyDown(keyCode: _keycode, characters: characters, flags: _flag) {
                return nil
            }
        }
    }

    if type == .keyDown && vPerformLayoutCompat != 0 {
        // If conversion fails, use current keycode
        _keycode = ConvertEventToKeyboardLayoutCompatKeyCode(event, _keycode)
    }

    // Keystroke sound. Kept ahead of every early return below so it fires in both
    // Vietnamese and English mode; the player itself does the (cheap) gating and
    // hands the actual note off to its own queue.
    if vKeySound != 0 {
        if type == .keyDown {
            KeySoundPlayer.shared.handleKeyDown(
                keycode: _keycode,
                isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0)
        } else if type == .keyUp {
            KeySoundPlayer.shared.handleKeyUp(keycode: _keycode)
        }
    }

    // switch language shortcut; convert hotkey
    if type == .keyDown {
        if GET_SWITCH_KEY(vSwitchKeyStatus) != _keycode && GET_SWITCH_KEY(convertToolHotKey) != _keycode && GET_SWITCH_KEY(clipboardHotKey) != _keycode {
            _lastFlag = []
        } else {
            if GET_SWITCH_KEY(vSwitchKeyStatus) == _keycode &&
                checkHotKey(vSwitchKeyStatus, GET_SWITCH_KEY(vSwitchKeyStatus) != 0xFE) {
                switchLanguage()
                _lastFlag = []
                _hasJustUsedHotKey = true
                return nil
            }
            if GET_SWITCH_KEY(convertToolHotKey) == _keycode &&
                checkHotKey(convertToolHotKey, GET_SWITCH_KEY(convertToolHotKey) != 0xFE) {
                (NSApp.delegate as? AppDelegate)?.onQuickConvert()
                _lastFlag = []
                _hasJustUsedHotKey = true
                return nil
            }
            if GET_SWITCH_KEY(clipboardHotKey) == _keycode &&
                checkHotKey(clipboardHotKey, GET_SWITCH_KEY(clipboardHotKey) != 0xFE) {
                (NSApp.delegate as? AppDelegate)?.showClipboardHistory()
                _lastFlag = []
                _hasJustUsedHotKey = true
                return nil
            }
        }
        _hasJustUsedHotKey = _lastFlag.rawValue != 0
    } else if type == .flagsChanged {
        if _lastFlag.rawValue == 0 || _lastFlag.rawValue < _flag.rawValue {
            _lastFlag = _flag
        } else if _lastFlag.rawValue > _flag.rawValue {
            // check switch
            if checkHotKey(vSwitchKeyStatus, GET_SWITCH_KEY(vSwitchKeyStatus) != 0xFE) {
                _lastFlag = []
                switchLanguage()
                _hasJustUsedHotKey = true
                return nil
            }
            if checkHotKey(convertToolHotKey, GET_SWITCH_KEY(convertToolHotKey) != 0xFE) {
                _lastFlag = []
                (NSApp.delegate as? AppDelegate)?.onQuickConvert()
                _hasJustUsedHotKey = true
                return nil
            }
            if checkHotKey(clipboardHotKey, GET_SWITCH_KEY(clipboardHotKey) != 0xFE) {
                _lastFlag = []
                (NSApp.delegate as? AppDelegate)?.showClipboardHistory()
                _hasJustUsedHotKey = true
                return nil
            }
            // check temporarily turn off spell checking
            if vTempOffSpelling != 0 && !_hasJustUsedHotKey && _lastFlag.contains(.maskControl) {
                OK_TempOffSpellChecking()
            }
            if vTempOffOpenKey != 0 && !_hasJustUsedHotKey && _lastFlag.contains(.maskCommand) {
                OK_TempOffEngine(true)
            }
            _lastFlag = []
            _hasJustUsedHotKey = false
        }
    }

    // Also check correct event hooked
    if type != .keyDown && type != .keyUp &&
        type != .leftMouseDown && type != .rightMouseDown &&
        type != .leftMouseDragged && type != .rightMouseDragged {
        return Unmanaged.passUnretained(event)
    }

    _proxy = proxy

    // If is in english mode
    if vLanguage == 0 {
        if vUseMacro != 0 && vUseMacroInEnglishMode != 0 && type == .keyDown {
            OK_EnglishMode(UInt16(_keycode),
                           _flag.contains(.maskShift) || _flag.contains(.maskAlphaShift),
                           OTHER_CONTROL_KEY)

            if OK_Code() == vReplaceMaro { // handle macro in english mode
                handleMacro()
                return nil
            }
        }
        return Unmanaged.passUnretained(event)
    }

    // handle mouse
    if type == .leftMouseDown || type == .rightMouseDown ||
        type == .leftMouseDragged || type == .rightMouseDragged {
        RequestNewSession()
        return Unmanaged.passUnretained(event)
    }

    // if "turn off Vietnamese when in other language" mode on
    if vOtherLanguage != 0 && isTypingInOtherLanguage() {
        return Unmanaged.passUnretained(event)
    }

    // handle keyboard
    if type == .keyDown {
        // send event signal to Engine
        let capsStatus: UInt8 = _flag.contains(.maskShift) ? 1 : (_flag.contains(.maskAlphaShift) ? 2 : 0)
        OK_HandleKeyboardEvent(UInt16(_keycode), capsStatus, OTHER_CONTROL_KEY)

        let code = OK_Code()

        if code == vDoNothing { // do nothing
            if IS_DOUBLE_CODE(vCodeTable) { // VNI
                let extCode = OK_ExtCode()
                if extCode == 1 { // break key
                    _syncKey.removeAll()
                } else if extCode == 2 { // delete key
                    if let last = _syncKey.last {
                        if last > 1 && (vCodeTable == 2 || !containUnicodeCompoundApp(frontMostAppBundleId())) {
                            // send one more backspace
                            post(eventBackSpaceDown)
                            post(eventBackSpaceUp)
                        }
                        _syncKey.removeLast()
                    }
                } else if extCode == 3 { // normal key
                    InsertKeyLength(1)
                }
            }
            return Unmanaged.passUnretained(event)
        } else if code == vWillProcess || code == vRestore || code == vRestoreAndStartNewSession {
            // handle result signal
            let frontApp = frontMostAppBundleId()

            // fix autocomplete
            if shouldUseRecommendWorkaround(frontApp) && OK_ExtCode() != 4 {
                if vFixChromiumBrowser != 0, let frontApp = frontApp, _unicodeCompoundApp.contains(frontApp) {
                    if OK_BackspaceCount() > 0 {
                        SendShiftAndLeftArrow()
                        if OK_BackspaceCount() == 1 {
                            OK_SetBackspaceCount(OK_BackspaceCount() &- 1)
                        }
                    }
                } else {
                    SendEmptyCharacter()
                    OK_SetBackspaceCount(OK_BackspaceCount() &+ 1)
                }
            }

            if shouldUseSelectionReplacement(frontApp) && OK_BackspaceCount() > 0 {
                for _ in 0..<Int(OK_BackspaceCount()) {
                    SendShiftAndLeftArrow()
                }
                OK_SetBackspaceCount(0)
            }

            // send backspace
            let backspaceCount = Int(OK_BackspaceCount())
            if backspaceCount > 0 && backspaceCount < MAX_BUFF {
                for _ in 0..<backspaceCount {
                    SendBackspace()
                }
            }

            // send new character
            if vSendKeyStepByStep == 0 {
                SendNewCharString()
            } else {
                let newCharCount = Int(OK_NewCharCount())
                if newCharCount > 0 && newCharCount <= MAX_BUFF {
                    for i in stride(from: newCharCount - 1, through: 0, by: -1) {
                        SendKeyCode(OK_CharDataAt(Int32(i)))
                    }
                }
                if code == vRestore || code == vRestoreAndStartNewSession {
                    let caps: UInt32 = (_flag.contains(.maskAlphaShift) || _flag.contains(.maskShift)) ? CAPS_MASK : 0
                    SendKeyCode(UInt32(_keycode) | caps)
                }
                if code == vRestoreAndStartNewSession {
                    OK_StartNewSession()
                }
            }
        } else if code == vReplaceMaro { // MACRO
            handleMacro()
        }

        return nil
    }

    return Unmanaged.passUnretained(event)
}
