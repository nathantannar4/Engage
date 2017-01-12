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
    
    static var _current: User?
    
    public var object: PFUser
    public var id: String? {
        get {
            return self.object.objectId
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
    
    public init(fromObject object: PFUser) {
        self.object = object
        
        guard let file = self.object.value(forKey: PF_USER_PICTURE) as? PFFile else {
            return
        }
        file.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.image = UIImage(data: imageData)
        }
    }
    
    public static func current() -> User? {
        return self._current
    }
    
    public class func didLogin(with user: PFUser) {
        self._current = User(fromObject: user)
        let navContainer = NTNavigationContainer(centerView: ActivityFeedViewController(), leftView: MenuViewController(), rightView: nil)
        UIApplication.shared.keyWindow?.rootViewController = navContainer
    }
}
