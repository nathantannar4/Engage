//
//  Channel.swift
//  Engage
//
//  Created by Nathan Tannar on 2/3/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import NTUIKit

public class Channel {
    
    public var object: PFObject
    public var id: String {
        get {
            guard let id = self.object.objectId else {
                Log.write(.error, "User ID was nil")
                fatalError()
            }
            return id
        }
    }
    public var createdAt: Date? {
        get {
            return self.object.createdAt
        }
    }
    public var updatedAt: Date? {
        get {
            return self.object.updatedAt
        }
    }
    public var image: UIImage?
    public var name: String? {
        get {
            guard let name = self.object.value(forKey: PF_CHANNEL_NAME) as? String else {
                return nil
            }
            guard let members = self.members else {
                return nil
            }
            return name
        }
        set {
            self.object[PF_CHANNEL_NAME] = newValue
        }
    }
    public var isPrivate: Bool? {
        get {
            return self.object.value(forKey: PF_CHANNEL_PRIVATE) as? Bool
        }
        set {
            self.object[PF_CHANNEL_PRIVATE] = newValue
        }
    }
    public var members: [String]? {
        get {
            return self.object.value(forKey: PF_CHANNEL_MEMBERS) as? [String]
        }
        set {
            self.object[PF_CHANNEL_MEMBERS] = newValue
        }
    }
    public var admins: [String]? {
        get {
            return self.object.value(forKey: PF_CHANNEL_ADMINS) as? [String]
        }
        set {
            self.object[PF_CHANNEL_ADMINS] = newValue
        }
    }
    public var messages = [Message]()
    public var usernames: [String]? {
        get {
            var array = [String]()
            guard let members = members else {
                return nil
            }
            for member in members {
                guard let user = Cache.retrieveUser(member) else {
                    return nil
                }
                guard let username = user.fullname else {
                    return nil
                }
                array.append(username.replacingOccurrences(of: " ", with: ".").lowercased())
            }
            return array
        }
    }
    
    // MARK: Initialization
    
    public init(fromObject object: PFObject) {
        self.object = object
        
        if let file = self.object.value(forKey: PF_CHANNEL_IMAGE) as? PFFile {
            file.getDataInBackground { (data, error) in
                if let imageData = data {
                    self.image = UIImage(data: imageData)
                } else {
                    Log.write(.error, error.debugDescription)
                }
            }
        }
        if let members = self.members {
            if members.count <= 2 {
                // Private Chat
                var otherUserId = String()
                if members[0] != User.current().id {
                    otherUserId = members[0]
                } else {
                    otherUserId = members[1]
                }
                if let user = Cache.retrieveUser(otherUserId) {
                    self.name = user.fullname
                    self.image = UIImage(named: "profile_blank")
                    self.image = user.image
                    // Check if nil then assign character image
                } else {
                    let userQuery = PFUser.query()
                    userQuery?.whereKey(PF_USER_OBJECTID, equalTo: otherUserId)
                    userQuery?.getFirstObjectInBackground(block: { (object, error) in
                        if let user = object {
                            
                            self.name = user.value(forKey: PF_USER_FULLNAME) as? String
                            self.image = UIImage(named: "profile_blank")
                            let logoFile = user.value(forKey: PF_USER_PICTURE) as? PFFile
                            logoFile?.getDataInBackground { (data, error) in
                                guard let imageData = data else {
                                    Log.write(.error, error.debugDescription)
                                    return
                                }
                                self.image = UIImage(data: imageData)
                            }
                        } else {
                            Log.write(.error, error.debugDescription)
                        }
                    })
                }
            }
        }
        
        
        let messageQuery = PFQuery(className: Engagement.current().queryName! + PF_CHANNEL_CLASS_NAME)
        messageQuery.addDescendingOrder(PF_MESSAGE_CREATED_AT)
        messageQuery.whereKey(PF_MESSAGE_CHANNEL, equalTo: object)
        messageQuery.includeKey(PF_MESSAGE_USER)
        messageQuery.limit = 100
        messageQuery.findObjectsInBackground { (objects, error) in
            guard let messages = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            for message in messages {
                if let user = message.object(forKey: PF_MESSAGE_USER) as? PFUser {
                    if let text = message.value(forKey: PF_MESSAGE_TEXT) as? String {
                        self.messages.append(Message(user: Cache.retrieveUser(user), text: text, date: message.createdAt!, file: message.value(forKey: PF_MESSAGE_FILE) as? PFFile))
                    }
                }
            }
        }
    }
    
    public func addMessage(_ message: Message) {
        self.messages.append(message) //insert(message, at: 0)
    }
    
    public class func create(users: [User], name: String? = nil, completion: ((_ success: Bool) -> Void)?) {
        let newChannel = PFObject(className: Engagement.current().queryName! + PF_CHANNEL_CLASS_NAME)
        var members = [String]()
        var admins = [String]()
        for user in users {
            members.append(user.id)
        }
        members.append(User.current().id)
        if users.count == 1 {
            admins = members
            newChannel[PF_CHANNEL_PRIVATE] = true
        } else {
            admins = [User.current().id]
            newChannel[PF_CHANNEL_PRIVATE] = false
            newChannel[PF_CHANNEL_NAME] = name ?? User.current().id
        }
        newChannel[PF_CHANNEL_MEMBERS] = members
        newChannel[PF_CHANNEL_ADMINS] = admins
        
        newChannel.saveInBackground { (success, error) in
            if success {
                let channel = Cache.retrieveChannel(newChannel)
                if users.count == 1 {
                    Engagement.current().chats.append(channel)
                } else {
                    Engagement.current().channels.append(channel)
                }
                completion?(success)
            } else {
                Log.write(.error, error.debugDescription)
                Toast.genericErrorMessage()
                completion?(success)
            }
        }
    }
}
