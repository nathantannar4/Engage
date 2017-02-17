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
    public var color: UIColor? {
        get {
            guard let colorHex = self.object.value(forKey: PF_ENGAGEMENTS_COLOR) as? String else {
                return Color.defaultNavbarTint
            }
            return UIColor(hexString: colorHex)
        }
    }
    public var colorHex: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_COLOR) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_COLOR] = newValue
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
        Engagement._current?.updateTeams()
        Engagement._current?.updateChannels()
        
        UserDefaults.standard.set(engagement.objectId, forKey: "currentEngagement")
        
        User.current().loadExtension {
            let pageContainer = NTPageViewController(viewControllers: [UINavigationController(rootViewController: EngageInfoViewController()),UINavigationController(rootViewController: EngagementHomeViewController()), UINavigationController(rootViewController: DiscoverEngagementsViewController())], initialIndex: 1)
            pageContainer.view.backgroundColor = UIColor.groupTableViewBackground
            let navContainer = NTNavigationContainer(centerView: TabBarController(), leftView: pageContainer, rightView: nil)
            navContainer.leftPanelWidth = 300
            UIApplication.shared.keyWindow?.rootViewController = navContainer
        }
    }
    
    public func didResign() {
        let index = User.current().engagementsIds.index(of: self.id)!
        User.current().engagements?.remove(at: index)
        User.current().save(completion: nil)
        
        UserDefaults.standard.set(nil, forKey: "currentEngagement")
        
        let navContainer = NTNavigationContainer(centerView: NTPageViewController(viewControllers: [UINavigationController(rootViewController: EngageInfoViewController()),UINavigationController(rootViewController: EngagementHomeViewController()), UINavigationController(rootViewController: DiscoverEngagementsViewController())], initialIndex: 1))
        UIApplication.shared.keyWindow?.rootViewController = navContainer
    }
    
    public class func didSelect(with engagement: Engagement) {
        Engagement._current = engagement
        Engagement._current?.updateTeams()
        Engagement._current?.updateChannels()
        
        UserDefaults.standard.set(engagement.id, forKey: "currentEngagement")
        
        User.current().loadExtension {
            let pageContainer = NTPageViewController(viewControllers: [UINavigationController(rootViewController: EngageInfoViewController()),UINavigationController(rootViewController: EngagementHomeViewController()), UINavigationController(rootViewController: DiscoverEngagementsViewController())], initialIndex: 1)
            pageContainer.view.backgroundColor = UIColor.groupTableViewBackground
            let navContainer = NTNavigationContainer(centerView: TabBarController(), leftView: pageContainer, rightView: nil)
            navContainer.leftPanelWidth = 300
            UIApplication.shared.keyWindow?.rootViewController = navContainer
        }
    }
    
    public func join(target: UIViewController) {
        
        if !self.password!.isEmpty {
            let actionSheetController: UIAlertController = UIAlertController(title: "Password", message: "This Engagement is password protected", preferredStyle: .alert)
            actionSheetController.view.tintColor = Color.defaultNavbarTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .destructive)
            actionSheetController.addAction(cancelAction)
            
            let nextAction: UIAlertAction = UIAlertAction(title: "Join", style: .default) { action -> Void in
                guard let password = actionSheetController.textFields![0].text else {
                    let toast = Toast(text: "Incorrect Password", button: nil, color: Color.darkGray, height: 44)
                    toast.show(duration: 1.5)
                    return
                }
                
                if password == self.password {
                    self.join(user: User.current(), completion: { (success) in
                        if success {
                            Engagement.didSelect(with: self)
                            User.current().engagements?.append(self.object)
                            User.current().save(completion: nil)
                        }
                    })
                } else {
                    let toast = Toast(text: "Incorrect Password", button: nil, color: Color.darkGray, height: 44)
                    toast.show(duration: 1.5)
                }
            }
            actionSheetController.addAction(nextAction)
            
            actionSheetController.addTextField { textField -> Void in
                textField.textColor = Color.darkGray
                textField.isSecureTextEntry = true
            }
            target.present(actionSheetController, animated: true, completion: nil)
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "", message: "Would you like to join \(self.name!)", preferredStyle: .alert)
            actionSheetController.view.tintColor = Color.defaultNavbarTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "No", style: .destructive)
            actionSheetController.addAction(cancelAction)
            
            let nextAction: UIAlertAction = UIAlertAction(title: "Yes", style: .default) { action -> Void in
                self.join(user: User.current(), completion: { (success) in
                    if success {
                        Engagement.didSelect(with: self)
                        User.current().engagements?.append(self.object)
                        User.current().save(completion: nil)
                    }
                })
            }
            actionSheetController.addAction(nextAction)
            
            target.present(actionSheetController, animated: true, completion: nil)
        }
    }
}
