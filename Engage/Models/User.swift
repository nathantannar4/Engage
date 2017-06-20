//
//  User.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import UIKit
import NTComponents

public class User: Equatable {
    
    private static var _current: User?
    private static let imageCache = NSCache<NSString, DiscardableImageCacheItem>()
    
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
    public static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
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
    public var coverImage: UIImage?
    public var fullname: String? {
        get {
            return self.object.value(forKey: PF_USER_FULLNAME) as? String
        }
        set {
            self.object[PF_USER_FULLNAME] = newValue?.lowercased().capitalized
            self.object[PF_USER_FULLNAME_LOWER] = newValue?.lowercased()
        }
    }
    public var email: String? {
        get {
            return self.object.email
        }
        set {
            if newValue!.isValidEmail {
                self.object.email = newValue
            }
        }
    }
    public var phone: String? {
        get {
            return self.object.value(forKey: PF_USER_PHONE) as? String
        }
        set {
            self.object[PF_USER_PHONE] = newValue
        }
    }
    public var blockedUsers: PFRelation<PFObject>? {
        get {
            return self.object.relation(forKey: PF_USER_BLOCKED)
        }
        set {
            self.object[PF_USER_BLOCKED] = newValue
        }
    }
    public var engagements: PFRelation<PFObject>? {
        get {
            return self.object.relation(forKey: PF_USER_ENGAGEMENTS)
        }
        set {
            self.object[PF_USER_ENGAGEMENTS] = newValue
            
        }
    }
    
    // MARK: Initialization
    
    public init(_ object: PFUser) {
        self.object = object
        
        if let profileFile = self.object.value(forKey: PF_USER_PICTURE) as? PFFile {
            if let cachedItem = User.imageCache.object(forKey: NSString(string: profileFile.url!)) {
                image = cachedItem.image
            } else {
                profileFile.getDataInBackground { (data, error) in
                    guard let imageData = data else {
                        Log.write(.error, error.debugDescription)
                        return
                    }
                    self.image = UIImage(data: imageData)
                    let cacheItem = DiscardableImageCacheItem(image: UIImage(data: imageData)!)
                    User.imageCache.setObject(cacheItem, forKey: NSString(string: profileFile.url!))
                }
            }
        }
        
        if let coverFile = self.object.value(forKey: PF_USER_COVER) as? PFFile {
            if let cachedItem = User.imageCache.object(forKey: NSString(string: coverFile.url!)) {
                coverImage = cachedItem.image
            } else {
                coverFile.getDataInBackground { (data, error) in
                    guard let imageData = data else {
                        Log.write(.error, error.debugDescription)
                        return
                    }
                    self.coverImage = UIImage(data: imageData)
                    let cacheItem = DiscardableImageCacheItem(image: UIImage(data: imageData)!)
                    User.imageCache.setObject(cacheItem, forKey: NSString(string: coverFile.url!))
                }
            }
        }
        
        self.loadExtension(completion: nil)
    }
    
    // MARK: Public Functions
    
    public static func current() -> User? {
        return self._current
    }
    
    public func login() {
        User._current = self
        let query = engagements?.query()
        query?.getFirstObjectInBackground(block: { (object, error) in
            DispatchQueue.main.async {
                if object == nil {
                    GettingStartedViewController().makeKeyAndVisible()
                } else {
                    NTDrawerController(centerViewController: NTNavigationController(rootViewController: SideBarMenuViewController())).makeKeyAndVisible()
                }
            }  
        })
    }
    
    public func logout() {
        
        guard let controller = UIViewController.topController() else {
            return
        }
        
        let logoutAction = NTActionSheetItem(title: "Logout") {
            PFUser.logOutInBackground { (error) in
                if error == nil {
                    User._current = nil
                    let vc = NTNavigationController(rootViewController: LoginViewController())
                    if let navContainer = controller as? NTDrawerController {
                        navContainer.removeViewController(forSide: .left)
                        navContainer.setViewController(vc, forSide: .center)
                    } else {
                        vc.makeKeyAndVisible()
                    }
                } else {
                    NTPing.genericErrorMessage()
                }
            }
        }
        let actionSheet = NTActionSheetViewController(title: nil, subtitle: nil, actions: [logoutAction])
        actionSheet.addDismissAction(withText: "Cancel", icon: nil)
        controller.present(actionSheet, animated: false, completion: nil)
    }
    
