//
//  Messages.swift
//  Engage
//
//  Created by Nathan Tannar on 9/30/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import Foundation
import Parse

class Messages {
    
    class func startPrivateChat(user1: PFUser, user2: PFUser) -> String {
        let id1 = user1.objectId!
        let id2 = user2.objectId!
        
        let groupId = (id1 < id2) ? "\(id1)\(id2)" : "\(id2)\(id1)"
        
        createMessageItem(user: user1, groupId: groupId, description: user2[PF_USER_FULLNAME] as! String)
        createMessageItem(user: user2, groupId: groupId, description: user1[PF_USER_FULLNAME] as! String)
        
        return groupId
    }

    class func startMultipleChat(users: [PFUser]!) -> String {
        var groupId = ""
        let description = "Group Chat"
        
        var userIds = [String]()
        
        for user in users {
            userIds.append(user.objectId!)
        }
        
        for userId in userIds {
            groupId = groupId + userId
        }
        
        for user in users {
            Messages.createMessageItem(user: user, groupId: groupId, description: description)
        }
        
        return groupId
    }
    
    class func createMessageItem(user: PFUser, groupId: String, description: String) {
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_MESSAGES_CLASS_NAME)")
        query.whereKey(PF_MESSAGES_USER, equalTo: user)
        query.whereKey(PF_MESSAGES_GROUPID, equalTo: groupId)
        query.findObjectsInBackground {(objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if objects!.count == 0 {
                    let message = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_MESSAGES_CLASS_NAME)")
                    message[PF_MESSAGES_USER] = user;
                    message[PF_MESSAGES_GROUPID] = groupId;
                    message[PF_MESSAGES_DESCRIPTION] = description;
                    message[PF_MESSAGES_LASTUSER] = PFUser.current()
                    message[PF_MESSAGES_LASTMESSAGE] = "Send the first message!";
                    message[PF_MESSAGES_COUNTER] = 0
                    message[PF_MESSAGES_UPDATEDACTION] = NSDate()
                    message.saveInBackground(block: { (succeeded: Bool, error:
                        Error?) -> Void in
                        if (error != nil) {
                            print("Messages.createMessageItem save error.")
                            print(error)
                        }
                    })
                }
            } else {
                print("Messages.createMessageItem save error.")
                print(error)
            }
        }
    }
    
    class func deleteMessageItem(message: PFObject) {
        message.deleteInBackground { (succeeded: Bool, error: Error?) -> Void in
            if error != nil {
                print("UpdateMessageCounter save error.")
                print(error)
            }
        }
    }
    
    class func updateMessageCounter(groupId: String, lastMessage: String) {
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_MESSAGES_CLASS_NAME)")
        query.whereKey(PF_MESSAGES_GROUPID, equalTo: groupId)
        query.limit = 1000
        query.findObjectsInBackground {(objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                for message in objects as [PFObject]! {
                    let user = message[PF_MESSAGES_USER] as! PFUser
                    if user.objectId != PFUser.current()!.objectId {
                        message.incrementKey(PF_MESSAGES_COUNTER) // Increment by 1
                        message[PF_MESSAGES_LASTUSER] = PFUser.current()
                        message[PF_MESSAGES_LASTMESSAGE] = lastMessage
                        message[PF_MESSAGES_UPDATEDACTION] = NSDate()
                        message.saveInBackground(block: { (succeeded: Bool, error: Error?) -> Void in
                            if error != nil {
                                print("UpdateMessageCounter save error.")
                                print(error)
                            }
                        })
                    } else {
                        message[PF_MESSAGES_LASTMESSAGE] = lastMessage
                        message[PF_MESSAGES_UPDATEDACTION] = NSDate()
                        message.saveInBackground(block: { (succeeded: Bool, error:
                            Error?) -> Void in
                            if error != nil {
                                print("UpdateMessageCounter save error.")
                                print(error)
                            }
                        })
                    }
                }
            } else {
                print("UpdateMessageCounter save error.")
                print(error)
            }
        }
    }
    
    class func clearMessageCounter(groupId: String) {
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_MESSAGES_CLASS_NAME)")
        query.whereKey(PF_MESSAGES_GROUPID, equalTo: groupId)
        query.whereKey(PF_MESSAGES_USER, equalTo: PFUser.current()!)
        query.findObjectsInBackground {(objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                for message in objects as [PFObject]! {
                    message[PF_MESSAGES_COUNTER] = 0
                    message.saveInBackground(block: { (succeeded: Bool, error: Error?) -> Void in
                        if error != nil {
                            print("ClearMessageCounter save error.")
                            print(error)
                        }
                    })
                }
            } else {
                print("ClearMessageCounter save error.")
                print(error)
            }
        }
    }

}
