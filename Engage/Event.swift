//
//  Event.swift
//  Engage
//
//  Created by Nathan Tannar on 2/4/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Foundation
import Parse
import NTUIKit

public class Event {
    
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
    public var title: String? {
        get {
            return self.object.value(forKey: PF_EVENT_NAME) as? String
        }
        set {
            self.object[PF_EVENT_NAME] = newValue
        }
    }
    public var info: String? {
        get {
            return self.object.value(forKey: PF_EVENT_INFO) as? String
        }
        set {
            self.object[PF_EVENT_INFO] = newValue
        }
    }
    public var location: String? {
        get {
            return self.object.value(forKey: PF_EVENT_LOCATION) as? String
        }
        set {
            self.object[PF_EVENT_LOCATION] = newValue
        }
    }
    public var url: String? {
        get {
            return self.object.value(forKey: PF_EVENT_URL) as? String
        }
        set {
            self.object[PF_EVENT_URL] = newValue
        }
    }
    public var isPrivate: Bool? {
        get {
            return self.object.value(forKey: PF_EVENT_PRIVATE) as? Bool
        }
        set {
            self.object[PF_EVENT_PRIVATE] = newValue
        }
    }
    public var start: Date? {
        get {
            return self.object.value(forKey: PF_EVENT_START) as? Date
        }
        set {
            self.object[PF_EVENT_START] = newValue
        }
    }
    public var end: Date? {
        get {
            return self.object.value(forKey: PF_EVENT_END) as? Date
        }
        set {
            self.object[PF_EVENT_END] = newValue
        }
    }
    public var isAllDay: Bool {
        get {
            return (self.object.value(forKey: PF_EVENT_ALL_DAY) as? Bool) ?? false
        }
        set {
            self.object[PF_EVENT_ALL_DAY] = newValue
        }
    }
    public var organizer: User? {
        get {
            guard let user = self.object.value(forKey: PF_EVENT_ORGANIZER) as? PFUser else {
                return nil
            }
            return Cache.retrieveUser(user.objectId!)
        }
        set {
            self.object[PF_EVENT_ORGANIZER] = newValue?.object
        }
    }
    public var invites: [String]? {
        get {
            return self.object.value(forKey: PF_EVENT_INVITES) as? [String]
        }
        set {
            self.object[PF_EVENT_INVITES] = newValue
        }
    }
    public var accepted: [String]? {
        get {
            return self.object.value(forKey: PF_EVENT_ACCEPTED) as? [String]
        }
        set {
            self.object[PF_EVENT_ACCEPTED] = newValue
        }
    }
    public var declined: [String]? {
        get {
            return self.object.value(forKey: PF_EVENT_DECLINED) as? [String]
        }
        set {
            self.object[PF_EVENT_DECLINED] = newValue
        }
    }
    public var longitude: Double? {
        get {
            return self.object.value(forKey: PF_EVENT_LONGITUDE) as? Double
        }
        set {
            self.object[PF_EVENT_LONGITUDE] = newValue
        }
    }
    public var latitude: Double? {
        get {
            return self.object.value(forKey: PF_EVENT_LATITUDE) as? Double
        }
        set {
            self.object[PF_EVENT_LATITUDE] = newValue
        }
    }
    public var coordinate: CLLocationCoordinate2D? {
        get {
            if let long = self.longitude {
                if let lat = self.latitude {
                    return CLLocationCoordinate2D(latitude: lat, longitude: long)
                }
            }
            return nil
        }
    }
    
    // MARK: Initialization
    
    public init(fromObject object: PFObject) {
        self.object = object
        
        let file = self.object.value(forKey: PF_EVENT_IMAGE) as? PFFile
        file?.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.image = UIImage(data: imageData)
        }
    }
    
    public init() {
        self.object = PFObject(className: Engagement.current().queryName! + PF_EVENT_CLASS_NAME)
        self.title = String()
        self.image = nil
        self.info = String()
        self.location = String()
        self.isPrivate = false
        self.start = Date()
        self.end = Date()
        self.organizer = User.current()
        self.invites = []
        self.declined = []
        self.accepted = []
        self.longitude = Double()
        self.latitude = Double()
    }
    
    // MARK: Public 
    
    public func save(completion: ((_ success: Bool) -> Void)?) {
        self.object.saveInBackground { (success, error) in
            if success {
                Cache.update(self)
                completion?(success)
            }
            if error != nil {
                Log.write(.error, "Could not save event")
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: error?.localizedDescription, button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 1.0)
                completion?(success)
            }
        }
    }
}
