//
//  KeySoundPlayer.swift
//  Plays a short MIDI note through the default output device on every keystroke.
//
//  The sound is synthesised at runtime by AVAudioUnitSampler driving the General MIDI
//  bank that ships with macOS (gs_instruments.dls), so no audio assets need to be
//  bundled with the app. Output goes through AVAudioEngine's main mixer, i.e. the
//  normal speaker — not the system alert device that NSSound.beep() uses.
//
//  A single drum sample on its own sounds thin and mechanical. Real key noise is two
//  events — a bright click and a duller body — plus a quieter one when the key comes
//  back up, and no two presses sound quite alike. So each voice here layers two notes,
//  rotates between variants so consecutive keys differ, and optionally clicks on
//  release. (Varying pitch instead would be the obvious trick, but the GM drum kit
//  ignores pitch bend: bending it ±2 semitones leaves the rendered waveform unchanged.)
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
var vKeySoundRelease: Int32 = 1

final class KeySoundPlayer {

    static let shared = KeySoundPlayer()

    /// One note of a layered hit. `gain` is dB relative to the layer struck hardest,
    /// applied through MIDI velocity.
    struct Layer {
        let note: UInt8
        let gain: Float
        init(_ note: UInt8, _ gain: Float = 0) { self.note = note; self.gain = gain }
    }

    struct Voice {
        let name: String
        /// Struck together on key down. The variants rotate per keystroke so a run of
        /// typing doesn't sound like the same sample looping.
        let down: [[Layer]]
        /// Space / Enter / Delete / Tab when the special-key option is on.
        let alt: [Layer]
        /// Quieter hit when the key is released.
        let up: [Layer]
        /// Make-up gain in dB bringing this voice to the same peak as the others.
        /// Calibrated at velocity 127 against the macOS GM bank at 48 kHz, which
        /// renders ~1.4x hotter than 44.1 kHz; using the louder rate as the reference
        /// keeps 44.1 kHz devices clear of clipping too.
        let trim: Float
    }

    /// Order must stay in sync with the popup in ViewController.xib — the selected
    /// index is what gets persisted.
    static let voices: [Voice] = [
        Voice(name: "Bàn phím cơ (thock)",
              down: [[Layer(77), Layer(37, -5)], [Layer(76, -1), Layer(37, -5)]],
              alt: [Layer(41), Layer(37, -5)], up: [Layer(76, -6)], trim: 3.2),
        Voice(name: "Bàn phím cơ (clicky)",
              down: [[Layer(75), Layer(42, -3)], [Layer(76, -1), Layer(42, -3)]],
              alt: [Layer(75), Layer(37, -3)], up: [Layer(42, -0.5)], trim: 3.4),
        Voice(name: "Máy đánh chữ",
              down: [[Layer(37), Layer(42, -4)], [Layer(37, -2), Layer(75, -6)]],
              alt: [Layer(38, -3), Layer(42, -4)], up: [Layer(75, -7)], trim: 5.3),
        Voice(name: "Gõ mộc",
              down: [[Layer(76), Layer(77, -4)], [Layer(77), Layer(76, -4)]],
              alt: [Layer(75), Layer(77, -4)], up: [Layer(76, -6)], trim: 2.4),
        Voice(name: "Trầm sâu",
              down: [[Layer(41), Layer(77, -6)], [Layer(43, -1), Layer(77, -6)]],
              alt: [Layer(41), Layer(37, -8)], up: [Layer(77, -6)], trim: 3.0),
        Voice(name: "Êm nhẹ",
              down: [[Layer(42), Layer(80, -10)], [Layer(42, -2), Layer(80, -12)]],
              alt: [Layer(42), Layer(37, -10)], up: [Layer(42, -7)], trim: 16.2),
    ]

    private static let bankURL = URL(fileURLWithPath:
        "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")

    /// Keys that get `alt` when "âm riêng cho phím đặc biệt" is on.
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
    private var lastDown: CFTimeInterval = 0
    private var lastUp: CFTimeInterval = 0

    /// Key repeat can fire far faster than the samples decay; ignore anything closer
    /// together than this so holding a key doesn't turn into a buzz. Down and up are
    /// throttled separately, otherwise a quick tap loses its release click.
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
        guard vKeySound != 0, passesLanguageGate() else { return }

        let now = CACurrentMediaTime()
        if now - lastDown < minInterval { return }
        lastDown = now

        let voice = Self.currentVoice()
        let layers: [Layer]
        if vKeySoundSpecialKeys != 0 && Self.specialKeyCodes.contains(keycode) {
            layers = voice.alt
        } else {
            // Rotate variants by key so neighbouring keys don't sound identical.
            layers = voice.down[Int(keycode) % voice.down.count]
        }
        // Velocity jitter, downwards only so the calibrated trims stay clear of clipping.
        let drop = Int32(keycode % 7) + (isRepeat ? 12 : 0)
        queue.async { self.strike(layers, trim: voice.trim, velocityDrop: drop) }
    }

    /// The quieter click as the key comes back up.
    func handleKeyUp(keycode: CGKeyCode) {
        guard vKeySound != 0, vKeySoundRelease != 0, passesLanguageGate() else { return }

        let now = CACurrentMediaTime()
        if now - lastUp < minInterval { return }
        lastUp = now

        let voice = Self.currentVoice()
        guard !voice.up.isEmpty else { return }
        let drop = Int32(keycode % 5)
        queue.async { self.strike(voice.up, trim: voice.trim, velocityDrop: drop) }
    }

    /// Plays one hit with the current settings — used by the "Nghe thử" button.
    func preview() {
        let voice = Self.currentVoice()
        queue.async {
            self.prepare()
            self.strike(voice.down[0], trim: voice.trim, velocityDrop: 0)
            if vKeySoundRelease != 0 && !voice.up.isEmpty {
                self.queue.asyncAfter(deadline: .now() + 0.09) {
                    self.strike(voice.up, trim: voice.trim, velocityDrop: 0)
                }
            }
        }
    }

    // MARK: - Helpers

    private static func currentVoice() -> Voice {
        voices[Int(max(0, min(Int32(voices.count - 1), vKeySoundVoice)))]
    }

    private func passesLanguageGate() -> Bool {
        !(vKeySoundOnlyVietnamese != 0 && vLanguage == 0)
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

    private func strike(_ layers: [Layer], trim: Float, velocityDrop: Int32) {
        prepare()
        guard isPrepared, engine.isRunning, vKeySoundVolume > 0 else { return }

        // All loudness shaping happens in the gain stage: the per-voice trim plus the
        // user's volume in dB. It has to be here rather than mainMixerNode.outputVolume
        // — changing the mixer's volume once the engine is already running has no
        // effect, so the slider would only ever have worked on the very first play.
        let level = Float(max(0, min(100, vKeySoundVolume))) / 100.0
        gain.globalGain = min(24, max(-96, trim + 20 * log10(level)))

        for layer in layers {
            let scaled = 127.0 * pow(10.0, layer.gain / 20.0) - Float(velocityDrop)
            let velocity = UInt8(max(8, min(127, Int32(scaled))))
            sampler.startNote(layer.note, withVelocity: velocity, onChannel: 0)
        }
        // One-shot samples ignore note-off, but sending it frees the voice slots.
        queue.asyncAfter(deadline: .now() + 0.2) {
            for layer in layers { self.sampler.stopNote(layer.note, onChannel: 0) }
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
