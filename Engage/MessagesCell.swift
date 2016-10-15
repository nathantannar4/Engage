//
//  MessagesCell.swift
//  Engage
//
//  Created by Nathan Tannar on 9/30/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class MessagesCell: UITableViewCell {
    
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var lastMessageLabel: UILabel!
    @IBOutlet var timeElapsedLabel: UILabel!
    @IBOutlet var counterLabel: UILabel!
    
    func bindData(message: PFObject) {
        
        descriptionLabel.text = message[PF_MESSAGES_DESCRIPTION] as? String
        lastMessageLabel.text = message[PF_MESSAGES_LASTMESSAGE] as? String
        
        let date = message[PF_MESSAGES_UPDATEDACTION] as! NSDate
        var interval = NSDate().minutes(after: date as Date!)
        
        var dateString = ""
        if interval < 60 {
            if interval == 0 {
                dateString = "Now"
            }
            else if interval <= 1 {
                dateString = "1 minutes ago"
            }
            else {
                dateString = "\(interval) minutes ago"
            }
        }
        else {
            interval = NSDate().hours(after: date as Date!)
            if interval < 24 {
                if interval <= 1 {
                    dateString = "1 hour ago"
                }
                else {
                    dateString = "\(interval) hours ago"
                }
            }
            else {
                interval = NSDate().days(after: date as Date!)
                if interval <= 1 {
                    dateString = "1 day ago"
                }
                else {
                    dateString = "\(interval) days ago"
                }
            }
        }
        timeElapsedLabel.text = dateString
        
        let counter = (message[PF_MESSAGES_COUNTER]! as AnyObject).integerValue
        counterLabel.text = (counter == 0) ? "" : "\(counter) new"
    }
    
}
