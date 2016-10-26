//
//  Engagement.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-11.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

final class Engagement {
    
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
    var sponsor: Bool?
    
    func clear() {
        engagement = nil
        members.removeAll()
        admins.removeAll()
        info = ""
        hidden = false
        name = ""
        memberCount = 0
        password = ""
        fieldInput = ""
        coverPhoto = nil
        profileFields.removeAll()
        phone = ""
        address = ""
        email = ""
        url = ""
        positionsField = ""
        positions.removeAll()
        subGroupName = ""
        color = UIColor.flatSkyBlueColorDark().hexValue()
        sponsor = false
    }
    
    func removeSpecialCharsFromString(text: String) -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890, ".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    
    func save() {
        if Engagement.sharedInstance.engagement != nil {
            UIApplication.shared.beginIgnoringInteractionEvents()
            SVProgressHUD.show(withStatus: "Saving")
                Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_INFO] = Engagement.sharedInstance.info
                Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_PHONE] = Engagement.sharedInstance.phone!
                Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_ADDRESS] = Engagement.sharedInstance.address!
                Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_EMAIL] = Engagement.sharedInstance.email!
                Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_URL] = Engagement.sharedInstance.url!
                Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_HIDDEN] = Engagement.sharedInstance.hidden!
                Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_PASSWORD] = Engagement.sharedInstance.password!
                Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_SUBGROUP_NAME] = Engagement.sharedInstance.subGroupName!
                Engagement.sharedInstance.engagement![PF_ENGAGEMENT_COLOR] = Engagement.sharedInstance.color!
                Engagement.sharedInstance.engagement![PF_ENGAGEMENT_SPONSOR] = Engagement.sharedInstance.sponsor!
            
            
                // Custom Profile Fields
                var responses = Engagement.sharedInstance.fieldInput!
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
                    let stringToAdd = self.removeSpecialCharsFromString(text: responses.substring(to: index!).capitalized).replacingOccurrences(of: " ", with: "")
                    print("Adding: \(stringToAdd)")
                    if stringToAdd != "" {
                        // Ignore double commas example: one,,three
                        fieldsArray.append(stringToAdd)
                    }
                    responses = responses.replacingOccurrences(of: originalString + ",", with: "")
                    print(responses)
                }
            responses = responses.replacingOccurrences(of: " ", with: "")
                if responses != "" {
                    // Ignore double commas example: one,,three
                    fieldsArray.append(self.removeSpecialCharsFromString(text: responses.capitalized))
                }
                Engagement.sharedInstance.profileFields = fieldsArray
                Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_PROFILE_FIELDS] = fieldsArray
                
                // Custom Positions
                responses = Engagement.sharedInstance.positionsField!
                fieldsArray.removeAll()
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
                Engagement.sharedInstance.positions = fieldsArray
                Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_POSITIONS] = fieldsArray

                
                Engagement.sharedInstance.engagement!.saveInBackground { (success: Bool, error: Error?) in
                    UIApplication.shared.endIgnoringInteractionEvents()
                    if !success {
                        SVProgressHUD.showError(withStatus: "Error Saving")
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "Saved")
                        MAIN_COLOR = UIColor.init(hexString: Engagement.sharedInstance.color!)
                    }
                }
        } else {
            print("engagement is nil")
        }
    }
    
    func unpack() {
        
        if engagement![PF_ENGAGEMENTS_MEMBERS] != nil {
            members = engagement![PF_ENGAGEMENTS_MEMBERS] as! [String]
        }
        if engagement![PF_ENGAGEMENTS_ADMINS] != nil {
            admins = engagement![PF_ENGAGEMENTS_ADMINS] as! [String]
        }
        if engagement![PF_ENGAGEMENTS_POSITIONS] != nil {
            positions = engagement![PF_ENGAGEMENTS_POSITIONS] as! [String]
        }
        info = engagement![PF_ENGAGEMENTS_INFO] as? String
        name = engagement![PF_ENGAGEMENTS_NAME] as? String
        password = engagement![PF_ENGAGEMENTS_PASSWORD] as? String
        memberCount = engagement![PF_ENGAGEMENTS_MEMBER_COUNT] as? Int
        hidden = engagement![PF_ENGAGEMENTS_HIDDEN] as? Bool
        profileFields = engagement![PF_ENGAGEMENTS_PROFILE_FIELDS] as! [String]
        phone = engagement![PF_ENGAGEMENTS_PHONE] as? String
        address = engagement![PF_ENGAGEMENTS_ADDRESS] as? String
        url = engagement![PF_ENGAGEMENTS_URL] as? String
        email = engagement![PF_ENGAGEMENTS_EMAIL] as? String
        subGroupName = engagement![PF_ENGAGEMENTS_SUBGROUP_NAME] as? String
        color = engagement![PF_ENGAGEMENT_COLOR] as? String
        sponsor = engagement![PF_ENGAGEMENT_SPONSOR] as? Bool
        if color != nil {
            MAIN_COLOR = UIColor.init(hexString: color)
        } else {
            color = UIColor.flatSkyBlueColorDark().hexValue()
        }
        if engagement![PF_ENGAGEMENTS_COVER_PHOTO] != nil {
            (engagement![PF_ENGAGEMENTS_COVER_PHOTO] as? PFFile)?.getDataInBackground(block: { (data: Data?, error: Error?) in
                Engagement.sharedInstance.coverPhoto = UIImage(data: data! as Data)
            })
        }
    }
    
    func join(newUser: PFUser) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        members.append(newUser.objectId!)
        memberCount = memberCount! + 1
        engagement![PF_ENGAGEMENTS_MEMBERS] = members
        engagement![PF_ENGAGEMENTS_MEMBER_COUNT] = memberCount
        engagement!.saveInBackground { (success: Bool, error: Error?) in
            UIApplication.shared.endIgnoringInteractionEvents()
            if success {
                let user = PFUser.current()!
                if PFUser.current()?.value(forKey: PF_USER_ENGAGEMENTS) != nil {
                    var currentEngagements = PFUser.current()?.value(forKey: PF_USER_ENGAGEMENTS) as? [PFObject]
                    currentEngagements?.append(self.engagement!)
                    user[PF_USER_ENGAGEMENTS] = currentEngagements
                } else {
                    user[PF_USER_ENGAGEMENTS] = [self.engagement!]
                }
                user.saveInBackground()
                
                SVProgressHUD.showSuccess(withStatus: "Joined \(Engagement.sharedInstance.name!)")
                
                Profile.sharedInstance.engagements.append(self.engagement!.objectId!)
                
                let userExtensionQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                userExtensionQuery.whereKey("user", equalTo: PFUser.current()!)
                userExtensionQuery.findObjectsInBackground { (users: [PFObject]?, error: Error?) in
                    if error == nil {
                        if users == nil || users?.count == 0 {
                            let newUserExtension = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                            newUserExtension["user"] = PFUser.current()!
                            newUserExtension.saveInBackground()
                        }
                    }
                }

            } else {
                SVProgressHUD.showError(withStatus: "Network Error")
            }
        }
    }
    
    func leave(oldUser: PFUser, completion: Void) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        SVProgressHUD.show(withStatus: "Leaving")
        let index = members.index(of: oldUser.objectId!)
        members.remove(at: index!)
        memberCount = memberCount! - 1
        engagement![PF_ENGAGEMENTS_MEMBERS] = members
        engagement![PF_ENGAGEMENTS_MEMBER_COUNT] = memberCount
        engagement!.saveInBackground { (success: Bool, error: Error?) in
            UIApplication.shared.endIgnoringInteractionEvents()
            if success {
                let index = Profile.sharedInstance.engagements.index(of: Engagement.sharedInstance.engagement!.objectId!)
                let user = PFUser.current()!
                var engagements = user[PF_USER_ENGAGEMENTS] as? [PFObject]
                engagements?.remove(at: index!)
                user[PF_USER_ENGAGEMENTS] = engagements
                user.saveInBackground()
                Profile.sharedInstance.engagements.remove(at: index!)
                
                SVProgressHUD.showSuccess(withStatus: "You left \(Engagement.sharedInstance.name!)")
                completion
                
                // Delete created objects
                
                let postQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Posts")
                postQuery.whereKey(PF_POST_USER, equalTo: PFUser.current()!)
                postQuery.findObjectsInBackground(block: { (posts: [PFObject]?, error: Error?) in
                    if error == nil {
                        for post in posts! {
                            post.deleteInBackground()
                        }
                    } else {
                        print(error)
                        Utilities.showBanner(title: "Network Error", subtitle: "Your posts were not deleted from the group.", duration: 1.5)
                    }
                })
                let eventQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Events")
                eventQuery.whereKey(PF_EVENTS_ORGANIZER, equalTo: PFUser.current()!)
                eventQuery.findObjectsInBackground(block: { (events: [PFObject]?, error: Error?) in
                    if error == nil {
                        for event in events! {
                            event.deleteInBackground()
                        }
                    } else {
                        print(error)
                        Utilities.showBanner(title: "Network Error", subtitle: "Your events were not deleted from the group.", duration: 1.5)
                    }
                })
                let messageQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Messages")
                messageQuery.whereKey("groupId", contains: PFUser.current()!.objectId!)
                messageQuery.findObjectsInBackground(block: { (messages: [PFObject]?, error: Error?) in
                    if error == nil {
                        for message in messages! {
                            message.deleteInBackground()
                        }
                    } else {
                        print(error)
                        Utilities.showBanner(title: "Network Error", subtitle: "Your messages were not deleted from the group.", duration: 1.5)
                    }
                })
                let subGroupQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                subGroupQuery.whereKey("user", equalTo: PFUser.current()!)
                subGroupQuery.includeKey("subgroup")
                subGroupQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                    let userExtensionQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                    userExtensionQuery.whereKey("user", equalTo: PFUser.current()!)
                    userExtensionQuery.findObjectsInBackground { (users: [PFObject]?, error: Error?) in
                        if error == nil {
                            if let user = users?.first {
                                user.deleteInBackground()
                            }
                        } else {
                            print(error)
                        }
                    }
                    if error == nil {
                        if let user = users!.first {
                            let oldSubgroup = user["subgroup"] as? PFObject
                            if oldSubgroup != nil {
                                
                                var oldMembers = oldSubgroup![PF_SUBGROUP_MEMBERS] as? [String]
                                let removeMemberIndex = oldMembers!.index(of: PFUser.current()!.objectId!)
                                if removeMemberIndex != nil {
                                    oldMembers?.remove(at: removeMemberIndex!)
                                    oldSubgroup![PF_SUBGROUP_MEMBERS] = oldMembers
                                }
                                
                                var oldAdmins = oldSubgroup![PF_SUBGROUP_ADMINS] as? [String]
                                let removeAdminIndex = oldAdmins!.index(of: PFUser.current()!.objectId!)
                                if removeAdminIndex != nil {
                                    oldAdmins?.remove(at: removeAdminIndex!)
                                    oldSubgroup![PF_SUBGROUP_ADMINS] = oldAdmins
                                    if oldAdmins?.count == 0 {
                                        oldSubgroup!.deleteInBackground()
                                    } else {
                                        oldSubgroup!.saveInBackground()
                                    }
                                } else {
                                    oldSubgroup!.saveInBackground()
                                }
                                
                                
                            } else {
                                print("Old sub group was nil")
                            }
                        }
                    }
                })
            } else {
                UIApplication.shared.endIgnoringInteractionEvents()
                SVProgressHUD.showError(withStatus: "Network Error")
                print(error)
            }
        }
    }
    
    func delete(completion: Void) {
    
        // Delete All Data
        UIApplication.shared.beginIgnoringInteractionEvents()
        SVProgressHUD.show(withStatus: "Deleting \(Engagement.sharedInstance.name!)")
        Engagement.sharedInstance.engagement?.deleteInBackground(block: { (success: Bool, error: Error?) in
            if success {
                
                let userExtensionQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                userExtensionQuery.findObjectsInBackground { (users: [PFObject]?, error: Error?) in
                    if error == nil {
                        for user in users! {
                            user.deleteInBackground()
                        }
                        SVProgressHUD.showSuccess(withStatus: "Deleted User Info")
                    } else {
                        print(error)
                    }
                    
                    let postQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Posts")
                    postQuery.findObjectsInBackground(block: { (posts: [PFObject]?, error: Error?) in
                        if error == nil {
                            for post in posts! {
                                post.deleteInBackground()
                            }
                            SVProgressHUD.showSuccess(withStatus: "Deleted Posts")
                        } else {
                            print(error)
                        }
                        
                        let eventQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Events")
                        eventQuery.findObjectsInBackground(block: { (events: [PFObject]?, error: Error?) in
                            if error == nil {
                                for event in events! {
                                    event.deleteInBackground()
                                }
                                SVProgressHUD.showSuccess(withStatus: "Deleted Events")
                            } else {
                                print(error)
                            }
                            
                            let groupsQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Groups")
                            groupsQuery.findObjectsInBackground(block: { (groups: [PFObject]?, error: Error?) in
                                if error == nil {
                                    for group in groups! {
                                        group.deleteInBackground()
                                    }
                                } else {
                                    print(error)
                                }
                            })
                            
                            let messageQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Messages")
                            messageQuery.findObjectsInBackground(block: { (messages: [PFObject]?, error: Error?) in
                                if error == nil {
                                    for message in messages! {
                                        message.deleteInBackground()
                                    }
                                    SVProgressHUD.showSuccess(withStatus: "Deleted Messages")
                                } else {
                                    print(error)
                                }
                                
                                let subGroupQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                                subGroupQuery.findObjectsInBackground(block: { (subgroups: [PFObject]?, error: Error?) in
                                    UIApplication.shared.endIgnoringInteractionEvents()
                                    if error == nil {
                                        for subgroup in subgroups! {
                                            subgroup.deleteInBackground()
                                        }
                                        SVProgressHUD.showSuccess(withStatus: "Deleted Subgroups")
                                        completion
                                    } else {
                                        print(error)
                                    }
                                })
                            })
                        })
                    })
                }
            } else {
                UIApplication.shared.endIgnoringInteractionEvents()
                SVProgressHUD.showError(withStatus: "Network Error")
                print(error)
            }
        })
    }
    
    func create(completion: @escaping () -> Void) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        SVProgressHUD.show(withStatus: "Setting Things Up")
            let newEngagement = PFObject(className: PF_ENGAGEMENTS_CLASS_NAME)
            newEngagement[PF_ENGAGEMENTS_MEMBERS] = [PFUser.current()!.objectId!]
            newEngagement[PF_ENGAGEMENTS_ADMINS] = [PFUser.current()!.objectId!]
            newEngagement[PF_ENGAGEMENTS_INFO] = Engagement.sharedInstance.info!
            newEngagement[PF_ENGAGEMENTS_HIDDEN] = Engagement.sharedInstance.hidden!
            newEngagement[PF_ENGAGEMENTS_NAME] = Engagement.sharedInstance.name!
            newEngagement[PF_ENGAGEMENTS_LOWERCASE_NAME] = Engagement.sharedInstance.name!.lowercased()
            newEngagement[PF_ENGAGEMENTS_MEMBER_COUNT] = 1
            newEngagement[PF_ENGAGEMENTS_PASSWORD] = Engagement.sharedInstance.password!
            newEngagement[PF_ENGAGEMENTS_PROFILE_FIELDS] = []
            newEngagement[PF_ENGAGEMENTS_PHONE] = ""
            newEngagement[PF_ENGAGEMENTS_ADDRESS] = ""
            newEngagement[PF_ENGAGEMENTS_EMAIL] = ""
            newEngagement[PF_ENGAGEMENTS_URL] = ""
            newEngagement[PF_ENGAGEMENTS_POSITIONS] = []
            newEngagement[PF_ENGAGEMENTS_SUBGROUP_NAME] = ""
            newEngagement[PF_ENGAGEMENT_COLOR] = UIColor.flatSkyBlueColorDark().hexValue()
            newEngagement[PF_ENGAGEMENT_SPONSOR] = false
            
            if Engagement.sharedInstance.coverPhoto != nil {
                let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(Engagement.sharedInstance.coverPhoto!, 0.6)!)
                pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                    if error != nil {
                        print("Network error")
                    }
                }
                newEngagement[PF_ENGAGEMENTS_COVER_PHOTO] = pictureFile
            }
            
            newEngagement.saveInBackground { (success: Bool, error: Error?) in
                UIApplication.shared.endIgnoringInteractionEvents()
                if success {
                    let user = PFUser.current()!
                    if PFUser.current()?.value(forKey: PF_USER_ENGAGEMENTS) != nil {
                        var currentEngagements = PFUser.current()?.value(forKey: PF_USER_ENGAGEMENTS) as? [PFObject]
                        currentEngagements?.append(newEngagement)
                        user[PF_USER_ENGAGEMENTS] = currentEngagements
                    } else {
                        user[PF_USER_ENGAGEMENTS] = [newEngagement]
                    }
                    user.saveInBackground()
                    Profile.sharedInstance.engagements.append(newEngagement.objectId!)
                    Engagement.sharedInstance.engagement = newEngagement
                    Engagement.sharedInstance.unpack()
                    
                    SVProgressHUD.showSuccess(withStatus: "Success")
                    completion()
                    
                } else {
                    Utilities.showBanner(title: "Error Creating Group", subtitle: error.debugDescription, duration: 1.5)
                    SVProgressHUD.dismiss()
                }
            }
    }
}
