//
//  Message.swift
//  Engage
//
//  Created by Nathan Tannar on 2/3/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTUIKit
import Parse

public class Message {
    
    public var object: PFObject
    public var id: String? {
        return self.object.objectId
    }
    public var user: User? {
        get {
            guard let user = object.object(forKey: PF_MESSAGE_USER) as? PFUser else {
                return nil
            }
            return Cache.retrieveUser(user)
        }
    }
    public var text: String? {
        get {
            return self.object.value(forKey: PF_MESSAGE_TEXT) as? String
        }
    }
    public var createdAt: Date? {
        get {
            return self.object.createdAt
        }
    }
    public var image: UIImage?
    
    
    public init(fromObject object: PFObject) {
        self.object = object
        
        let file = object.value(forKey: PF_MESSAGE_FILE) as? PFFile
        file?.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.image = UIImage(data: imageData)
        }
    }
}
