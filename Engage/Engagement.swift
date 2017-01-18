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
    public var image: UIImage?
    public var name: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_NAME) as? String
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
    }
    
    // MARK: Initialization
    
    public init(fromObject object: PFObject) {
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
    
    // MARK: Public Functions
    
    public static func current() -> Engagement? {
        guard let engagement = self._current else {
            Log.write(.error, "The current engagement was nil")
            return nil
        }
        return engagement
    }
    
    public class func didSelect(with engagement: PFObject) {
        self._current = Engagement(fromObject: engagement)
        User.current().loadExtension()
        let navContainer = NTNavigationContainer(centerView: ActivityFeedViewController(), leftView: MenuViewController(), rightView: nil)
        UIApplication.shared.keyWindow?.rootViewController = navContainer
    }
    
    var engagement: PFObject?
    var members = [String]()
    var admins = [String]()
    var info: String?
    var hidden: Bool?
    var memberCount: Int?
    var password: String?
    var coverPhoto: UIImage?
    var fieldInput: String?
    var phone: String?
    var address: String?
    var email: String?
    var url: String?
    var positionsField: String?
    var positions = [String]()
    var subGroupName: String?
    var color: String?
    
  

}
