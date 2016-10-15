//
//  Event.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-08.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

final class Event {
    
    static let sharedInstance = Event()
    
    var object: PFObject?
    var organizers = [PFUser]()
    var inviteTo = [PFUser]()
    var title: String?
    var location: String?
    var info: String?
    var url: String?
    var start: NSDate?
    var end: NSDate?
    var allDay = false
    var lat: Double?
    var long: Double?
    
    func clear() {
        organizers.removeAll()
        inviteTo.removeAll()
        title = ""
        location = ""
        info = ""
        url = ""
        start = NSDate()
        end = NSDate()
        allDay = false
        lat = 0.0
        long = 0.0
    }
    
    func create(completion: @escaping () -> Void) {
        if title != "" {
            UIApplication.shared.beginIgnoringInteractionEvents()
            SVProgressHUD.show(withStatus: "Creating Event")
            let newEvent = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_EVENTS_CLASS_NAME)")
            newEvent[PF_EVENTS_TITLE] = Event.sharedInstance.title!
            newEvent[PF_EVENTS_LOCATION] = Event.sharedInstance.location!
            newEvent[PF_EVENTS_INFO] = Event.sharedInstance.info!
            newEvent[PF_EVENTS_URL] = Event.sharedInstance.url!
            newEvent[PF_EVENTS_START] = Event.sharedInstance.start!
            newEvent[PF_EVENTS_END] = Event.sharedInstance.end!
            newEvent[PF_EVENTS_ALL_DAY] = Event.sharedInstance.allDay
            newEvent[PF_EVENTS_ORGANIZER] = PFUser.current()!
            newEvent[PF_EVENTS_INVITE_TO] = Event.sharedInstance.inviteTo
            newEvent[PF_EVENTS_CONFIRMED] = []
            newEvent[PF_EVENTS_MAYBE] = []
            newEvent[PF_EVENTS_LATITUDE] = Event.sharedInstance.lat!
            newEvent[PF_EVENTS_LONGITUDE] = Event.sharedInstance.long!
            
            newEvent.saveInBackground { (success: Bool, error: Error?) in
                UIApplication.shared.endIgnoringInteractionEvents()
                if success {
                    completion()
                    SVProgressHUD.showSuccess(withStatus: "Event Created")
                } else {
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            }
            Event.sharedInstance.clear()
        } else {
            // Event name empty
            SVProgressHUD.showError(withStatus: "Invalid Name")
        }
    }
    
    func unpack() {
        title = object![PF_EVENTS_TITLE] as? String
        location = object![PF_EVENTS_LOCATION] as? String
        info = object![PF_EVENTS_INFO] as? String
        url = object![PF_EVENTS_URL] as? String
        start = object![PF_EVENTS_START] as? NSDate
        end = object![PF_EVENTS_END] as? NSDate
        allDay = object![PF_EVENTS_ALL_DAY] as! Bool
        lat = object![PF_EVENTS_LATITUDE] as? Double
        long = object![PF_EVENTS_LONGITUDE] as? Double
    }
    
    func save() {
        object![PF_EVENTS_TITLE] = Event.sharedInstance.title!
        object![PF_EVENTS_LOCATION] = Event.sharedInstance.location!
        object![PF_EVENTS_INFO] = Event.sharedInstance.info!
        object![PF_EVENTS_URL] = Event.sharedInstance.url!
        object![PF_EVENTS_START] = Event.sharedInstance.start!
        object![PF_EVENTS_END] = Event.sharedInstance.end!
        object![PF_EVENTS_ALL_DAY] = Event.sharedInstance.allDay
        object![PF_EVENTS_LONGITUDE] = Event.sharedInstance.long!
        object![PF_EVENTS_LATITUDE] = Event.sharedInstance.lat!
        UIApplication.shared.beginIgnoringInteractionEvents()
        SVProgressHUD.show(withStatus: "Updating Event")
        Event.sharedInstance.object!.saveInBackground { (success: Bool, error: Error?) in
            UIApplication.shared.endIgnoringInteractionEvents()
            if success {
                SVProgressHUD.showSuccess(withStatus: "Event Updated")
            } else {
                SVProgressHUD.showError(withStatus: "Network Error")
            }
        }
    }
}
