//
//  KeySoundService.swift
//  ModernKey
//
//  Service protocol and wrapper for typing sound effects.
//

import Cocoa

protocol KeySoundServiceProtocol {
    var voiceNames: [String] { get }
    func applySettings()
    func preview()
    func setEnabled(_ enabled: Bool)
    func setVoice(index: Int)
    func setVolume(_ volume: Int)
    func setOnlyVietnamese(_ enabled: Bool)
    func setSpecialKeys(_ enabled: Bool)
    func setReleaseSound(_ enabled: Bool)
}

final class KeySoundService: KeySoundServiceProtocol {
    static let shared = KeySoundService()
    
    private init() {}
    
    var voiceNames: [String] {
        return KeySoundPlayer.voices.map { $0.name }
    }
    
    func applySettings() {
        KeySoundPlayer.shared.applySettings()
    }
    
    func preview() {
        KeySoundPlayer.shared.preview()
    }
    
    func setEnabled(_ enabled: Bool) {
        vKeySound = enabled ? 1 : 0
        UserDefaults.standard.set(vKeySound, forKey: "vKeySound")
        applySettings()
    }
    
    func setVoice(index: Int) {
        vKeySoundVoice = Int32(index)
        UserDefaults.standard.set(vKeySoundVoice, forKey: "vKeySoundVoice")
    }
    
    func setVolume(_ volume: Int) {
        vKeySoundVolume = Int32(volume)
        UserDefaults.standard.set(vKeySoundVolume, forKey: "vKeySoundVolume")
    }
    
    func setOnlyVietnamese(_ enabled: Bool) {
        vKeySoundOnlyVietnamese = enabled ? 1 : 0
        UserDefaults.standard.set(vKeySoundOnlyVietnamese, forKey: "vKeySoundOnlyVietnamese")
    }
    
    func setSpecialKeys(_ enabled: Bool) {
        vKeySoundSpecialKeys = enabled ? 1 : 0
        UserDefaults.standard.set(vKeySoundSpecialKeys, forKey: "vKeySoundSpecialKeys")
    }
    
    func setReleaseSound(_ enabled: Bool) {
        vKeySoundRelease = enabled ? 1 : 0
        UserDefaults.standard.set(vKeySoundRelease, forKey: "vKeySoundRelease")
    }
}
