//
//  SceneDelegate.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/19/22.
//

import UIKit
#if !DEBUG
import AuthenticationServices
#endif

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var windowScene: UIWindowScene?
    
    var userID: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: "userID")
        }
        get {
            UserDefaults.standard.string(forKey: "userID")
        }
    }

    func setWeatherScrollViewController(scene: UIWindowScene) {
        let window = UIWindow(windowScene: scene)
        if let weatherViewController = Bundle.main.loadNibNamed("WeatherScrollViewController", owner: nil, options: nil)?.first as? WeatherScrollViewController {
            weatherViewController.databaseID = userID?.replacingOccurrences(of: ".", with: "")
            #if !DEBUG
            weatherViewController.delegate = self
            #endif
            window.rootViewController = weatherViewController
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
#if !DEBUG
    func setSignInViewController(scene: UIWindowScene) {
        let window = UIWindow(windowScene: scene)
        if let signInController = Bundle.main.loadNibNamed("WeatherSignInViewController", owner: nil, options: nil)?.first as? WeatherSignInViewController {
            signInController.signInDelegate = self
            window.rootViewController = signInController
            self.window = window
            window.makeKeyAndVisible()
        }
    }
#endif

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.windowScene = windowScene
        
#if targetEnvironment(simulator) || DEBUG
        userID = "simulator"
        self.setWeatherScrollViewController(scene: windowScene)
#else
        if let userID = userID {
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userID) { state, error in
                if let error = error {
                    NSLog("Couldn't get credential state. \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        if (state == .authorized) {
                            self.setWeatherScrollViewController(scene: windowScene)
                        } else {
                            self.setSignInViewController(scene: windowScene)
                        }
                    }
                }
            }
        } else {
            setSignInViewController(scene: windowScene)
        }
#endif
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

#if !DEBUG
extension SceneDelegate: WeatherAuthenticationDelegate {
    
    func signIn(userID: String) {
        self.userID = userID
        
        if let windowScene = windowScene {
            setWeatherScrollViewController(scene: windowScene)
        }
    }
    
    func signOut() {
        self.userID = nil
        
        if let scene = windowScene {
            self.setSignInViewController(scene: scene)
        }
    }
    
}
#endif
