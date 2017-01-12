//
//  Post.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Foundation
import Parse
import NTUIKit

public class Post {
    
    public var object: PFObject
    public var user: User!
    public var content: String? {
        get {
            return self.object.value(forKey: PF_POST_INFO) as? String
        }
    }
    public var image: UIImage?
    public var createdAt: Date? {
        get {
            return self.object.createdAt
        }
    }
    public var likes: [String]? {
        get {
            return self.object.value(forKey: PF_POST_LIKES) as? [String]
        }
    }
    public var comments: [Comment]? 
    
    public init(fromObject object: PFObject) {
        self.object = object
        guard let objectUser = object.object(forKey: PF_POST_USER) as? PFUser else {
            Log.write(.error, "Object with ID \(object.objectId!) did not have a cooresponding user")
            return
        }
        self.user = User(fromObject: objectUser)
        
        guard let file = self.object.value(forKey: PF_POST_IMAGE) as? PFFile else {
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
    
    public init() {
        self.object = PFObject(className: "ChitterBox_Posts")
        guard let currenrUser = PFUser.current() else {
            Log.write(.error, "PFUser.current() was nil, cannot create a new Post object")
            return
        }
        self.user = User(fromObject: currenrUser)
    }
    
    
}
