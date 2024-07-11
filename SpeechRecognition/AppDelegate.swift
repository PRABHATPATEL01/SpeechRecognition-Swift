//
//  AppDelegate.swift
//  SpeechRecognition
//
//  Created by Prabhat Mishra on 20/01/24.
//

import UIKit
import NotificationCenter

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        {(accepted, error) in
            
            if !accepted {
                print("Notification access denied")
            }
        }
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
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Replace "Main" with the name of your storyboard
            let destinationViewController = storyboard.instantiateViewController(withIdentifier: "dest") // Replace "YourDestinationViewControllerIdentifier" with the identifier of your destination view controller
            
            // Access the window and root view controller to perform the navigation
            if let window = UIApplication.shared.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(destinationViewController, animated: true, completion: nil)
            }
            
            completionHandler()
       
    }


}

