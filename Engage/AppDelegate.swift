//
//  AppDelegate.swift
//  Engage
//
//  Created by Nathan Tannar on 9/29/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import Parse
import UserNotifications
import Material
import ParseFacebookUtilsV4
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
 

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let config = ParseClientConfiguration(block: { (ParseMutableClientConfiguration) -> Void in
            ParseMutableClientConfiguration.applicationId = APPLICATION_ID
            ParseMutableClientConfiguration.clientKey = CLIENT_KEY
            ParseMutableClientConfiguration.server = SERVER_URL
        });
        Parse.initialize(with: config) 
        FBSDKSettings.setAppID(FACEBOOK_APPLICATION_ID)
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)
        PFUser.enableRevocableSessionInBackground()
        
        if isWESST {
            MAIN_COLOR = UIColor(red: 153.0/255, green:62.0/255.0, blue:123.0/255, alpha: 1) as UIColor!
        }
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        // Change navbar color
        let navbar = UINavigationBar.appearance()
        navbar.barTintColor = MAIN_COLOR
        navbar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName: MAIN_FONT_TITLE]
        navbar.tintColor = UIColor.white
        navbar.isTranslucent = false
        
        // Remove back button text from navbar
        let barAppearace = UIBarButtonItem.appearance()
        barAppearace.setBackButtonTitlePositionAdjustment(UIOffsetMake(0, -60), for:UIBarMetrics.default)
        
        // Remove shadow from navigation bar
        navbar.shadowImage = UIImage()
        navbar.setBackgroundImage(UIImage(), for: .default)

        
        // Register for push notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization.
        }
        application.registerForRemoteNotifications()
 
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Mark - Push Notification methods
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let installation = PFInstallation.current()
        installation?.setDeviceTokenFrom(deviceToken as Data)
        installation?.saveInBackground()
        print("Registered for Push Notifications")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for Push Notifications")
    }
    
    internal func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        if let data = userInfo["aps"] {
            let notificationMessage = (data as AnyObject).value(forKey: "alert") as? String
            if  notificationMessage != nil {
                print("Recieved Remote Notification: \(notificationMessage!)")
                let currentBadgeNumber: Int = UIApplication.shared.applicationIconBadgeNumber
                UIApplication.shared.applicationIconBadgeNumber = currentBadgeNumber + 1
                Utilities.showBanner(title: notificationMessage!, subtitle: "", duration: 2.0)
            } else {
                print("Notification was nil")
            }
        } else {
            print("Data was nil")
        }
    }
    
    // MARK: - Facebook Login
    func application(_ application: UIApplication,
                     open url: URL,
                     sourceApplication: String?,
                     annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application,
                                                                     open: url,
                                                                     sourceApplication: sourceApplication,
                                                                     annotation: annotation)
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

