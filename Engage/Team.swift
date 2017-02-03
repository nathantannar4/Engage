//
//  Team.swift
//  Engage
//
//  Created by Nathan Tannar on 1/31/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import NTUIKit

public class Team: Group {
    
    private static var _current: Team?
    
    
    // MARK: Public Functions
    
    public static func current() -> Team! {
        guard let team = self._current else {
            Log.write(.error, "The current engagement was nil")
            return nil
        }
        return team
    }
    
    public func undoModifications() {
        Team._current = Cache.retrieveTeam(self.object)
    }
}
