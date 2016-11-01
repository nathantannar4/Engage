//
//  Utilities.swift
//  Engage
//
//  Created by Nathan Tannar on 9/30/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import Foundation
import UIKit
import Former

class Utilities {
    
    class func userLoggedIn(_ target: AnyObject) {
        PushNotication.parsePushUserAssign()
        let navVC = UINavigationController(rootViewController: EngagementsViewController())
        target.present(navVC, animated: false, completion: nil)
    }
    
    class func showEngagement(_ target: AnyObject) {
        PushNotication.parsePushUserAssign()
        /*
        let appToolbarController = AppToolbarController(rootViewController: FeedViewController())
        let leftViewController = MenuController()
            //AppPageTabBarController(viewControllers: [RedViewController(), BlueViewController()], selectedIndex: 1)
        let rightViewController = RightViewController()
        
        let baseVC = AppNavigationDrawerController(rootViewController: AppMenuController(rootViewController:appToolbarController), leftViewController: leftViewController, rightViewController: rightViewController)
        */
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let containerVC = storyboard.instantiateViewController(withIdentifier: "menuVC") as! SWRevealViewController
        containerVC.view.backgroundColor = MAIN_COLOR
        target.present(containerVC, animated: false, completion: nil)
    }
    
    class func showBanner(title: String, subtitle: String, duration: Double) {
        let banner = Banner(title: title, subtitle: subtitle, image: nil, backgroundColor: MAIN_COLOR!)
        banner.dismissesOnTap = true
        banner.show(duration: duration)
    }
    
    class func postNotification(_ notification: String) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notification), object: nil)
    }
    
    class func timeElapsed(seconds: TimeInterval) -> String {
        var elapsed: String
        if seconds < 60 {
            elapsed = "Just now"
        }
        else if seconds < 60 * 60 {
            let minutes = Int(seconds / 60)
            let suffix = (minutes > 1) ? "mins" : "min"
            elapsed = "\(minutes) \(suffix) ago"
        }
        else if seconds < 24 * 60 * 60 {
            let hours = Int(seconds / (60 * 60))
            let suffix = (hours > 1) ? "hours" : "hour"
            elapsed = "\(hours) \(suffix) ago"
        }
        else {
            let days = Int(seconds / (24 * 60 * 60))
            let suffix = (days > 1) ? "days" : "day"
            elapsed = "\(days) \(suffix) ago"
        }
        return elapsed
    }
    
    class func dateToString(time: NSDate) -> String {
        var interval = NSDate().minutes(after: time as Date!)
        if interval < 60 {
            if interval <= 1 {
                return "Just Now"
            }
            else {
                return "\(interval) minutes ago"
            }
        }
        else {
            interval = NSDate().hours(after: time as Date!)
            if interval < 24 {
                if interval <= 1 {
                    return "1 hour ago"
                }
                else {
                    return "\(interval) hours ago"
                }
            }
            else {
                interval = NSDate().days(after: time as Date!)
                if interval <= 1 {
                    return "1 day ago"
                }
                else {
                    return "\(interval) days ago"
                }
            }
        }
    }
}

