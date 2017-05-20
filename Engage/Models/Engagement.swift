//
//  Engagement.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import NTComponents

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
            return self.object.value(forKey: PF_ENGAGEMENTS_TEAM_NAME) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_TEAM_NAME] = newValue
        }
    }
    public var color: UIColor? {
        get {
            guard let colorHex = self.object.value(forKey: PF_ENGAGEMENTS_COLOR) as? String else {
                return Color.Default.Tint.View
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
    
    // MARK: - Initialization
    
    convenience init() {
        self.init(PFObject(className: PF_ENGAGEMENTS_CLASS_NAME))
        self.members = [User.current()!.id]
        self.admins = [User.current()!.id]
        self.positions = []
        self.profileFields = []
    }

    // MARK: - Public Functions
    
    
    public static func current() -> Engagement? {
        guard let engagement = self._current else {
            Log.write(.error, "The current engagement was nil")
            return nil
        }
        return engagement
    }
    
    public class func didSelect(with engagement: Engagement) {
        Engagement._current = engagement
        
        
        User.current()?.loadExtension {
            
        }
    }
    
    public func didResign() {
        User.current()?.engagementRelations?.remove(self.object)
        User.current()?.save(completion: nil)
        

    }
}
