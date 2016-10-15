//
//  Conference.swift
//  WESST
//
//  Created by Tannar, Nathan on 2016-09-12.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

final class Conference {
    
    static let sharedInstance = Conference()
    
    var conference: PFObject?
    var delegates = [String]()
    var organizers = [String]()
    var info: String?
    var name: String?
    var password: String?
    var coverPhoto: UIImage?
    var hostSchool: String?
    var year: String?
    var location: String?
    var url: String?
    var positionsField: String?
    var positions = [String]()
    var sponsors = [String]()
    var start: NSDate?
    var end: NSDate?
    
    func clear() {
        conference = nil
        delegates.removeAll()
        organizers.removeAll()
        info = ""
        name = ""
        password = ""
        coverPhoto = nil
        hostSchool = ""
        year = ""
        location = ""
        url = ""
        positionsField = ""
        positions.removeAll()
        sponsors.removeAll()
        start = NSDate()
        end = NSDate()
    }
    
    func unpack() {
        if conference![PF_CONFERENCE_DELEGATES] != nil {
            delegates = conference![PF_CONFERENCE_DELEGATES] as! [String]
        }
        if conference![PF_CONFERENCE_ORGANIZERS] != nil {
            organizers = conference![PF_CONFERENCE_ORGANIZERS] as! [String]
        }
        info = conference![PF_CONFERENCE_INFO] as? String
        name = conference![PF_CONFERENCE_NAME] as? String
        password = conference![PF_CONFERENCE_PASSWORD] as? String
        year = conference![PF_CONFERENCE_YEAR] as? String
        hostSchool = conference![PF_CONFERENCE_HOST_SCHOOL] as? String
        location = conference![PF_CONFERENCE_LOCATION] as? String
        url = conference![PF_CONFERENCE_URL] as? String
        if conference![PF_CONFERENCE_POSITIONS] != nil {
            positions = conference![PF_CONFERENCE_POSITIONS] as! [String]
        }
        if conference![PF_CONFERENCE_SPONSORS] != nil {
            sponsors = conference![PF_CONFERENCE_SPONSORS] as! [String]
        }
        if conference![PF_CONFERENCE_COVER_PHOTO] != nil {
            (conference![PF_CONFERENCE_COVER_PHOTO] as? PFFile)?.getDataInBackground(block: { (data: Data?, error: Error?) in
                Conference.sharedInstance.coverPhoto = UIImage(data: data!)
            })
        }
        start = conference![PF_CONFERENCE_START] as? NSDate
        end = conference![PF_CONFERENCE_END] as? NSDate
    }
    
    func create() {
        let newConference = PFObject(className: "WESST_Conferences")
        newConference[PF_CONFERENCE_DELEGATES] = []
        newConference[PF_CONFERENCE_ORGANIZERS] = []
        newConference[PF_CONFERENCE_INFO] = ""
        newConference[PF_CONFERENCE_NAME] = name
        newConference[PF_CONFERENCE_PASSWORD] = ""
        newConference[PF_CONFERENCE_HOST_SCHOOL] = ""
        newConference[PF_CONFERENCE_YEAR] = ""
        newConference[PF_CONFERENCE_LOCATION] = ""
        newConference[PF_CONFERENCE_URL] = ""
        newConference[PF_CONFERENCE_POSITIONS] = []
        newConference[PF_CONFERENCE_SPONSORS] = []
        newConference[PF_CONFERENCE_START] = NSDate()
        newConference[PF_CONFERENCE_END] = NSDate()
        conference = newConference
        newConference.saveInBackground()
    }
    
    func removeSpecialCharsFromString(text: String) -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890, ".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    func save() {
        conference![PF_CONFERENCE_DELEGATES] = delegates
        conference![PF_CONFERENCE_ORGANIZERS] = organizers
        conference![PF_CONFERENCE_INFO] = info
        conference![PF_CONFERENCE_PASSWORD] = password
        conference![PF_CONFERENCE_YEAR] = year
        conference![PF_CONFERENCE_HOST_SCHOOL] = hostSchool
        conference![PF_CONFERENCE_LOCATION] = location
        conference![PF_CONFERENCE_URL] = url
        conference![PF_CONFERENCE_SPONSORS] = sponsors
        conference![PF_CONFERENCE_START] = start
        conference![PF_CONFERENCE_END] = end
        
        // Custom Positions
        var responses = Conference.sharedInstance.positionsField!
        var fieldsArray = [String]()
        while responses.contains(",") {
            while responses[responses.startIndex] == " " {
                // Remove leading spaces
                responses.remove(at: responses.startIndex)
            }
            // Find comma
            let index = responses.characters.index(of: ",")
            // Create string to comma
            let originalString = responses.substring(to: index!)
            let stringToAdd = self.removeSpecialCharsFromString(text: responses.substring(to: index!))
            print("Adding: \(stringToAdd)")
            if stringToAdd != "" {
                // Ignore double commas example: one,,three
                fieldsArray.append(stringToAdd)
            }
            responses = responses.replacingOccurrences(of: originalString + ",", with: "")
            print(responses)
        }
        if responses != "" {
            // Ignore double commas example: one,,three
            fieldsArray.append(self.removeSpecialCharsFromString(text: responses))
        }
        positions = fieldsArray
        conference![PF_CONFERENCE_POSITIONS] = positions
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        SVProgressHUD.show(withStatus: "Saving")
            Conference.sharedInstance.conference!.saveInBackground { (success: Bool, error: Error?) in
                UIApplication.shared.endIgnoringInteractionEvents()
                SVProgressHUD.dismiss()
                if !success {
                    let banner = Banner(title: "Error Saving Conference", subtitle: error as! String?, image: nil, backgroundColor: MAIN_COLOR!)
                    banner.dismissesOnTap = true
                    banner.show(duration: 2.0)
                }
            }
    }
}