    public func save(completion: ((_ success: Bool) -> Void)?) {
        self.object.saveInBackground { (success, error) in
            if success && self.userExtension != nil {
                self.userExtension?.save(completion: { (success) in
                    //Cache.update(self)
                    completion?(success)
                })
            }
            if error != nil {
                Log.write(.error, "Could not save user")
                Log.write(.error, error.debugDescription)
                let toast = NTToast(text: error?.localizedDescription)
                toast.show(duration: 1.0)
                completion?(success)
            }
        }
    }
    
    public func upload(image: UIImage?, forKey key: String, completion: (() -> Void)?) {
        
        guard let image = image else {
            completion?()
            return
        }
        
        let ping = NTPing(type: .isInfo, title: "Uploading Image...")
        ping.show()
        if let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(image, 0.6)!) {
            pictureFile.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error != nil {
                    Log.write(.error, error.debugDescription)
                    NTPing(type: .isDanger, title: error?.localizedDescription.capitalized).show()
                } else {
                    ping.dismiss()
                    self.object[key] = pictureFile
                    completion?()
                }
            }
        }
    }
    
    public func loadExtension(completion: (() -> Void)?) {
        let userExtenionQuery = PFQuery(className: Service.queryHome + PF_USER_CLASS_NAME)
        userExtenionQuery.includeKey(PF_USER_TEAM)
        userExtenionQuery.whereKey(PF_USER_EXTENSION, equalTo: self.object)
        userExtenionQuery.findObjectsInBackground { (objects, error) in
            guard let userExtensions = objects else {
                Log.write(.error, error.debugDescription)
                completion?()
                return
            }
            if userExtensions.count == 0 {
                // Extension does not exist yet
                let newExtension = PFObject(className: Service.queryHome + PF_USER_CLASS_NAME)
                newExtension[PF_USER_EXTENSION] = User.current()?.object
                newExtension.saveInBackground()
                Log.write(.status, "Created extension for user \(self.id)")
                self.userExtension = UserExtension(fromObject: newExtension)
                
            } else if userExtensions.count == 1 {
                self.userExtension = UserExtension(fromObject: userExtensions[0])
                Log.write(.status, "Loaded extension for user \(self.id)")
                
            } else {
                self.userExtension = UserExtension(fromObject: userExtensions[0])
                Log.write(.status, "Loaded extension for user \(self.id)")
                
                // Extra extensions exist
                for index in 1...userExtensions.count {
                    Log.write(.warning, "An extra extension for user \(self.id) was deleted")
                    userExtensions[index].deleteInBackground()
                }
            }
            completion?()
        }
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
        public var bio: String? {
            get {
                return self.object.value(forKey: PF_USER_BIO) as? String
            }
            set {
                self.object[PF_USER_BIO] = newValue
            }
        }
        //public var team: Team?
        
        // MARK: Initialization
        
        public init(fromObject object: PFObject) {
            self.object = object
            
            //guard let team = object.object(forKey: PF_USER_TEAM) as? PFObject else {
            //    Log.write(.status, "User is not associated with a team")
            //    return
            //}
            //self.team = Team(team)
        }
        
        // MARK: Public Functions
        
        public func field(forIndex index: Int) -> String? {
            guard let profileFields = Engagement.current()?.profileFields else {
                Log.write(.warning, "Engagements profile fields was nil")
                return nil
            }
            if index >= profileFields.count {
                return nil
            }
            let indexString = profileFields[index].replacingOccurrences(of: " ", with: "_")
            return self.object.value(forKey: indexString) as? String
        }
 
        
        public func setValue(_ newValue: String?, forField field: String) {
            self.object[field] = newValue
        }
        
        public func save(completion: ((_ success: Bool) -> Void)?) {
            self.object.saveInBackground { (success, error) in
                completion?(success)
                if error != nil {
                    Log.write(.error, "Could not save user extension")
                    Log.write(.error, error.debugDescription)
                    NTPing.genericErrorMessage()
                }
            }
        }
    }
}
