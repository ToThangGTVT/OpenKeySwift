//
//  EngineBridge.h
//  OpenKey
//
//  Plain-C bridge over the C++ engine so Swift never has to touch
//  std::string / std::vector / C++ references.
//

#ifndef EngineBridge_h
#define EngineBridge_h

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- engine lifecycle ---- */
void      OK_KeyInit(void);
bool      OK_HasData(void);

/* ---- vKeyHookState accessors ---- */
uint8_t   OK_Code(void);
uint8_t   OK_ExtCode(void);
uint8_t   OK_BackspaceCount(void);
void      OK_SetBackspaceCount(uint8_t value);
uint8_t   OK_NewCharCount(void);
uint32_t  OK_CharDataAt(int index);
int       OK_MacroDataSize(void);
uint32_t  OK_MacroDataAt(int index);

/* ---- engine events ---- */
void      OK_HandleKeyboardEvent(uint16_t keyCode, uint8_t capsStatus, bool otherControlKey);
void      OK_HandleMouseEvent(void);
void      OK_EnglishMode(uint16_t keyCode, bool isCaps, bool otherControlKey);
void      OK_StartNewSession(void);
void      OK_TempOffSpellChecking(void);
void      OK_TempOffEngine(bool off);
void      OK_SetCheckSpelling(void);

/* ---- character helpers ---- */
uint16_t  OK_KeyCodeToCharacter(uint32_t keyCode);
uint16_t  OK_UnicodeCompoundMark(int index);

/* ---- macro ---- */
void      OK_InitMacroMap(const uint8_t* data, int size);
void      OK_OnTableCodeChange(void);

/* ---- smart switch key ---- */
void      OK_InitSmartSwitchKey(const uint8_t* data, int size);
/* Returns a pointer to an internal buffer valid until the next call. */
const uint8_t* OK_SmartSwitchKeySaveData(int* outLength);
int       OK_GetAppInputMethodStatus(const char* bundleId, int currentInputMethod);
void      OK_SetAppInputMethodStatus(const char* bundleId, int language);

/* ---- convert tool ---- */
/* Returns a pointer to an internal buffer valid until the next call. */
const char* OK_ConvertUtil(const char* source);

/* ---- misc ---- */
const char* OK_BuildDate(void);

#ifdef __cplusplus
}
#endif

#endif /* EngineBridge_h */
