//
//  EngineBridge.cpp
//  OpenKey
//

#include "EngineBridge.h"
#include "Engine.h"

#include <string>
#include <vector>

using namespace std;

static vector<Byte> _smartSwitchKeyBuffer;
static string _convertResultBuffer;

extern "C" {

#pragma mark - lifecycle

void OK_KeyInit(void) {
    pData = (vKeyHookState*)vKeyInit();
}

bool OK_HasData(void) {
    return pData != NULL;
}

#pragma mark - hook state

uint8_t OK_Code(void) {
    return pData ? pData->code : 0;
}

uint8_t OK_ExtCode(void) {
    return pData ? pData->extCode : 0;
}

uint8_t OK_BackspaceCount(void) {
    return pData ? pData->backspaceCount : 0;
}

void OK_SetBackspaceCount(uint8_t value) {
    if (pData)
        pData->backspaceCount = value;
}

uint8_t OK_NewCharCount(void) {
    return pData ? pData->newCharCount : 0;
}

uint32_t OK_CharDataAt(int index) {
    if (pData && index >= 0 && index < MAX_BUFF)
        return pData->charData[index];
    return 0;
}

int OK_MacroDataSize(void) {
    return pData ? (int)pData->macroData.size() : 0;
}

uint32_t OK_MacroDataAt(int index) {
    if (pData && index >= 0 && index < (int)pData->macroData.size())
        return pData->macroData[index];
    return 0;
}

#pragma mark - engine events

void OK_HandleKeyboardEvent(uint16_t keyCode, uint8_t capsStatus, bool otherControlKey) {
    vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, keyCode, capsStatus, otherControlKey);
}

void OK_HandleMouseEvent(void) {
    vKeyHandleEvent(vKeyEvent::Mouse, vKeyEventState::MouseDown, 0);
}

void OK_EnglishMode(uint16_t keyCode, bool isCaps, bool otherControlKey) {
    vEnglishMode(vKeyEventState::KeyDown, keyCode, isCaps, otherControlKey);
}

void OK_StartNewSession(void) {
    startNewSession();
}

void OK_TempOffSpellChecking(void) {
    vTempOffSpellChecking();
}

void OK_TempOffEngine(bool off) {
    vTempOffEngine(off);
}

void OK_SetCheckSpelling(void) {
    vSetCheckSpelling();
}

#pragma mark - character helpers

uint16_t OK_KeyCodeToCharacter(uint32_t keyCode) {
    return keyCodeToCharacter(keyCode);
}

uint16_t OK_UnicodeCompoundMark(int index) {
    if (index < 0)
        return 0;
    return _unicodeCompoundMark[index];
}

#pragma mark - macro

void OK_InitMacroMap(const uint8_t* data, int size) {
    initMacroMap((const Byte*)data, size);
}

void OK_OnTableCodeChange(void) {
    onTableCodeChange();
}

#pragma mark - smart switch key

void OK_InitSmartSwitchKey(const uint8_t* data, int size) {
    initSmartSwitchKey((const Byte*)data, size);
}

const uint8_t* OK_SmartSwitchKeySaveData(int* outLength) {
    _smartSwitchKeyBuffer.clear();
    getSmartSwitchKeySaveData(_smartSwitchKeyBuffer);
    if (outLength)
        *outLength = (int)_smartSwitchKeyBuffer.size();
    return _smartSwitchKeyBuffer.empty() ? NULL : _smartSwitchKeyBuffer.data();
}

int OK_GetAppInputMethodStatus(const char* bundleId, int currentInputMethod) {
    return getAppInputMethodStatus(string(bundleId ? bundleId : ""), currentInputMethod);
}

void OK_SetAppInputMethodStatus(const char* bundleId, int language) {
    setAppInputMethodStatus(string(bundleId ? bundleId : ""), language);
}

void OK_RemoveAppInputMethodStatus(const char* bundleId) {
    removeAppInputMethodStatus(string(bundleId ? bundleId : ""));
}

void OK_ClearAllAppInputMethodStatus(void) {
    clearAllAppInputMethodStatus();
}

int OK_GetSmartSwitchKeyCount(void) {
    return getSmartSwitchKeyCount();
}

const char* OK_GetSmartSwitchKeyBundleId(int index) {
    return getSmartSwitchKeyBundleId(index);
}

int OK_GetSmartSwitchKeyLanguage(int index) {
    return getSmartSwitchKeyLanguage(index);
}

#pragma mark - convert tool

const char* OK_ConvertUtil(const char* source) {
    _convertResultBuffer = convertUtil(string(source ? source : ""));
    return _convertResultBuffer.c_str();
}

#pragma mark - misc

const char* OK_BuildDate(void) {
    return __DATE__;
}

}
