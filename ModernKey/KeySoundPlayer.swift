//
//  KeySoundPlayer.swift
//  Plays a short MIDI note through the default output device on every keystroke.
//
//  The sound is synthesised at runtime by AVAudioUnitSampler driving the General MIDI
//  bank that ships with macOS (gs_instruments.dls), so no audio assets need to be
//  bundled with the app. Output goes through AVAudioEngine's main mixer, i.e. the
//  normal speaker — not the system alert device that NSSound.beep() uses.
//

import AVFoundation
import Carbon
import Cocoa

// MARK: - Settings (mirrored from UserDefaults, read on the event tap thread)

var vKeySound: Int32 = 0
var vKeySoundVoice: Int32 = 0
var vKeySoundVolume: Int32 = 60
var vKeySoundOnlyVietnamese: Int32 = 0
var vKeySoundSpecialKeys: Int32 = 1

final class KeySoundPlayer {

    static let shared = KeySoundPlayer()

    /// A GM percussion voice that sounds like a keypress. `note` and `altNote` are
    /// MIDI note numbers on the General MIDI drum map.
    struct Voice {
        let name: String
        let note: UInt8
        let altNote: UInt8
    }

    /// Order must stay in sync with the popup in ViewController.xib — the selected
    /// index is what gets persisted.
    static let voices: [Voice] = [
        Voice(name: "Gõ mộc (Wood Block)",   note: 76, altNote: 77),
        Voice(name: "Lách cách (Side Stick)", note: 37, altNote: 38),
        Voice(name: "Máy đánh chữ (Claves)",  note: 75, altNote: 76),
        Voice(name: "Hi-Hat",                 note: 42, altNote: 46),
        Voice(name: "Chuông (Triangle)",      note: 80, altNote: 81),
        Voice(name: "Vỗ tay (Hand Clap)",     note: 39, altNote: 39),
    ]

    private static let bankURL = URL(fileURLWithPath:
        "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")

    /// Keys that get `altNote` when "âm riêng cho phím đặc biệt" is on.
    private static let specialKeyCodes: Set<CGKeyCode> = [
        CGKeyCode(kVK_Space), CGKeyCode(kVK_Return), CGKeyCode(kVK_ANSI_KeypadEnter),
        CGKeyCode(kVK_Delete), CGKeyCode(kVK_ForwardDelete), CGKeyCode(kVK_Tab),
    ]

    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()

    /// All engine/sampler mutation happens here so the event tap thread never blocks.
    private let queue = DispatchQueue(label: "org.openkey.keysound", qos: .userInteractive)

    private var isPrepared = false
    private var lastPlayed: CFTimeInterval = 0

    /// Key repeat can fire far faster than the samples decay; ignore anything closer
    /// together than this so holding a key doesn't turn into a buzz.
    private let minInterval: CFTimeInterval = 0.012

    private init() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        // The output device can change under us (headphones plugged in, display
        // sleep, Bluetooth speaker). The engine stops itself; bring it back.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConfigurationChange),
            name: .AVAudioEngineConfigurationChange,
            object: engine)
    }

    // MARK: - Public API

    /// Loads settings from UserDefaults and spins the audio engine up or down to match.
    func applySettings() {
        queue.async {
            self.engine.mainMixerNode.outputVolume = Float(max(0, min(100, vKeySoundVolume))) / 100.0
            if vKeySound != 0 {
                self.prepare()
            } else {
                self.teardown()
            }
        }
    }

    /// Called from the CGEventTap callback — must return immediately.
    func handleKeyDown(keycode: CGKeyCode, isRepeat: Bool) {
        guard vKeySound != 0 else { return }
        if vKeySoundOnlyVietnamese != 0 && vLanguage == 0 { return }

        let now = CACurrentMediaTime()
        if now - lastPlayed < minInterval { return }
        lastPlayed = now

        let useAlt = vKeySoundSpecialKeys != 0 && Self.specialKeyCodes.contains(keycode)
        // Slight velocity jitter keeps a long burst of typing from sounding robotic.
        let jitter = Int32(keycode % 7) - 3
        queue.async { self.strike(useAlt: useAlt, velocityOffset: isRepeat ? -12 + jitter : jitter) }
    }

    /// Plays one note with the current settings — used by the "Nghe thử" button.
    func preview() {
        queue.async {
            self.engine.mainMixerNode.outputVolume = Float(max(0, min(100, vKeySoundVolume))) / 100.0
            self.prepare()
            self.strike(useAlt: false, velocityOffset: 0)
        }
    }

    // MARK: - Engine (queue only)

    private func prepare() {
        if !isPrepared {
            guard FileManager.default.fileExists(atPath: Self.bankURL.path) else {
                NSLog("KeySoundPlayer: General MIDI bank not found at \(Self.bankURL.path)")
                return
            }
            do {
                // 0x78 selects the percussion bank; the program number is ignored for it.
                try sampler.loadSoundBankInstrument(at: Self.bankURL,
                                                    program: 0,
                                                    bankMSB: 0x78,
                                                    bankLSB: 0)
            } catch {
                NSLog("KeySoundPlayer: could not load MIDI bank — \(error.localizedDescription)")
                return
            }
            isPrepared = true
        }

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                NSLog("KeySoundPlayer: could not start audio engine — \(error.localizedDescription)")
                isPrepared = false
                return
            }
        }
    }

    private func teardown() {
        if engine.isRunning {
            engine.stop()
        }
    }

    private func strike(useAlt: Bool, velocityOffset: Int32) {
        prepare()
        guard isPrepared, engine.isRunning else { return }

        let voice = Self.voices[Int(max(0, min(Int32(Self.voices.count - 1), vKeySoundVoice)))]
        let note = useAlt ? voice.altNote : voice.note

        // Percussion samples are one-shot, so velocity is what controls loudness
        // per hit; the mixer sets the overall level.
        let base = Int32(64) + (max(0, min(100, vKeySoundVolume)) - 60) / 2
        let velocity = UInt8(max(24, min(127, base + velocityOffset)))

        sampler.startNote(note, withVelocity: velocity, onChannel: 0)
        // One-shot samples ignore note-off, but sending it frees the voice slot.
        queue.asyncAfter(deadline: .now() + 0.15) {
            self.sampler.stopNote(note, onChannel: 0)
        }
    }

    @objc private func handleConfigurationChange() {
        queue.async {
            guard vKeySound != 0 else { return }
            self.isPrepared = false
            self.prepare()
        }
    }
}
