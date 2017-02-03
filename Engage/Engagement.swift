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
            return self.name?.replacingOccurrences(of: " ", with: "_")
        }
    }
    public var profileFields: [String]? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_PROFILE_FIELDS) as? [String]
        }
        set {
            self.object[PF_ENGAGEMENTS_PROFILE_FIELDS] = newValue
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
    public var hidden: Bool? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_HIDDEN) as? Bool
        }
        set {
            self.object[PF_ENGAGEMENTS_HIDDEN] = newValue
        }
    }
    public var teams = [Team]()
    
    // MARK: Initialization
    
    public override init(fromObject object: PFObject) {
        super.init(fromObject: object)
        
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
    
    
    // MARK: Public Functions
    
    public static func current() -> Engagement! {
        guard let engagement = self._current else {
            Log.write(.error, "The current engagement was nil")
            return nil
        }
        return engagement
    }
    
    public func undoModifications() {
        Engagement._current = Cache.retrieveEngagement(self.object)
    }
    
    public class func didSelect(with engagement: PFObject) {
        self._current = Cache.retrieveEngagement(engagement)
        User.current().loadExtension()
        let navContainer = NTNavigationContainer(centerView: ActivityFeedViewController(), leftView: MenuViewController(), rightView: nil)
        navContainer.leftPanelWidth = 200
        UIApplication.shared.keyWindow?.rootViewController = navContainer
    }
}
