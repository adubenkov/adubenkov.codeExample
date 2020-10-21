//
//  AudioSessionService.swift
//  
//
//  Created by Andrey Dubenkov on 05/06/2019.
//  Copyright © 2019 . All rights reserved.
//

import AudioKit

final class AudioSessionService: AudioSessionServiceProtocol {

    private var isAudioSessionConfigured: Bool = false
    private var isAudioEngineConfigured: Bool = false
    private var isAudioSessionActive: Bool = false

    var audioOutput: AKNode? {
        get {
            return AudioKit.output
        }
        set {
            AudioKit.output = newValue
        }
    }

    init() {
        setupAudioKitSettings()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startAudioSession() throws {
        if !isAudioSessionActive {
            try setAudioSessionActive(true)
        }
    }

    func stopAudioSession() throws {
        if isAudioSessionActive {
            try setAudioSessionActive(false)
        }
    }

    func startAudioEngine() throws {
        configureAudioEngineIfNeeded()
        if !AudioKit.engine.isRunning {
            try AudioKit.start()
        }
    }

    func stopAudioEngine() throws {
        configureAudioEngineIfNeeded()
        if AudioKit.engine.isRunning {
            try AudioKit.stop()
        }
    }

    func configureAudioSampleRate() {
        // AudioKit usually uses wrong sample rate, which produces this issues:
        // 1. `AKMicrophone` crashes with input device (microphone with 44.1 kHz sample rate)
        // 2. Playback working, but microphone is not recording (microphone with 48 kHz sample rate)
        // 3. Sample rate in `AKSettings` doesn't match sample rate of current audio session
        // (AudioKit nodes like `AKClipPlayer` couldn't start)

        // WARNING: DO NOT change sample rate anywhere else
        // TODO: test changing input device

        // Code below will choose and set correct sample rate for current audio session and AudioKit settings
        // As a result, at playback/recording time AudioKit's engine will contain nodes with the same sample rates
        // Use `AudioKit.printConnections()` to debug sample rate issues

        let audioSession = AVAudioSession.sharedInstance()
        let oldSampleRate = audioSession.sampleRate
        do {
            // 1. Try to use 48 kHz sample rate as default
            try audioSession.setPreferredSampleRate(48_000)
            // Don't forget to update value in audio kit settings,
            // because AudioKit nodes (aka `AKClipPlayer`) doesn't use sample rate from audio session
            AKSettings.sampleRate = 48_000

            let newSampleRate = audioSession.sampleRate

            // 2. Compare new audio session sample rate with old value
            // Need to do additional setup, if we updated sample rate of audio session
            if oldSampleRate != newSampleRate {
                // 3. Last check, we have to compare sample rate with input device.
                // For example, microphone, which works only on 44.1 kHz sample rate
                // will not work with audio session with 48 kHz sample rate
                // In this case we have to downgrade sample rate of audio session to 44.1 kHz
                let inputSampleRate = AudioKit.engine.inputNode.outputFormat(forBus: 0).sampleRate
                if newSampleRate != inputSampleRate {
                    try audioSession.setPreferredSampleRate(inputSampleRate)
                    // Again, update sample rate AudioKit settings to have
                    // valid AudioKit nodes later
                    AKSettings.sampleRate = inputSampleRate
                }
            }
        } catch {
            print("Couldn't configure audio sample rate: \(error)")
        }
    }

    // MARK: - Private

    private func configureAudioSessionIfNeeded() throws {
        guard !isAudioSessionConfigured else {
            return
        }

        try AKSettings.setSession(category: .playAndRecord, with: [
            .allowBluetoothA2DP,
            .defaultToSpeaker,
            .allowBluetooth,
            .mixWithOthers
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionInterrupted),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        isAudioSessionConfigured = true
    }

    private func configureAudioEngineIfNeeded() {
        guard !isAudioEngineConfigured else {
            return
        }
        AudioKit.engine.isAutoShutdownEnabled = false
        isAudioEngineConfigured = true
    }

    private func setAudioSessionActive(_ isActive: Bool) throws {
        try configureAudioSessionIfNeeded()
        try AKSettings.session.setActive(isActive, options: .notifyOthersOnDeactivation)
        isAudioSessionActive = isActive
    }

    private func setupAudioKitSettings() {
        AKSettings.playbackWhileMuted = true
        AKSettings.bufferLength = .medium
        AKSettings.useBluetooth = true
        AKSettings.allowAirPlay = true
        AKSettings.defaultToSpeaker = true
        AKSettings.audioInputEnabled = true
    }

    // MARK: - Notifications

    @objc private func audioSessionInterrupted() {
        isAudioSessionActive = false
    }
}
