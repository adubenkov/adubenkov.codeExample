//
//  AudioPlaybackServiceProtocol.swift
//  
//
//  Created by Andrey Dubenkov on 25/08/2019.
//  Copyright © 2019 . All rights reserved.
//

protocol HasAudioPlaybackService {
    var audioPlaybackService: AudioPlaybackServiceProtocol { get }
}

protocol AudioPlaybackServiceProtocol: class {

    var output: AudioPlaybackServiceOutput? { get set }

    func startPlaybackSession(withAudioFileURL audioFileURL: URL) throws
    func finishPlaybackSession()
    func play() throws
    func stop()
}
