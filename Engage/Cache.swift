//
//  Cache.swift
//  Engage
//
//  Created by Nathan Tannar on 1/14/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Foundation
import Parse
import NTUIKit

public class Cache {
    
    public static var Users = [User]()
    
    public static var Engagements = [Engagement]()
    
    public static var Posts = [Post]()
    
    public static func add(_ object: AnyObject) {
        if let user = object as? User {
            Cache.Users.append(user)
        } else if let engagement = object as? Engagement {
            Cache.Engagements.append(engagement)
        } else if let post = object as? Post {
            Cache.Posts.append(post)
        } else {
            Log.write(.warning, "Could not cache object")
        }
    }
    
    public static func retrieveUser(_ userObject: PFUser) -> User {
        for user in Cache.Users {
            if user.id == userObject.objectId! {
                return user
            }
        }
        Log.write(.status, "Caching User with id \(userObject.objectId!)")
        let user = User(fromObject: userObject)
        Cache.add(user)
        return user
    }
    
    public static func retrieveEngagement(_ engagementObject: PFObject) -> Engagement {
        for engagement in Cache.Engagements {
            if engagement.id == engagementObject.objectId! {
                return engagement
            }
        }
        Log.write(.status, "Caching Engagement with id \(engagementObject.objectId!)")
        let engagement = Engagement(fromObject: engagementObject)
        Cache.add(engagement)
        return engagement
    }
    
    public static func retrievePost(_ postObject: PFObject) -> Post {
        for post in Cache.Posts {
            if post.id == postObject.objectId! {
                return post
            }
        }
        Log.write(.status, "Caching Post with id \(postObject.objectId!)")
        let post = Post(fromObject: postObject)
        Cache.add(post)
        return post
    }
}
