//
//  CashService.swift
//  
//
//  Created by Andrey Dubenkov on 11/05/2018.
//  Copyright © 2018 . All rights reserved.
//

import Foundation
import AudioKit
import FileKit

protocol HasCacheService {
    var cacheService: CacheServiceProtocol { get }
}

protocol CacheServiceProtocol {
    func saveTemporaryAudioFile(with fileURL: URL, mediaID: Int) -> Result<LocalFile, Error>
    func getAudioFile(forMediaWithID: Int, completion: @escaping (Result<AKAudioFile, Error>) -> Void)
}

final class CacheService: CacheServiceProtocol {
    private enum Constants {
        static let recordsDirectoryName: String = "recordsTmp"
        static let mediaDirectoryName: String = "media"
    }

    static let sharedInstance = CacheService()

    private lazy var dataManager: RealmService = .sharedInstance
    private lazy var fileManager: FileOperationManager = .sharedInstance

    var downloadingMedia: Media?
    var downloadEndHandler: ((String?) -> Void)?
    var downloadedFilePath: String? {
        didSet {
            guard let handler = downloadEndHandler else {
                return
            }
            handler(downloadedFilePath)
        }
    }

    private init() {}

    func getAudioFile(forMediaWithID mediaID: Int, completion: @escaping (Result<AKAudioFile, Error>) -> Void) {
        guard let media = self.dataManager.getMedia(id: mediaID) else {
            completion(.failure(CacheServiceError.mediaNotFound))
            return
        }

        guard downloadingMedia != media else {
            waitForDownloadedAudioFile(for: media, completion: completion)
            return
        }

        if media.isDownloaded {
            getAudioFile(for: media, completion: completion)
         } else {
            downloadAudioFile(for: media, completion: completion)
        }
    }

    private func getAudioFile(for media: Media, completion: @escaping (Result<AKAudioFile, Error>) -> Void) {
        guard let filePath = media.localUrl else {
            DispatchQueue.main.async {
                completion(.failure(CacheServiceError.invalidMediaFile))
            }
            return
        }
        #if DEBUG
        print("Opening local file: \(filePath)")
        #endif
        completeFileOpen(media: media, path: filePath, completion: completion)
    }

    private func waitForDownloadedAudioFile(for media: Media, completion: @escaping (Result<AKAudioFile, Error>) -> Void) {
        downloadEndHandler = { [weak self] path in
            guard let self = self else {
                return
            }
            guard self.downloadingMedia != nil,
                  let path = path else {
                return
            }

            self.completeFileOpen(media: media, path: path) { [weak self] result in
                guard let self = self else {
                    return
                }
                self.downloadEndHandler = nil
                completion(result)
            }
        }
    }

