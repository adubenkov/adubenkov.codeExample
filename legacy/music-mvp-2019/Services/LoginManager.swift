//
//  LoginManager.swift
//  
//
//  Created by Andrey Dubenkov on 23/07/2018.
//  Copyright © 2018 . All rights reserved.
//

import Foundation
import PhoneNumberKit
import SwiftyStoreKit
import Firebase
import FirebaseAuth
import FirebaseUI
import GoogleSignIn

// TODO: rename LoginManager to LoginService

protocol HasLoginService {
    var loginService: LoginServiceProtocol { get }
}

protocol LoginServiceProtocol {
    var userID: Int { get }
}

protocol LoginManagerOutput {
    func loginStarted()
    func loggedIn()
    func loggedOut()
    func loginError(error: String)
    func cleanInput()
}

enum SignInService: Int {
    case empty = 0
    case google = 1
    case apple = 2
}

final class LoginManager: NSObject, LoginServiceProtocol {
    static let sharedInstance = LoginManager()

    var googleAdapter = GoogleSignInAdapter()
    var appleAdapter: AppleSignInAdapter?

    var userID: Int = 0

    private lazy var networkStatusService: NetworkStatusService = .sharedInstance
    private(set) var loggedIn: Bool = false
    private(set) var loginInProgress: Bool = false

    private(set) lazy var delegate: MulticastDelegate<LoginManagerOutput> = .init()

    var signInService: SignInService {
        let typeIndex = UserDefaults.standard.integer(forKey: "accountType")
        return SignInService(rawValue: typeIndex) ?? .empty
    }

