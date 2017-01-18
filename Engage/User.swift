//
//  User.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Foundation
import Parse
import NTUIKit

public class User {
    
    private static var _current: User?
    
    public var object: PFUser
    public var userExtension: UserExtension?
    public var id: String {
        get {
            guard let id = self.object.objectId else {
                Log.write(.error, "User ID was nil")
                fatalError()
            }
            return id
        }
    }
    public var image: UIImage?
    public var fullname: String? {
        get {
            return self.object.value(forKey: PF_USER_FULLNAME) as? String
        }
    }
    public var email: String? {
        get {
            return self.object.email
        }
    }
    public var phone: String? {
        get {
            return self.object.value(forKey: PF_USER_PHONE) as? String
        }
    }
    public var blockedUsers: [String]? {
        get {
            return self.object.value(forKey: PF_USER_BLOCKED) as? [String]
        }
    }
    public var engagements: [String]? {
        get {
            return self.object.value(forKey: PF_USER_ENGAGEMENTS) as? [String]
        }
    }
    
    // MARK: Initialization
    
    public init(fromObject object: PFUser) {
        self.object = object
        
        guard let file = self.object.value(forKey: PF_USER_PICTURE) as? PFFile else {
            return
        }
        Log.write(.error, "Downloading image for user with id \(self.id)")
        file.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.image = UIImage(data: imageData)
        }
    }
    
    // MARK: Public Functions
    
    public static func current() -> User {
        guard let user = self._current else {
            // Show login screen
            Log.write(.error, "The current user was nil")
            fatalError()
        }
        return user
    }
    
    public func loadExtension() {
        guard let engagement = Engagement.current() else {
            return
        }
        let userExtenionQuery = PFQuery(className: engagement.queryName! + PF_USER_CLASS_NAME)
        userExtenionQuery.whereKey(PF_USER_EXTENSION, equalTo: User.current().object)
        userExtenionQuery.findObjectsInBackground { (objects, error) in
            guard let userExtensions = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            if userExtensions.count == 0 {
                // Extension does not exist yet
                let newExtension = PFObject(className: engagement.queryName! + PF_USER_CLASS_NAME)
                newExtension[PF_USER_EXTENSION] = User.current().object
                newExtension.saveInBackground()
                Log.write(.status, "Created extension for user \(self.id)")
                self.userExtension = UserExtension(fromObject: newExtension)
            } else if userExtensions.count == 1 {
                self.userExtension = UserExtension(fromObject: userExtensions[0])
                Log.write(.status, "Loaded extension for user \(self.id)")
            } else {
                // Extra extensions exist
                for index in 1...userExtensions.count {
                    Log.write(.warning, "An extra extension for user \(self.id) was deleted")
                    userExtensions[index].deleteInBackground()
                }
            }
        }
    }
    
    public class func didLogin(with user: PFUser) {
        self._current = User(fromObject: user)
    }
    
    // MARK: User Extension
    
    public class UserExtension {
        
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
        
        // MARK: Initialization
        
        public init(fromObject object: PFObject) {
            self.object = object
        }
        
        // MARK: Public Functions
        
        public func field(forIndex index: Int) -> String? {
            guard let engagement = Engagement.current() else {
                return nil
            }
            guard let profileFields = engagement.profileFields else {
                Log.write(.warning, "Engagements profile fields was nil")
                return nil
            }
            if index >= profileFields.count {
                return nil
            }
            let indexString = profileFields[index].replacingOccurrences(of: " ", with: "_").lowercased()
            return self.object.value(forKey: indexString) as? String
        }
    }
}
