//
//  AppDelegate.swift
//  Engage
//
//  Created by Nathan Tannar on 5/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents
import Parse
import UserNotifications
import ParseFacebookUtilsV4
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Color.Default.setPrimary(to: UIColor(hex: "31485e"))
        Color.Default.setSecondary(to: .white)
        Color.Default.setTertiary(to: UIColor(hex: "baa57b"))
        Color.Default.Tint.Toolbar = UIColor(hex: "31485e")
        
        Font.Default.Title = Font.Roboto.Medium.withSize(15)
        Font.Default.Subtitle = Font.Roboto.Regular
        Font.Default.Body = Font.Roboto.Regular.withSize(13)
        Font.Default.Caption = Font.Roboto.Medium.withSize(12)
        Font.Default.Subhead = Font.Roboto.Regular.withSize(14)
        Font.Default.Headline = Font.Roboto.Medium.withSize(15)
        Font.Default.Callout = Font.Roboto.Medium.withSize(15)
        Font.Default.Footnote = Font.Roboto.Regular.withSize(12)
        
        let config = ParseClientConfiguration(block: { (ParseMutableClientConfiguration) -> Void in
            ParseMutableClientConfiguration.applicationId = APPLICATION_ID
            ParseMutableClientConfiguration.clientKey = CLIENT_KEY
            ParseMutableClientConfiguration.server = SERVER_URL
        });
        Parse.enableLocalDatastore()
        Parse.initialize(with: config)
        Parse.setLogLevel(.debug)
        PFUser.enableRevocableSessionInBackground()
        
        
        // Register for Push Notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
        }
        application.registerForRemoteNotifications()
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor(hex: "31485e")
        window?.rootViewController = NTNavigationController(rootViewController: LoginViewController())
        window?.rootViewController?.view.isHidden = true
        window?.makeKeyAndVisible()
        
        if PFUser.current() != nil {
             User(PFUser.current()!).login()
        } else {
            window?.rootViewController?.view.isHidden = false
        }
        
        
        FBSDKSettings.setAppID(FACEBOOK_APPLICATION_ID)
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - FacebookSDK
    
    func applicationDidBecomeActive(application: UIApplication!) {
        FBSDKAppEvents.activateApp()
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
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

