//
//  Engagement.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse

public class Engagement {
    
    static let sharedInstance = Engagement()
    
    var engagement: PFObject?
    var members = [String]()
    var admins = [String]()
    var info: String?
    var hidden: Bool?
    var name: String?
    var memberCount: Int?
    var password: String?
    var coverPhoto: UIImage?
    var fieldInput: String?
    var profileFields = [String]()
    var phone: String?
    var address: String?
    var email: String?
    var url: String?
    var positionsField: String?
    var positions = [String]()
    var subGroupName: String?
    var color: String?
    
  

}
