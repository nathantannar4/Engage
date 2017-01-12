//
//  Comment.swift
//  Engage
//
//  Created by Nathan Tannar on 1/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

public class Comment {
    
    public var user: User
    public var text: String
    public var date: Date

    public init(user: User, text: String, date: Date) {
        self.user = user
        self.text = text
        self.date = date
    }
    
    


}
