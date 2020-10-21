//
//  SequenceSaver.swift
//   Dev
//
//  Created by Andrey Dubenkov on 30.10.2019.
//  Copyright © 2019 . All rights reserved.
//

import Foundation
import AudioKit

protocol SequenceSaverDelegate: class {
    func sequenceCanUndo(_ can: Bool)
}

final class SequenceSaver {
    var delegate: SequenceSaverDelegate?
    private var sequences: [AKFileClipSequence] = [] {
        didSet {
            delegate?.sequenceCanUndo(sequences.count > 1)
        }
    }

    func addState(_ sequence: AKFileClipSequence) {
        sequences.append(sequence)
    }

    func removeState() {
        guard sequences.count > 1 else {
            return
        }
        sequences.removeLast()
    }

    func removeAll() {
        sequences.removeAll()
    }

    func clearRecordedFiles() {
        if let currentClips = sequences.last?.clips {
            for clip in currentClips {
                guard let localFile = clip.audioFile.localFile else { continue }
                RealmService.sharedInstance.delete(localFileID: localFile.id)
            }
            removeAll()
        }
    }

    func getCurrentState() -> AKFileClipSequence {
        guard let last = sequences.last else {
            return AKFileClipSequence(clips: [])
        }
        return last
    }

    func getLastAddedClip() -> AKFileClip? {
        let lastSequence = getCurrentState()
        guard let previousSequence = sequences.after(lastSequence) else {
            return nil
        }
        return lastSequence.clips.equality(from: previousSequence.clips).first
    }

    func duration() -> Double {
        var duration = 0.0
        if let currentClips = sequences.last?.clips {
            for clip in currentClips {
                duration += clip.duration
            }
        }
        return duration
    }
}
