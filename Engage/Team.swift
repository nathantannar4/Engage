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
    
    // MARK: Public Functions

    
    public func undoModifications() {
        self.object = Cache.retrieveTeam(self.object).object
        self.image = Cache.retrieveTeam(self.object).image
    }
}
