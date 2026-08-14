#include "MacroBridge.h"
#include "Macro.h"
#include "DataType.h"
#include <vector>
#include <string>

using namespace std;

static vector<vector<Uint32>> cachedKeys;
static vector<string> cachedTexts;
static vector<string> cachedContents;
static vector<Byte> cachedSaveData;

extern "C" {

int Macro_GetCount(void) {
    return (int)cachedTexts.size();
}

const char* Macro_GetText(int index) {
    if (index >= 0 && index < (int)cachedTexts.size()) {
        return cachedTexts[index].c_str();
    }
    return "";
}

const char* Macro_GetContent(int index) {
    if (index >= 0 && index < (int)cachedContents.size()) {
        return cachedContents[index].c_str();
    }
    return "";
}

void Macro_Reload(void) {
    getAllMacro(cachedKeys, cachedTexts, cachedContents);
}

const uint8_t* Macro_SaveData(int* outLength) {
    cachedSaveData.clear();
    getMacroSaveData(cachedSaveData);
    if (outLength)
        *outLength = (int)cachedSaveData.size();
    return cachedSaveData.empty() ? NULL : cachedSaveData.data();
}

bool Macro_Add(const char* text, const char* content) {
    return addMacro(string(text ? text : ""), string(content ? content : ""));
}

bool Macro_Delete(const char* text) {
    return deleteMacro(string(text ? text : ""));
}

bool Macro_Has(const char* text) {
    return hasMacro(string(text ? text : ""));
}

void Macro_ReadFromFile(const char* path, bool append) {
    readFromFile(string(path ? path : ""), append);
}

void Macro_SaveToFile(const char* path) {
    saveToFile(string(path ? path : ""));
}

}
