//
//  AppDelegate.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2020/11/26.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//        if let error = error {
//            print(error)
//            return
//        }
//        guard let authentication = user.authentication else {return}
//        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
//        Auth.auth().signIn(with: credential) { (user, error) in
//            if let error = error {
//                print(error)
//                return
//            }
//        }
//    }
    

var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        IQKeyboardManager.shared.enable = true

        //GIDSignIn.sharedInstance().delegate = self
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // singleton 帶出來的值一定不會是nil 因為singleton 記憶體一直存在
        return GIDSignIn.sharedInstance().handle(url)
    }

}

