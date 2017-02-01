//
//  Engagement.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import NTUIKit

public class Engagement {
    
    private static var _current: Engagement?
    
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
    public var coverImage: UIImage?
    public var name: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_NAME) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_NAME] = newValue
        }
    }
    public var queryName: String? {
        get {
            return self.name?.replacingOccurrences(of: " ", with: "_")
        }
    }
    public var profileFields: [String]? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_PROFILE_FIELDS) as? [String]
        }
        set {
            self.object[PF_ENGAGEMENTS_PROFILE_FIELDS] = newValue
        }
    }
    public var info: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_INFO) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_INFO] = newValue
        }
    }
    public var subgroupName: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_SUBGROUP_NAME) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_SUBGROUP_NAME] = newValue
        }
    }
    public var color: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENT_COLOR) as? String
        }
        set {
            self.object[PF_ENGAGEMENT_COLOR] = newValue
        }
    }
    public var url: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_URL) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_URL] = newValue
        }
    }
    public var email: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_EMAIL) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_EMAIL] = newValue
        }
    }
    public var address: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_ADDRESS) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_ADDRESS] = newValue
        }
    }
    public var phone: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_PHONE) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_PHONE] = newValue
        }
    }
    public var members: [String]? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_MEMBERS) as? [String]
        }
        set {
            self.object[PF_ENGAGEMENTS_MEMBERS] = newValue
        }
    }
    public var admins: [String]? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_ADMINS) as? [String]
        }
        set {
            self.object[PF_ENGAGEMENTS_ADMINS] = newValue
        }
    }
    var hidden: Bool?
    var password: String?
    
    // MARK: Initialization
    
    public init(fromObject object: PFObject) {
        self.object = object
        
        guard let logoFile = self.object.value(forKey: PF_ENGAGEMENTS_LOGO) as? PFFile else {
            return
        }
        logoFile.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.image = UIImage(data: imageData)
        }
        
        guard let coverFile = self.object.value(forKey: PF_ENGAGEMENTS_COVER_PHOTO) as? PFFile else {
            return
        }
        coverFile.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.coverImage = UIImage(data: imageData)
        }
    }
    
    // MARK: Public Functions
    
    public static func current() -> Engagement! {
        guard let engagement = self._current else {
            Log.write(.error, "The current engagement was nil")
            return nil
        }
        return engagement
    }
    
    public func save(completion: ((_ success: Bool) -> Void)?) {
        self.object.saveInBackground { (success, error) in
            completion?(success)
            if success {
                Cache.update(self)
            }
            if error != nil {
                Log.write(.error, "Could not save engagement")
                Log.write(.error, error.debugDescription)
                Toast.genericErrorMessage()
            }
        }
    }
    
    public func undoModifications() {
        Engagement._current = Cache.retrieveEngagement(self.object)
    }
    
    public class func didSelect(with engagement: PFObject) {
        self._current = Engagement(fromObject: engagement)
        User.current().loadExtension()
        let navContainer = NTNavigationContainer(centerView: ActivityFeedViewController(), leftView: MenuViewController(), rightView: nil)
        UIApplication.shared.keyWindow?.rootViewController = navContainer
    }
}
