//
//  Services.swift
//  
//
//  Created by Andrey Dubenkov on 06/06/2019.
//  Copyright © 2019 . All rights reserved.
//

typealias HasServices = HasRealmService &
                        HasLoginService &
                        HasReachabilityService &
                        HasSyncService &
                        HasApiService &
                        HasCacheService &
                        HasStoreService &
                        HasAudioSessionService &
                        HasAudioPlaybackService &
                        HasRecordHubAudioServiceService &
                        HasAnalyticsService

private typealias HasPersistentServices = HasRealmService &
                                          HasLoginService &
                                          HasReachabilityService &
                                          HasSyncService &
                                          HasApiService &
                                          HasCacheService &
                                          HasStoreService &
                                          HasAudioSessionService

/// Service container only for persistent services (singletons)
private final class PersistentServiceContainer: HasPersistentServices {

    static var instance: PersistentServiceContainer = .init()

    lazy var realmService: RealmServiceProtocol = RealmService.sharedInstance
    lazy var loginService: LoginServiceProtocol = LoginManager.sharedInstance
    lazy var reachabilityService: ReachabilityServiceProtocol = NetworkStatusService.sharedInstance
    lazy var syncService: SyncServiceProtocol = SyncService.sharedInstance
    lazy var apiService: ApiServiceProtocol = Api.sharedInstance
    lazy var cacheService: CacheServiceProtocol = CacheService.sharedInstance
    lazy var storeService: StoreServiceProtocol = StoreService.sharedInstance
    lazy var audioSessionService: AudioSessionServiceProtocol = AudioSessionService()

    private init() {}
}

/// Main service container
final class ServiceContainer: HasServices {

    var realmService: RealmServiceProtocol {
        return PersistentServiceContainer.instance.realmService
    }

    var loginService: LoginServiceProtocol {
        return PersistentServiceContainer.instance.loginService
    }

    var reachabilityService: ReachabilityServiceProtocol {
        return PersistentServiceContainer.instance.reachabilityService
    }

    var syncService: SyncServiceProtocol {
        return PersistentServiceContainer.instance.syncService
    }

    var apiService: ApiServiceProtocol {
        return PersistentServiceContainer.instance.apiService
    }

    var cacheService: CacheServiceProtocol {
        return PersistentServiceContainer.instance.cacheService
    }

    var storeService: StoreServiceProtocol {
        return PersistentServiceContainer.instance.storeService
    }

    var audioSessionService: AudioSessionServiceProtocol {
        return PersistentServiceContainer.instance.audioSessionService
    }

    lazy var audioPlaybackService: AudioPlaybackServiceProtocol = {
        return AudioPlaybackService(audioSessionService: audioSessionService)
    }()

    lazy var recordHubAudioServiceService: RecordHubAudioServiceServiceProtocol = {
        return RecordHubAudioService(audioSessionService: audioSessionService)
    }()

    lazy var analyticsService: AnalyticsServiceProtocol = {
        return AnalyticsService()
    }()
}
