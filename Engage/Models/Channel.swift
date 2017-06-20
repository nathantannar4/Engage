//
//  Channel.swift
//  Engage
//
//  Created by Nathan Tannar on 2/3/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import NTComponents

public class Message {
    
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
    public var text: String {
        get {
            return self.object.value(forKey: PF_MESSAGE_TEXT) as? String ?? String()
        }
        set {
            self.object[PF_MESSAGE_TEXT] = newValue
        }
    }
    public var userPointer: PFUser? {
        get {
            return self.object.object(forKey: PF_MESSAGE_USER) as? PFUser
        }
        set {
            self.object[PF_MESSAGE_USER] = newValue
        }
    }
    public weak var user: User?
    public var channelPointer: PFObject? {
        get {
            return object.object(forKey: PF_MESSAGE_CHANNEL) as? PFObject
        }
        set {
            object[PF_MESSAGE_CHANNEL] = newValue
        }
    }
    public weak var channel: Channel?
    
    // MARK: Initialization
    
    public init(_ object: PFObject) {
        self.object = object
        
        userPointer?.fetchInBackground(block: { (object, error) in
            guard let user = object else {
                return
            }
            self.user = User(user as! PFUser)
        })
    }
}

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
            return self.object.value(forKey: PF_CHANNEL_NAME) as? String
        }
        set {
            self.object[PF_CHANNEL_NAME] = newValue
        }
    }
    public var members: PFRelation<PFObject>? {
        get {
            return self.object.relation(forKey: PF_CHANNEL_MEMBERS)
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
    public var messages: PFRelation<PFObject>? {
        get {
            return self.object.relation(forKey: PF_CHANNEL_MESSAGES)
        }
        set {
            self.object[PF_CHANNEL_MESSAGES] = newValue
        }
    }
    
    // MARK: Initialization
    
    public class func create(withUsers users: [User], completion: @escaping ((_ channel: Channel) -> Void)) {
        let object = PFObject(className: Engagement.current()!.queryName! + PF_CHANNEL_CLASS_NAME)
        for user in users {
            object.relation(forKey: PF_CHANNEL_MEMBERS).add(user.object)
        }
        object[PF_CHANNEL_NAME] = String.random(ofLength: 10)
        object.saveInBackground { (success, error) in
            if success {
                completion(Channel(object))
            } else {
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription.capitalized).show()
            }
        }
    }
    
    public init(_ object: PFObject) {
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
    }
    
    // MARK: Public Functions
    
    public func save(completion: ((_ success: Bool) -> Void)?) {
        self.object.saveInBackground { (success, error) in
            completion?(success)
            if error != nil {
                Log.write(.error, "Could not save channel")
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription.capitalized).show()
            }
        }
    }
    
    public func addMessage(_ user: User, text: String)  {
        let object = PFObject(className: Engagement.current()!.queryName! + PF_MESSAGE_CLASS_NAME)
        object[PF_MESSAGE_USER] = user.object
        object[PF_MESSAGE_CHANNEL] = self.object
        object[PF_MESSAGE_TEXT] = text
        object.saveInBackground { (success, error) in
            if success {
                self.messages?.add(object)
                self.save(completion: nil)
            } else {
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: "Message Send Failure").show()
            }
        }
    }
    
    public func add(user: User, completion: ((_ success: Bool) -> Void)?) {
        self.members?.add(user.object)
        self.save { (success) in
            completion?(success)
            if success {
                Log.write(.status, "User \(user.id) joined channel \(self.id)")
            }
        }
    }
    
    public func remove(user: User, completion: ((_ success: Bool) -> Void)?) {
        self.members?.remove(user.object)
        self.save { (success) in
            completion?(success)
            if success {
                Log.write(.status, "User \(user.id) left channel \(self.id)")
            }
        }
    }
}
