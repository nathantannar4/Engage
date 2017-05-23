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
        
        Color.Default.setPrimary(to: .white)
        Color.Default.setSecondary(to: UIColor(hex: "#31485e"))
        
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
        window?.backgroundColor = .white

        //let dataSet = NTSlideDataSet(image: #imageLiteral(resourceName: "Engage_Logo"), title: "Engage", subtitle: "Create your own Social Network!", body: nil)
        //let root = NTSlideShowViewController(dataSource: NTSlideShowDatasource(withValues: [dataSet]))
        //root.completionViewController = LoginViewController()
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        
        if PFUser.current() != nil {
            PFUser.current()?.fetchInBackground(block: { (object, error) in
                guard let user = object as? PFUser else {
                    return
                }
                User(user).login()
            })
        } else {
            LoginViewController().makeKeyAndVisible()
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

