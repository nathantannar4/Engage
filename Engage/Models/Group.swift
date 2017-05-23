//
//  File.swift
//  Engage
//
//  Created by Nathan Tannar on 1/31/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import NTComponents

public class Group {
    
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
            self.object[PF_ENGAGEMENTS_LOWERCASE_NAME] = newValue?.lowercased()
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
            guard let email = newValue else {
                return
            }
            if email.isValidEmail {
                self.object[PF_ENGAGEMENTS_EMAIL] = newValue
            }
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
    public var password: String? {
        get {
            let pwd = self.object.value(forKey: PF_ENGAGEMENTS_PASSWORD) as? String
            if pwd == nil {
                self.password = String()
            }
            return self.object.value(forKey: PF_ENGAGEMENTS_PASSWORD) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_PASSWORD] = newValue
        }
    }
    public var hidden: Bool? {
        get {
            let isHidden = self.object.value(forKey: PF_ENGAGEMENTS_HIDDEN) as? Bool
            if isHidden == nil {
                self.hidden = false
            }
            return self.object.value(forKey: PF_ENGAGEMENTS_HIDDEN) as? Bool
        }
        set {
            self.object[PF_ENGAGEMENTS_HIDDEN] = newValue
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
    public var positions: [String]? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_POSITIONS) as? [String]
        }
        set {
            self.object[PF_ENGAGEMENTS_POSITIONS] = newValue
        }
    }
    public var profileFields: [String]? {
        get {
            let fields = self.object.value(forKey: PF_ENGAGEMENTS_PROFILE_FIELDS) as? [String]
            if fields == nil {
                self.profileFields = [String]()
            }
            return self.object.value(forKey: PF_ENGAGEMENTS_PROFILE_FIELDS) as? [String]
        }
        set {
            self.object[PF_ENGAGEMENTS_PROFILE_FIELDS] = newValue
        }
    }
    
    // MARK: Initialization

    public init(_ object: PFObject) {
        self.object = object
        
        let logoFile = self.object.value(forKey: PF_ENGAGEMENTS_LOGO) as? PFFile
        logoFile?.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.image = UIImage(data: imageData)
        }
        
        let coverFile = self.object.value(forKey: PF_ENGAGEMENTS_COVER_PHOTO) as? PFFile
        coverFile?.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.coverImage = UIImage(data: imageData)
        }
    }
    
    // MARK: Public Functions
    
    public func save(completion: ((_ success: Bool) -> Void)?) {
        self.object.saveInBackground { (success, error) in
            completion?(success)
            if success {
                //Cache.update(self)
            }
            if error != nil {
                Log.write(.error, "Could not save engagement")
                Log.write(.error, error.debugDescription)
                NTToast(text: error?.localizedDescription).show()
                NTPing(type: .isDanger, title: "Saved Failed").show()
            }
        }
    }
    
    public func create(completion: ((_ success: Bool) -> Void)?) {
        self.admins = [User.current()!.id]
        self.members = self.admins
        self.save { (success) in
            if success {
                User.current()?.engagementRelations?.add(self.object)
                User.current()?.save(completion: { (success) in
                    completion?(success)
                })
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
                Log.write(.status, "User \(user.id) was promoted to an admin in group \(self.id)")
            } else {
                NTPing.genericErrorMessage()
            }
        }
    }
    
    public func demote(user: User, completion: ((_ success: Bool) -> Void)?) {
        guard var admins = self.admins else {
            completion?(false)
            return
        }
        if let index = admins.index(of: user.id) {
            if admins.count <= 1 {
                NTToast(text: "You are the only admin.").show()
                NTPing(type: .isWarning, title: "Cannot Resign").show()
                completion?(false)
            } else {
                admins.remove(at: index)
                self.admins = admins
                self.save { (success) in
                    completion?(success)
                    if success {
                        Log.write(.status, "User \(user.id) was demoted in group \(self.id)")
                    } else {
                        NTPing.genericErrorMessage()
                    }
                }
            }
        } else {
            completion?(false)
        }
    }

    public func join(user: User, completion: ((_ success: Bool) -> Void)?) {
        guard var members = self.members else {
            completion?(false)
            return
        }
        
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: name, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = Color.Default.Tint.View
        
        let joinAction: UIAlertAction = UIAlertAction(title: "Join", style: .default) { action -> Void in
            members.append(user.id)
            self.members = members
            self.save { (success) in
                completion?(success)
                if success {
                    Log.write(.status, "User \(user.id) joined group \(self.id)")
                    if self is Engagement {
                        User.current()?.engagementRelations?.add(self.object)
                        User.current()?.save(completion: nil)
                    }
                } else {
                    NTPing.genericErrorMessage()
                }
            }
        }
        actionSheetController.addAction(joinAction)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .destructive)
        actionSheetController.addAction(cancelAction)
        
        Group.topWindow()?.rootViewController?.present(actionSheetController, animated: true, completion: nil)
    }
    
    public func leave(user: User, completion: ((_ success: Bool) -> Void)?) {
        guard var members = self.members else {
            completion?(false)
            return
        }
        if let index = members.index(of: user.id) {
            if var admins = self.admins {
                if let adminIndex = admins.index(of: user.id) {
                    admins.remove(at: adminIndex)
                    if admins.count == 0 {
                        NTToast(text: "You are the only admin. You can delete the group.").show()
                        NTPing(type: .isWarning, title: "Cannot Leave").show()
                        completion?(false)
                        return
                    }
                    self.admins = admins
                }
            }
            members.remove(at: index)
            self.members = members
        }
        self.save { (success) in
            if success {
                Log.write(.status, "User \(user.id) left group \(self.id)")
                if user.id == User.current()?.id, let engagement = self as? Engagement {
                    engagement.didResign()
                }
            } else {
                NTPing.genericErrorMessage()
            }
            completion?(success)
        }
    }
    
    public func delete(completion: ((_ success: Bool) -> Void)?) {
        self.object.deleteInBackground { (success, error) in
            completion?(success)
            if error != nil {
                Log.write(.error, error.debugDescription)
                NTPing.genericErrorMessage()
            } else {
                let messageQuery = PFQuery(className: Service.queryHome + PF_MESSAGE_CLASS_NAME)
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
    
    public func position(forUser user: User) -> String? {
        guard let positions = self.positions else {
            Log.write(.status, "No positions exist")
            return nil
        }
        var positionIds = [String]()
        for position in positions {
            // Maps positions to the user ids
            positionIds.append((self.object.value(forKey: position.replacingOccurrences(of: " ", with: "").lowercased()) as? String) ?? String())
        }
        for id in positionIds {
            if user.id == id {
                return positions[positionIds.index(of: id)!]
            }
        }
        return nil
    }
    
    public func setPosition(forUser user: User, position: String, completion: ((_ success: Bool) -> Void)?) {
        self.object[position.lowercased()] = user.id
        self.save { (success) in
            completion?(success)
        }
    }
    
    public func emptyPosition(_ position: String, completion: ((_ success: Bool) -> Void)?) {
        self.object[position.lowercased()] = NSNull()
        self.save { (success) in
            completion?(success)
        }
    }
    
    class func topWindow() -> UIWindow? {
        for window in UIApplication.shared.windows.reversed() {
            if window.windowLevel == UIWindowLevelNormal && !window.isHidden && window.frame != CGRect.zero {
                return window
            }
        }
        return nil
    }
}
