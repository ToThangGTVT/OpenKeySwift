#pragma once
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int Macro_GetCount(void);
const char* Macro_GetText(int index);
const char* Macro_GetContent(int index);
bool Macro_Add(const char* text, const char* content);
bool Macro_Delete(const char* text);
bool Macro_Has(const char* text);

/// Refresh the table cache from the engine.
void Macro_Reload(void);

/// Serialized macro data to persist. Valid until the next call.
const uint8_t* Macro_SaveData(int* outLength);

void Macro_ReadFromFile(const char* path, bool append);
void Macro_SaveToFile(const char* path);

#ifdef __cplusplus
}
#endif
