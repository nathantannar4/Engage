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
    private var _name: String?
    public var name: String? {
        get {
            guard let name = self.object.value(forKey: PF_CHANNEL_NAME) as? String else {
                return self._name
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
    public var isNew: Bool = false
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
        
        self.updateName()
        self.updateMessages(completion: nil)
    }
    
    // MARK: Public Functions
    
    public func save(completion: ((_ success: Bool) -> Void)?) {
        self.object.saveInBackground { (success, error) in
            if success {
                Cache.update(self)
                completion?(success)
            }
            if error != nil {
                Log.write(.error, "Could not save channel")
                Log.write(.error, error.debugDescription)
                Toast.genericErrorMessage()
                completion?(success)
            }
        }
    }
    
    public func undoModifications() {
        self.object = Cache.retrieveChannel(self.object).object
        self.image = Cache.retrieveChannel(self.object).image
        self.updateName()
    }
    
    public func updateName() {
        if self.name == nil {
            if let members = self.members {
                if members.count <= 2 {
                    var userId = String()
                    if members[0] != User.current().id {
                        userId = members[0]
                    } else {
                        userId = members[1]
                    }
                    
                    if let user = Cache.retrieveUser(userId) {
                        self._name = user.fullname
                        self.image = user.image
                    } else {
                        let userQuery = PFUser.query()
                        userQuery?.whereKey(PF_USER_OBJECTID, equalTo: userId)
                        userQuery?.getFirstObjectInBackground(block: { (object, error) in
                            guard let user = object else {
                                //Log.write(.error, error.debugDescription)
                                return
                            }
                            self._name = user.value(forKey: PF_USER_FULLNAME) as? String
                            self.image = UIImage(named: "profile_blank")
                            if let file = user.value(forKey: PF_USER_PICTURE) as? PFFile {
                                file.getDataInBackground { (data, error) in
                                    if let imageData = data {
                                        self.image = UIImage(data: imageData)
                                    } else {
                                        Log.write(.error, error.debugDescription)
                                    }
                                }
                            }
                        })
                    }
                } else {
                    self._name = "Unnamed Group Chat"
                }
            }
        }
    }
    
    public func updateObject(completion: ((_ isNew: Bool) -> Void)?) {
        let channelQuery = PFQuery(className: Engagement.current().queryName! + PF_CHANNEL_CLASS_NAME)
        channelQuery.whereKey(PF_CHANNEL_OBJECT_ID, equalTo: self.id)
        channelQuery.whereKey(PF_CHANNEL_UPDATED_AT, greaterThan: self.updatedAt ?? Date())
        channelQuery.getFirstObjectInBackground { (object, error) in
            guard let channel = object else {
                Log.write(.error, error.debugDescription)
                return
            }
            
            // Refresh Image
            if self.object.value(forKey: PF_CHANNEL_IMAGE) as? PFFile != channel.value(forKey: PF_CHANNEL_IMAGE) as? PFFile {
                Log.write(.status, "Updated channel image for channel \(self.id)")
                if let file = channel.value(forKey: PF_CHANNEL_IMAGE) as? PFFile {
                    file.getDataInBackground { (data, error) in
                        if let imageData = data {
                            self.image = UIImage(data: imageData)
                        } else {
                            Log.write(.error, error.debugDescription)
                        }
                    }
                }
            }
            self.object = channel
            self.updateName()
        }
        self.updateMessages { (isNew) in
            self.isNew = isNew
            completion?(isNew)
        }
    }
    
    public func updateMessages(completion: ((_ isNew: Bool) -> Void)?) {
        
        let messageQuery = PFQuery(className: Engagement.current().queryName! + PF_MESSAGE_CLASS_NAME)
        if let lastMessage = self.messages.last {
            messageQuery.whereKey(PF_MESSAGE_CREATED_AT, greaterThan: lastMessage.createdAt ?? Date())
        }
        messageQuery.addAscendingOrder(PF_MESSAGE_CREATED_AT)
        messageQuery.whereKey(PF_MESSAGE_CHANNEL, equalTo: self.object)
        messageQuery.includeKey(PF_MESSAGE_USER)
        messageQuery.limit = 100
        messageQuery.findObjectsInBackground { (objects, error) in
            guard let messages = objects else {
                Log.write(.error, error.debugDescription)
                completion?(false)
                return
            }
            for message in messages {
                if !self.messages.contains(where: { (findMessage) -> Bool in
                    if findMessage.id == message.objectId {
                        return true
                    }
                    return false
                }) {
                    self.messages.append(Message(fromObject: message))
                }
            }
            completion?(messages.count > 0)
        }
    }
    
    public func addMessage(text: String?, file: PFFile?, completion: ((_ isNew: Bool) -> Void)?) {
        
        let newMessage = PFObject(className: Engagement.current().queryName! + PF_MESSAGE_CLASS_NAME)
        newMessage[PF_MESSAGE_USER] = User.current().object
        newMessage[PF_MESSAGE_CHANNEL] = self.object
        newMessage[PF_MESSAGE_TEXT] = text
        
        /*
         var videoFile: PFFile!
         var pictureFile: PFFile!
         
         
         if let video = video {
         videoFile = PFFile(name: "video.mp4", data: FileManager.default.contents(atPath: video.path!)!)
         
         videoFile.saveInBackground(block: { (succeeed: Bool, error: Error?) -> Void in
         if error != nil {
         print("Network error")
         }
         })
         }
         
         if let picture = picture {
         pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(picture, 0.6)!)
         pictureFile.saveInBackground(block: { (suceeded: Bool, error: Error?) -> Void in
         if error != nil {
         print("Picture save error")
         }
         })
         }
         */
        
        
        
        /*
         if let videoFile = videoFile {
         newMessage[PF_MESSAGE_FILE] = videoFile
         }
         if let pictureFile = pictureFile {
         newMessage[PF_MESSAGE_FILE] = pictureFile
         }
         */
        
        newMessage.saveInBackground{ (success, error) -> Void in
            if success {
                
                self.messages.append(Message(fromObject: newMessage))
                completion?(success)
                
                
                //PushNotication.sendPushNotificationMessage(groupId, text: "\(PFUser.current()!.value(forKey: "fullname")!): \(text)")
                //Messages.updateMessageCounter(groupId: groupId, lastMessage: text)
            } else {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: "Error Sending Message", button: nil, color: Color.darkGray, height: 44)
                toast.show(duration: 1.0)
                completion?(success)
            }
        }
    }
    
    public class func create(users: [User], name: String? = nil, isPrivate: Bool, completion: ((_ success: Bool) -> Void)?) {
        let newChannel = PFObject(className: Engagement.current().queryName! + PF_CHANNEL_CLASS_NAME)
        var members = [String]()
        
        for user in users {
            members.append(user.id)
        }
        members.append(User.current().id)
        
        newChannel[PF_CHANNEL_PRIVATE] = isPrivate
        if name != nil {
            newChannel[PF_CHANNEL_NAME] = name!
        }
        newChannel[PF_CHANNEL_MEMBERS] = members
        newChannel[PF_CHANNEL_ADMINS] = [User.current().id]
        
        newChannel.saveInBackground { (success, error) in
            if success {
                let channel = Cache.retrieveChannel(newChannel)
                if isPrivate {
                    Engagement.current().chats.insert(channel, at: 0)
                } else {
                    Engagement.current().channels.insert(channel, at: 0)
                }
                completion?(success)
            } else {
                Log.write(.error, error.debugDescription)
                Toast.genericErrorMessage()
                completion?(success)
            }
        }
    }
    
    public func promote(user: User, completion: ((_ success: Bool) -> Void)?) {
        guard var admins = self.admins else {
            completion?(false)
            return
        }
        admins.append(user.id)
        self.admins = admins
        self.save { (success) in
            completion?(success)
            if success {
                Log.write(.status, "User \(user.id) was promoted to an admin in channel \(self.id)")
            } else {
                Toast.genericErrorMessage()
            }
        }
    }
    
    public func join(user: User, completion: ((_ success: Bool) -> Void)?) {
        guard var members = self.members else {
            completion?(false)
            return
        }
        members.append(user.id)
        self.members = members
        self.save { (success) in
            completion?(success)
            if success {
                Log.write(.status, "User \(user.id) joined channel \(self.id)")
            } else {
                Toast.genericErrorMessage()
            }
        }
    }
    
    public func leave(user: User, completion: ((_ success: Bool) -> Void)?) {
        guard var members = self.members else {
            completion?(false)
            return
        }
        if let index = members.index(of: user.id) {
            members.remove(at: index)
            self.members = members
            if var admins = self.admins {
                if let adminIndex = admins.index(of: user.id) {
                    admins.remove(at: adminIndex)
                    if admins.count == 0 {
                        self.members = admins
                    }
                    self.admins = admins
                }
            }
        }
        self.save { (success) in
            completion?(success)
            if success {
                Log.write(.status, "User \(user.id) left channel \(self.id)")
            } else {
                Toast.genericErrorMessage()
            }
        }
    }
    
    public func delete(completion: ((_ success: Bool) -> Void)?) {
        self.object.deleteInBackground { (success, error) in
            completion?(success)
            if error != nil {
                Log.write(.error, error.debugDescription)
                Toast.genericErrorMessage()
            } else {
                let messageQuery = PFQuery(className: Engagement.current().queryName! + PF_MESSAGE_CLASS_NAME)
                messageQuery.whereKey(PF_MESSAGE_CHANNEL, equalTo: self.object)
                messageQuery.limit = 1000
                messageQuery.findObjectsInBackground { (objects, error) in
                    guard let messages = objects else {
                        Log.write(.error, "Error while deleting messages")
                        Log.write(.error, error.debugDescription)
                        return
                    }
                    for message in messages {
                        message.deleteInBackground()
                    }
                }
            }
        }
    }
}
