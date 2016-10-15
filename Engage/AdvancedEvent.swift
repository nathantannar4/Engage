//
//  AdvancedEvent.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-13.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

final class AdvancedEvent {
    
    static let sharedInstance = AdvancedEvent()
    
    var organizers = [PFUser]()
    var inviteTo = [PFUser]()
    var title: String?
    var location: String?
    var info: String?
    var url: String?
    var start: NSDate?
    var end: NSDate?
    var formTitle: String?
    
    func clear() {
        organizers.removeAll()
        inviteTo.removeAll()
        title = ""
        location = ""
        info = ""
        url = ""
        start = NSDate()
        end = NSDate()
        formTitle = ""
    }
    
    func create(completion: @escaping () -> Void) {
        let newEvent = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_EVENTS_CLASS_NAME)")
        newEvent.saveInBackground { (success: Bool, error: Error?) in
            if success {
                SVProgressHUD.showSuccess(withStatus: "Event Created")
                completion()
            } else {
                SVProgressHUD.showError(withStatus: "Network Error")
            }
        }
        clear()
    }
}
