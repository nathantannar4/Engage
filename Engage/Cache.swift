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
    
    public static var ids = [String]()
    
    public static func add(_ object: AnyObject) {
        if let user = object as? User {
            Cache.ids.append(user.id)
            Cache.Users.append(user)
        } else if let engagement = object as? Engagement {
            Cache.ids.append(engagement.id)
            Cache.Engagements.append(engagement)
        } else if let post = object as? Post {
            Cache.ids.append(post.id)
            Cache.Posts.append(post)
        } else {
            Log.write(.warning, "Could not cache object")
        }
    }
    
    public static func update(_ object: AnyObject) {
        if let user = object as? User {
            Cache.retrieveUser(user.object)
        } else if let engagement = object as? Engagement {
            let _ = Cache.retrieveEngagement(engagement.object)
        } else if let post = object as? Post {
            let _ = Cache.retrievePost(post.object)
        } else {
            Log.write(.warning, "Could updated cached object")
        }
    }
    
    public static func retrieveUser(_ userObject: PFUser) -> User {
        var index = 0
        for user in Cache.Users {
            if user.id == userObject.objectId! {
                if user.updatedAt == userObject.updatedAt {
                    return user
                } else {
                    let updatedUser = User(fromObject: userObject)
                    Cache.Users[index] = updatedUser
                    return updatedUser
                }
            }
            index += 1
        }
        Log.write(.status, "Caching User with id \(userObject.objectId!)")
        let user = User(fromObject: userObject)
        user.loadExtension()
        Cache.add(user)
        return user
    }
    
    public static func retrieveUser(_ id: String) -> User? {
        for user in Cache.Users {
            if user.id == id {
                return user
            }
        }
        return nil
    }
    
    public static func retrieveEngagement(_ engagementObject: PFObject) -> Engagement {
        var index = 0
        for engagement in Cache.Engagements {
            if engagement.id == engagementObject.objectId! {
                if engagement.updatedAt == engagementObject.updatedAt {
                    return engagement
                } else {
                    let updatedEngagement = Engagement(fromObject: engagementObject)
                    Cache.Engagements[index] = updatedEngagement
                    return updatedEngagement
                }
            }
            index += 1
        }
        Log.write(.status, "Caching Engagement with id \(engagementObject.objectId!)")
        let engagement = Engagement(fromObject: engagementObject)
        Cache.add(engagement)
        return engagement
    }
    
    public static func retrievePost(_ postObject: PFObject) -> Post {
        var index = 0
        for post in Cache.Posts {
            if post.id == postObject.objectId! {
                if post.updatedAt == postObject.updatedAt {
                    return post
                } else {
                    let updatedPost = Post(fromObject: postObject)
                    Cache.Posts[index] = updatedPost
                    return post
                }
            }
            index += 1
        }
        Log.write(.status, "Caching Post with id \(postObject.objectId!)")
        let post = Post(fromObject: postObject)
        Cache.add(post)
        return post
    }
}
