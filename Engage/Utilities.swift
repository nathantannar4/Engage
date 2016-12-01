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
import BRYXBanner
import DrawerController
import Material
import Parse

class Utilities {
    
    class func userLoggedIn(_ target: AnyObject) {
        PushNotication.parsePushUserAssign()
        let navVC = UINavigationController(rootViewController: EngagementsViewController())
        target.present(navVC, animated: false, completion: nil)
    }
    
    class func showEngagement(_ target: AnyObject, animated: Bool) {
        PushNotication.parsePushUserAssign()
        
        let navigationController = UINavigationController(rootViewController: FeedViewController())
        navigationController.navigationBar.barTintColor = MAIN_COLOR
        navigationController.restorationIdentifier = "NavigationControllerRestorationKey"
        
        drawerController = DrawerController(centerViewController: navigationController, leftDrawerViewController: EngagementMenuController(), rightDrawerViewController: AnnouncementsViewController())
        
        drawerController.restorationIdentifier = "Drawer"
        drawerController.showsShadows = true
        drawerController.shouldStretchDrawer = false
        drawerController.maximumLeftDrawerWidth = 200.0
        drawerController.maximumRightDrawerWidth = 280.0
        drawerController.openDrawerGestureModeMask = .all
        drawerController.closeDrawerGestureModeMask = .all
        
        drawerController.drawerVisualStateBlock = { (drawerController, drawerSide, percentVisible) in
            let block = ExampleDrawerVisualStateManager.sharedManager.drawerVisualStateBlock(for: drawerSide)
            block?(drawerController, drawerSide, percentVisible)
        }        
        target.present(drawerController, animated: animated, completion: nil)
    }
    
    class func showBanner(title: String, subtitle: String, duration: Double) {
        let banner = Banner(title: title, subtitle: subtitle, image: nil, backgroundColor: MAIN_COLOR!)
        banner.dismissesOnTap = true
        banner.show(duration: duration)
    }
    
    class func postNotification(_ notification: String) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notification), object: nil)
    }
    
    class func setTitle(title:String, subtitle:String) -> UIView {
        let titleLabel = UILabel(frame: CGRect(x: 0, y: -2, width: 0, height: 0))
        
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.white
        titleLabel.font = RobotoFont.medium(with: 17)
        titleLabel.text = title
        titleLabel.sizeToFit()
        
        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = UIColor.white
        subtitleLabel.font = RobotoFont.regular(with: 12)
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), height: 30))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        let widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width
        
        if widthDiff < 0 {
            let newX = widthDiff / 2
            subtitleLabel.frame.origin.x = abs(newX)
        } else {
            let newX = widthDiff / 2
            titleLabel.frame.origin.x = newX
        }
        
        return titleView
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

