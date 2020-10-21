//
//  AudioPlaybackService.swift
//  
//
//  Created by Andrey Dubenkov on 25/08/2019.
//  Copyright © 2019 . All rights reserved.
//

import AVFoundation

protocol AudioPlaybackServiceOutput: class {
    func audioPlaybackServiceDidFinishPlayback(_ service: AudioPlaybackServiceProtocol)
}

/// AudioPlaybackService provides easy way to play audio using URL using AVAudioPlayer
/// like it implemented for Library screen, but for new architecture
final class AudioPlaybackService: NSObject, AudioPlaybackServiceProtocol {

    weak var output: AudioPlaybackServiceOutput?

    private let audioSessionService: AudioSessionServiceProtocol
    private var audioPlayer: AVAudioPlayer?

    init(audioSessionService: AudioSessionServiceProtocol) {
        self.audioSessionService = audioSessionService
        super.init()
    }

    func startPlaybackSession(withAudioFileURL audioFileURL: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
        audioPlayer?.delegate = self
    }

    func finishPlaybackSession() {
        audioPlayer = nil
    }

    func play() throws {
        try audioSessionService.startAudioSession()
        audioPlayer?.play()
    }

    func stop() {
        audioPlayer?.stop()
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackService: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        player.stop()
        output?.audioPlaybackServiceDidFinishPlayback(self)
    }
}