    private override init() {
        super.init()
        if #available(iOS 13.0, *) {
            appleAdapter = AppleSignInAdapter()
            appleAdapter?.output = self
        }
        googleAdapter.output = self
    }

    // MARK: Main Login Logic

    func tryToLogIn(completion: ((Result<Bool, Error>) -> Void)? = nil) {
        func requestTokenFromFirebase() {
            googleAdapter.requestToken { [weak self] result in
                switch result {
                case let .success(token):
                    self?.loginWithToken(token, accountType: .google)
                case let .failure(error):
                    self?.delegate.invoke {
                        $0.loggedOut()
                        $0.loginError(error: error.localizedDescription)
                    }
                }
            }
        }
        switch signInService {
        case .empty:
            completion?(.failure(APIError(errorDescription: "No Account stored")))
        case .google:
            requestTokenFromFirebase()
        case .apple:
            requestTokenFromFirebase()
        }
    }

    func registerNewAccount(with adapter: SignInAdapter,
                            email: String,
                            password: String,
                            name: String) {
        adapter.registerNewAccount(with: email, password: password, name: name) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success:
                adapter.requestToken { [weak self] result in
                    switch result {
                    case let .success(token):
                        self?.loginWithToken(token, accountType: .google)
                    case let .failure(error):
                        self?.delegate.invoke {
                            $0.loggedOut()
                            $0.loginError(error: error.localizedDescription)
                        }
                    }
                }
                self.delegate.invoke {
                    $0.loggedIn()
                }
            case let .failure(error):
                self.delegate.invoke {
                    $0.loggedOut()
                    $0.loginError(error: error.localizedDescription)
                }
            }
        }
    }

    private func loginWithToken(_ token: String, accountType: SignInService) {
        func failure(errorMessage: String) {
            logout()
            loggedIn = false
            loginInProgress = false
            delegate.invoke {
                $0.loggedOut()
                $0.loginError(error: errorMessage)
            }
        }

        func success(user: User) {
            UserDefaults.standard.set(accountType.rawValue, forKey: "accountType")
            RealmService.sharedInstance.setDefaultRealmForUser(username: "\(user.id)_\(user.firebaseID)")
            loggedIn = true
            loginInProgress = false
            delegate.invoke {
                $0.loggedIn()
            }
        }

        func handle503() {
            let errorMessage = """
                Login error.
            """
            // Trying to retrieve stored user data
            userID = RealmService.sharedInstance.getUserFromUserDefaults()
            guard let user = RealmService.sharedInstance.getUserBy(id: self.userID) else {
                failure(errorMessage: errorMessage)
                return
            }
            // Setting old token to API Adapter
            guard let token = RealmService.sharedInstance.getTokenFromUserDefaults() else {
                failure(errorMessage: errorMessage)
                return
            }
            Api.sharedInstance.updateToken(token: token)
            success(user: user)
        }

        guard networkStatusService.isReachable else {
            failure(errorMessage: "Please connect to the internet")
            return
        }
        loginInProgress = true
        delegate.invoke {
            $0.loginStarted()
        }

        Api.sharedInstance.login(token: token, onSuccess: { [weak self] response in
            guard let self = self else {
                return
            }

            guard let user = response.user,
                user.subscription != nil else {
                failure(errorMessage: "Can't read user from server")
                return
            }

            NetworkStatusService.sharedInstance.setBackendIsOnline(true)

            self.saveUser(user)
            success(user: user)
        }, onFailed: { error in
            guard error != "503" else {
                let errorMessage = """
                Our server is temporarily unreachable. \
                The app will continue operating in offline mode. Please try again later.
                """
                failure(errorMessage: errorMessage)
                return
            }
            handle503()

        })
    }

    func saveUser(_ user: User) {
        self.userID = user.id

        RealmService.sharedInstance.saveUserToUserDefaults(userID: LoginManager.sharedInstance.userID)
        RealmService.sharedInstance.save(user: user)
    }

    func logout() {
        try? Auth.auth().signOut()
        if let fcmToken = RealmService.sharedInstance.fcmToken {
            if networkStatusService.isReachable {
                Api.sharedInstance.revokeFCMToken(token: fcmToken, onSuccess: { _ in }, onFailed: { _ in })
            }
        }

        GIDSignIn.sharedInstance().signOut()
        RealmService.sharedInstance.clearRealm()
        RealmService.sharedInstance.cleanUserDefaults()
        userID = 0
        loggedIn = false
        delegate.invoke {
            $0.loggedOut()
        }
    }

    // MARK: - Google

    func loginWith(email: String, password: String) {
        googleAdapter.loginWith(email: email, password: password)
    }

    func loginWithPhoneNumber(_ phoneNumber: PhoneNumber, currentVC: UIViewController) {
        googleAdapter.loginWithPhoneNumber(phoneNumber, currentVC: currentVC)
        delegate.invoke { output in
            output.cleanInput()
        }
    }

    // MARK: - Apple

    @available(iOS 13.0, *)
    func loginWithApple() {
        appleAdapter?.startSignInWithAppleFlow()
    }
}

extension LoginManager: SignInAdapterOutput {
    func adapterDidSignedInInOfflineMode(_ adapter: SignInAdapter) {
        UserDefaults.standard.set(adapter.adapterType.rawValue, forKey: "accountType")
        loggedIn = false
        networkStatusService.delegate.addDelegate(delegate: self)
        loginInProgress = false
        delegate.invoke {
            $0.loggedIn()
        }

    }

    func anErrorOccuredDuringSignInProcess(_ adapter: SignInAdapter, error: Error) {
        self.delegate.invoke {
            $0.loggedOut()
            $0.loginError(error: error.localizedDescription)
        }
    }

    func adapterDidSignedIn(_ adapter: SignInAdapter) {
        UserDefaults.standard.set(adapter.adapterType.rawValue, forKey: "accountType")
        self.tryToLogIn()
    }

    func adapterDidRequestedLogout(_ adater: SignInAdapter) {
//        logout()
    }
}

extension LoginManager: NetworkStatusServiceProtocol {
    func networkNotReachable() {
    }

    func networkIsReachable() {
        networkStatusService.delegate.removeDelegate(delegate: self)
        tryToLogIn()
    }
}
