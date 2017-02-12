//
//  Engagement.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import NTUIKit

public class Engagement: Group {
    
    private static var _current: Engagement?
    
    public var queryName: String? {
        get {
            guard let name = self.name?.replacingOccurrences(of: " ", with: "_") else {
                return String()
            }
            return name
        }
    }
    public var altTeamName: String? {
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
    public var teams = [Team]()
    public var chats = [Channel]()
    public var chatNames: [String]? {
        get {
            var array = [String]()
            for chat in self.chats {
                guard let name = chat.name else {
                    return nil
                }
                array.append(name)
            }
            return array
        }
    }

    public var channels = [Channel]()
    public var myChannels: [Channel]! {
        get {
            return self.channels.filter({ (channel) -> Bool in
                guard let members = channel.members else {
                    return false
                }
                if members.contains(User.current().id) {
                    return true
                }
                return false
            })
        }
    }
    public var otherChannels: [Channel]! {
        get {
            return self.channels.filter({ (channel) -> Bool in
                guard let members = channel.members else {
                    return false
                }
                if !members.contains(User.current().id) {
                    return true
                }
                return false
            })
        }
    }
    public var channelNames: [String]? {
        get {
            var array = [String]()
            for channel in self.channels {
                guard let name = channel.name else {
                    return nil
                }
                array.append(name)
            }
            return array
        }
    }
    
    // MARK: Initialization
    
    public override init(fromObject object: PFObject) {
        super.init(fromObject: object)
        
        self.updateTeams()
        self.updateChannels()
    }
    
    
    // MARK: Public Functions
    
    public static func current() -> Engagement! {
        guard let engagement = self._current else {
            Log.write(.error, "The current engagement was nil")
            return nil
        }
        return engagement
    }
    
    public func updateTeams() {
        let teamQuery = PFQuery(className: self.queryName! + PF_SUBGROUP_CLASS_NAME)
        teamQuery.order(byAscending: PF_SUBGROUP_NAME)
        teamQuery.findObjectsInBackground { (objects, error) in
            guard let teams = objects else {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: "Could not fetch teams", button: nil, color: Color.darkGray, height: 44)
                toast.show(duration: 2.0)
                return
            }
            for team in teams {
                self.teams.append(Cache.retrieveTeam(team))
            }
        }

    }
    
    public func updateChannels() {
        let chatQuery = PFQuery(className: self.queryName! + PF_CHANNEL_CLASS_NAME)
        chatQuery.whereKey(PF_CHANNEL_MEMBERS, contains: User.current().id)
        chatQuery.whereKey(PF_CHANNEL_PRIVATE, equalTo: true)
        chatQuery.order(byAscending: PF_CHANNEL_UPDATED_AT)
        chatQuery.findObjectsInBackground { (objects, error) in
            guard let chats = objects else {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: "Could not fetch private messages", button: nil, color: Color.darkGray, height: 44)
                toast.show(duration: 2.0)
                return
            }
            self.chats.removeAll()
            for chat in chats {
                self.chats.append(Cache.retrieveChannel(chat))
            }
        }
        
        let channelQuery = PFQuery(className: self.queryName! + PF_CHANNEL_CLASS_NAME)
        channelQuery.whereKey(PF_CHANNEL_PRIVATE, equalTo: false)
        channelQuery.order(byAscending: PF_CHANNEL_UPDATED_AT)
        channelQuery.findObjectsInBackground { (objects, error) in
            guard let channels = objects else {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: "Could not fetch channels", button: nil, color: Color.darkGray, height: 44)
                toast.show(duration: 2.0)
                return
            }
            self.channels.removeAll()
            for channel in channels {
                self.channels.append(Cache.retrieveChannel(channel))
            }
        }
    }
    
    public func undoModifications() {
        Engagement._current = Cache.retrieveEngagement(self.object)
    }
    
    public class func didSelect(with engagement: PFObject) {
        Engagement._current = Cache.retrieveEngagement(engagement)
        User.current().loadExtension {
            let navContainer = NTNavigationContainer(centerView: TabBarController())
            navContainer.leftPanelWidth = 200
            UIApplication.shared.keyWindow?.rootViewController = navContainer
        }
    }
}
