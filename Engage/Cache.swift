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
    
    public static var Teams = [Team]()
    
    public static var Channels = [Channel]()
    
    public static var Posts = [Post]()
    
    public static var ids = [String]()
    
    public static func add(_ object: AnyObject) {
        if let user = object as? User {
            Cache.ids.append(user.id)
            Cache.Users.append(user)
        } else if let team = object as? Team {
            Cache.ids.append(team.id)
            Cache.Teams.append(team)
        } else if let engagement = object as? Engagement {
            Cache.ids.append(engagement.id)
            Cache.Engagements.append(engagement)
        } else if let channel = object as? Channel {
            Cache.ids.append(channel.id)
            Cache.Channels.append(channel)
        } else if let post = object as? Post {
            Cache.ids.append(post.id)
            Cache.Posts.append(post)
        } else {
            Log.write(.warning, "Could not cache object")
        }
    }
    
    public static func update(_ object: AnyObject) {
        if let user = object as? User {
            let _ = Cache.retrieveUser(user.object)
        } else if let team = object as? Team {
            let _ = Cache.retrieveTeam(team.object)
        } else if let engagement = object as? Engagement {
            let _ = Cache.retrieveEngagement(engagement.object)
        } else if let channel = object as? Channel {
            let _ = Cache.retrieveChannel(channel.object)
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
        user.loadExtension(completion: nil)
        Cache.add(user)
        return user
    }
    
    public static func retrieveUser(_ id: String) -> User? {
        for user in Cache.Users {
            if user.id == id {
                return user
            }
        }
        let userQuery = PFUser.query()
        userQuery?.whereKey(PF_USER_OBJECTID, equalTo: id)
        do {
            let userObject = try userQuery?.getFirstObject()
            return Cache.retrieveUser(userObject as! PFUser)
        } catch _ {
            return nil
        }
    }
    
    public static func retrieveTeam(_ teamObject: PFObject) -> Team {
        var index = 0
        for team in Cache.Teams {
            if team.id == teamObject.objectId! {
                if team.updatedAt == teamObject.updatedAt {
                    return team
                } else {
                    let updatedTeam = Team(fromObject: teamObject)
                    Cache.Teams[index] = updatedTeam
                    return updatedTeam
                }
            }
            index += 1
        }
        Log.write(.status, "Caching Team with id \(teamObject.objectId!)")
        let team = Team(fromObject: teamObject)
        Cache.add(team)
        return team
    }
    
    public static func retrieveChannel(_ channelObject: PFObject) -> Channel {
        var index = 0
        for channel in Cache.Channels {
            if channel.id == channelObject.objectId! {
                if channel.updatedAt == channelObject.updatedAt {
                    return channel
                } else {
                    let updatedChannel = Channel(fromObject: channelObject)
                    Cache.Channels[index] = updatedChannel
                    return updatedChannel
                }
            }
            index += 1
        }
        Log.write(.status, "Caching Channel with id \(channelObject.objectId!)")
        let channel = Channel(fromObject: channelObject)
        Cache.add(channel)
        return channel
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
