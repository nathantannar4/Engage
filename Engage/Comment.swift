//
//  Comment.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-20.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse

final class Comment {
    
    static var new = Comment()
    
    var post: PFObject?
    var user: PFUser?
    var comment: String?
    var commentDate: NSDate?
    
    func clear() {
        Comment.new.post = nil
        Comment.new.user = nil
        Comment.new.comment = ""
    }

}

class CommentObject {
    private var comment: String!
    private var username: String!
    private var userId: String!
    private var date: Date!
    
    func initialize(commentString: String, usernnameString: String, userIdString: String, commentDate: Date) {
        comment = commentString
        username = usernnameString
        userId = userIdString
        date = commentDate
    }
    
    func getComment() -> String {
        return comment
    }
    
    func getUsername() -> String {
        return username
    }
    
    func getUserId() -> String {
        return userId
    }
    
    func getDateString() -> String {
        return Utilities.dateToString(time: date as NSDate)
    }
}
