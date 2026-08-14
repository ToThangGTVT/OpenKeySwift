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
        /// Make-up gain in dB. The bank's percussion samples differ hugely in level
        /// — Hi-Hat sits about 6 dB below Wood Block — so each voice carries a trim
        /// that brings it to roughly the same peak. Calibrated at velocity 127 against
        /// the macOS GM bank at 48 kHz, which renders ~1.4x hotter than 44.1 kHz; using
        /// the louder rate as the reference keeps 44.1 kHz devices clear of clipping too.
        let trim: Float
    }

    /// Order must stay in sync with the popup in ViewController.xib — the selected
    /// index is what gets persisted.
    static let voices: [Voice] = [
        Voice(name: "Gõ mộc (Wood Block)",    note: 76, altNote: 77, trim: 4.3),
        Voice(name: "Lách cách (Side Stick)", note: 37, altNote: 38, trim: 4.9),
        Voice(name: "Máy đánh chữ (Claves)",  note: 75, altNote: 76, trim: 4.3),
        Voice(name: "Hi-Hat",                 note: 42, altNote: 46, trim: 10.8),
        Voice(name: "Chuông (Triangle)",      note: 80, altNote: 81, trim: 7.5),
        Voice(name: "Vỗ tay (Hand Clap)",     note: 39, altNote: 39, trim: 9.4),
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
    /// Pure gain stage. The sampler's own overallGain caps at +12 dB, which is not
    /// enough to lift the quieter percussion samples to a useful level; an EQ with
    /// no bands gives us up to +24 dB more.
    private let gain = AVAudioUnitEQ(numberOfBands: 0)

    /// All engine/sampler mutation happens here so the event tap thread never blocks.
    private let queue = DispatchQueue(label: "org.openkey.keysound", qos: .userInteractive)

    private var isPrepared = false
    private var lastPlayed: CFTimeInterval = 0

    /// Key repeat can fire far faster than the samples decay; ignore anything closer
    /// together than this so holding a key doesn't turn into a buzz.
    private let minInterval: CFTimeInterval = 0.012

    private init() {
        engine.attach(sampler)
        engine.attach(gain)

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
        // Only ever downwards, so the calibrated trims stay clear of clipping.
        let drop = Int32(keycode % 7) + (isRepeat ? 12 : 0)
        queue.async { self.strike(useAlt: useAlt, velocityDrop: drop) }
    }

    /// Plays one note with the current settings — used by the "Nghe thử" button.
    func preview() {
        queue.async {
            self.prepare()
            self.strike(useAlt: false, velocityDrop: 0)
        }
    }

    // MARK: - Engine (queue only)

    private func prepare() {
        if !isPrepared {
            guard FileManager.default.fileExists(atPath: Self.bankURL.path) else {
                NSLog("KeySoundPlayer: General MIDI bank not found at \(Self.bankURL.path)")
                return
            }

            // Connect through a MONO format on purpose. The GM drum kit pans each
            // percussion instrument across the stereo field the way a real kit sits
            // on a stage — Wood Block lands hard left, Hi-Hat right — which for a UI
            // click just sounds like a broken earbud. The bank bakes that pan into
            // its regions, so neither stereoPan nor CC10 can undo it; downmixing to
            // one channel and letting the mixer place it at pan 0 centres every voice.
            // Rebuilt on every prepare() so it follows the output device's sample rate.
            let rate = engine.outputNode.outputFormat(forBus: 0).sampleRate
            guard let mono = AVAudioFormat(standardFormatWithSampleRate: rate > 0 ? rate : 44100,
                                           channels: 1) else {
                NSLog("KeySoundPlayer: could not build mono format")
                return
            }
            engine.connect(sampler, to: gain, format: mono)
            engine.connect(gain, to: engine.mainMixerNode, format: mono)
            sampler.pan = 0

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

    private func strike(useAlt: Bool, velocityDrop: Int32) {
        prepare()
        guard isPrepared, engine.isRunning else { return }

        guard vKeySoundVolume > 0 else { return }

        let voice = Self.voices[Int(max(0, min(Int32(Self.voices.count - 1), vKeySoundVoice)))]
        let note = useAlt ? voice.altNote : voice.note

        // Drive the sampler near full velocity and do all the loudness shaping in the
        // gain stage: the per-voice trim plus the user's volume, converted to dB.
        // It has to be the gain stage rather than mainMixerNode.outputVolume — changing
        // the mixer's volume once the engine is already running has no effect, so the
        // slider would only ever have worked on the very first play.
        let level = Float(max(0, min(100, vKeySoundVolume))) / 100.0
        gain.globalGain = min(24, max(-96, voice.trim + 20 * log10(level)))
        let velocity = UInt8(max(40, min(127, 127 - velocityDrop)))

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
