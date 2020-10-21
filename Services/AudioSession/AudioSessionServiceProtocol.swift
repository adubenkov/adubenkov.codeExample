//
//  AudioSessionServiceProtocol.swift
//  
//
//  Created by Andrey Dubenkov on 06/06/2019.
//  Copyright © 2019 . All rights reserved.
//

import AudioKit

protocol HasAudioSessionService {
    var audioSessionService: AudioSessionServiceProtocol { get }
}

protocol AudioSessionServiceProtocol: class {

    var audioOutput: AKNode? { get set }

    func configureAudioSampleRate()

    func startAudioEngine() throws
    func stopAudioEngine() throws
    func startAudioSession() throws
    func stopAudioSession() throws
}
