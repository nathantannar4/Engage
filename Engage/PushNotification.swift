//
//  PushNotification.swift
//  Engage
//
//  Created by Nathan Tannar on 9/30/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import Foundation
import Parse

class PushNotication {
    
    class func parsePushUserAssign() {
        let installation = PFInstallation.current()!
        installation[PF_INSTALLATION_USER] = PFUser.current()
        installation.saveInBackground(block: { (success, error) in
            if error != nil {
                print("parsePushUserAssign save error.")
            }
        })
    }
    
    class func parsePushUserResign() {
        let installation = PFInstallation.current()!
        installation.remove(forKey: PF_INSTALLATION_USER)
        installation.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
            if error != nil {
                print("parsePushUserResign save error")
            }
        }
    }
    
    class func sendPushNotificationMessage(_ groupId: String, text: String) {
        /*
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.stringByReplacingOccurrencesOfString(" ", withString: "_"))_\(PF_MESSAGES_CLASS_NAME)")
        query.whereKey(PF_MESSAGES_GROUPID, equalTo: groupId)
        query.whereKey(PF_MESSAGES_USER, notEqualTo: PFUser.currentUser()!)
        query.includeKey(PF_MESSAGES_USER)
        query.limit = 1000
        
        let installationQuery = PFInstallation.query()
        installationQuery!.whereKey(PF_INSTALLATION_USER, matchesKey: PF_MESSAGES_USER, inQuery: query)
        
        let push = PFPush()
        push.setQuery(installationQuery)
        push.setMessage(text)
        push.sendPushInBackgroundWithBlock { (succeeded: Bool, error: NSError?) -> Void in
            if error != nil {
                print("sendPushNotification error")
            } else {
                print("Push Sent")
            }
        }
         */
    }
}