    private func completeFileOpen(media: Media,
                                  path: String,
                                  isDownloading: Bool = false,
                                  completion: @escaping (Result<AKAudioFile, Error>) -> Void) {

        self.openFile(atPath: path, mediaID: media.id) { [weak self] result in
            guard let self = self else {
                return
            }

            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let audioFile):
                    try? self.updateLocalFilePath(forMediaWithID: media.id, fileURL: audioFile.url)
                    guard let localPath = media.localFile?.localUrl else {
                        completion(.failure(CacheServiceError.localPathInvalid))
                        return
                    }
                    if isDownloading {
                        self.downloadedFilePath = localPath
                        self.downloadingMedia = nil
                    }
                    completion(.success(audioFile))
                }
            }
        }
    }

    private func downloadAudioFile(for media: Media, completion: @escaping (Result<AKAudioFile, Error>) -> Void) {
        guard media.url != nil else {
            DispatchQueue.main.async {
                completion(.failure(CacheServiceError.invalidMediaFileURL))
            }
            return
        }

        guard let mediaStringURL = media.url else {
            DispatchQueue.main.async {
                completion(.failure(CacheServiceError.invalidMediaFile))
            }
            return
        }

        downloadingMedia = media
        #if DEBUG
        print("Downloading file: \(mediaStringURL)")
        #endif
        fileManager.downloadFile(media: media, onSuccess: { [weak self] path in
            guard let self = self else {
                return
            }
            let documentsUrl = Path.userDocuments
            let finalPath = documentsUrl + path
            guard finalPath.exists else {
                self.downloadingMedia = nil
                if let localFile = media.localFile {
                    RealmService.sharedInstance.delete(localFileID: localFile.id)
                }
                DispatchQueue.main.async {
                    completion(.failure(CacheServiceError.mediaDownloadingFailed))
                }
                return
            }
            #if DEBUG
            print("Opening local file: \(mediaStringURL)")
            #endif
            self.completeFileOpen(media: media, path: path, isDownloading: true, completion: completion)
        }, onFail: { _ in
            self.downloadingMedia = nil
            DispatchQueue.main.async {
                completion(.failure(CacheServiceError.mediaDownloadingFailed))
            }
        })
    }

    func saveToMediaAudioFile(with fileURL: URL, mediaID: Int) -> Result<LocalFile, Error> {
        return fileManager.moveTemporaryFileToDocumentsDirectory(
            temporaryFileURL: fileURL,
            mediaID: mediaID,
            subDirectoryName: Constants.mediaDirectoryName
        )
    }

    func copyTemporaryAudioFile(with fileURL: URL, mediaID: Int) -> Result<LocalFile, Error> {
        return fileManager.copyTemporaryFileToDocumentsDirectory(
            temporaryFileURL: fileURL,
            mediaID: mediaID,
            subDirectoryName: Constants.mediaDirectoryName
        )
    }

    func saveTemporaryAudioFile(with fileURL: URL, mediaID: Int) -> Result<LocalFile, Error> {
        return fileManager.moveTemporaryFileToDocumentsDirectory(
            temporaryFileURL: fileURL,
            mediaID: mediaID,
            subDirectoryName: Constants.recordsDirectoryName
        )
    }

    private func openFile(atPath filePath: String,
                          mediaID: Int,
                          completion: @escaping (Result<AKAudioFile, Error>) -> Void) {
        let documentsPath = Path.userDocuments
        let finalPath = documentsPath + filePath
        guard finalPath.exists else {
            #if DEBUG
            print("NOT EXISTING PATH")
            print("_________________")
            print("\(finalPath)")
            print("_________________")
            #endif
            guard let media = RealmService.sharedInstance.getMedia(id: mediaID) else {
                completion(.failure(CacheServiceError.mediaNotFound))
                return
            }

            if let localFile = media.localFile {
                RealmService.sharedInstance.delete(localFileID: localFile.id)
            }
            completion(.failure(CacheServiceError.localPathInvalid))
            return
        }

        let fileURL = finalPath.url
        let audioFile: AKAudioFile
        do {
            audioFile = try AKAudioFile(forReading: fileURL)
        } catch {
            print("Unable to open local file: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        #if DEBUG
        print("Starting file conversion: \(filePath)")
        #endif
        convertAudioFile(audioFile) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .failure(let error):
                print("Unable to convert audio file: \(error.localizedDescription)")
                guard let media = RealmService.sharedInstance.getMedia(id: mediaID) else {
                    return
                }
                if let localFile = media.localFile {
                    RealmService.sharedInstance.delete(localFileID: localFile.id)
                }
                completion(.failure(error))
            case .conversionNotRequired:
                completion(.success(audioFile))
            case .fileConverted(let convertedFileURL):
                do {
                    // Update local file since audio file changed after conversion
                    try self.updateLocalFilePath(forMediaWithID: mediaID, fileURL: convertedFileURL)
                    let convertedAudioFile = try AKAudioFile(forReading: convertedFileURL)
                    print("File converted: sample rate\(convertedAudioFile.sampleRate)")
                    completion(.success(convertedAudioFile))
                } catch {
                    print("Unable to convert audio file: \(error.localizedDescription)")
                    completion(.failure(CacheServiceError.conversionError))
                }
            }
        }
    }

    private func updateLocalFilePath(forMediaWithID mediaID: Int, fileURL: URL) throws {
        guard let media = dataManager.getMedia(id: mediaID) else {
            throw CacheServiceError.mediaNotFound
        }

        guard let localFile = media.localFile else {
            throw CacheServiceError.invalidMediaFile
        }

        let realm = dataManager.makeDefaultRealm()
        realm.beginWrite()
        localFile.localUrl = "media/\(fileURL.lastPathComponent)"
        try realm.commitWrite()
    }

    private func convertAudioFile(_ audioFile: AKAudioFile,
                                  completion: @escaping (AudioFileConversionResult) -> Void) {
        let fileURL = audioFile.url
        #warning("File CONVERSION SAMPLE RATE")
        // Always use sample rate of our input device
        let currentSampleRate = audioFile.sampleRate
//        let currentSampleRate = AudioKit.engine.inputNode.outputFormat(forBus: 0).sampleRate
        let fileSampleRate = audioFile.sampleRate
        if fileSampleRate == currentSampleRate, fileURL.pathExtension == "m4a" {
            completion(.conversionNotRequired)
            return
        }
        let outputFileURLString = fileURL.deletingPathExtension().absoluteString + "-converted"
        let m4aFileUrl = fileURL.deletingPathExtension().appendingPathExtension("m4a")
        guard var outputFileURL = URL(string: outputFileURLString) else {
            completion(.failure(CacheServiceError.conversionError))
            return
        }
        outputFileURL = outputFileURL.appendingPathExtension("m4a")
        var options = AudioConverterOptions(inputFileURL: fileURL, outputFileURL: outputFileURL)
        options.sampleRate = currentSampleRate
        let converter = AudioConverter(audioSessionService: ServiceContainer().audioSessionService, options: options)
        converter.start { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success:
                    FileOperationManager.sharedInstance.deleteFile(url: fileURL.absoluteString)
                    FileOperationManager.sharedInstance.moveFile(url: outputFileURL, toPath: m4aFileUrl)
                    completion(.fileConverted(m4aFileUrl))
                }
            }
        }
    }
}

private enum AudioFileConversionResult {
    case failure(Error)
    case conversionNotRequired
    case fileConverted(URL)
}

private enum CacheServiceError: Equatable {
    case mediaNotFound
    case invalidMediaFile
    case mediaDownloadingFailed
    case invalidMediaFileURL
    case localPathInvalid
    case conversionError
}

extension CacheServiceError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .mediaNotFound:
            return "Media not found"
        case .localPathInvalid:
            return "Path doesn't exists"
        case .invalidMediaFile:
            return "Invalid media file"
        case .mediaDownloadingFailed:
            return "Media downloading failed"
        case .invalidMediaFileURL:
            return "Media file contains invalid URL"
        case .conversionError:
            return "Sample Rate conversion error"
        }
    }
}
