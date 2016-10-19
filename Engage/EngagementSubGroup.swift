//
//  EngagementSubGroup.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-27.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

final class EngagementSubGroup {
    
    static let sharedInstance = EngagementSubGroup()
    
    var subgroup: PFObject?
    var members = [String]()
    var admins = [String]()
    var info: String?
    var name: String?
    var coverPhoto: UIImage?
    var phone: String?
    var address: String?
    var email: String?
    var url: String?
    var positionsField: String?
    var positions = [String]()
    var isSponsor: Bool?
    
    func clear() {
        subgroup = nil
        members.removeAll()
        admins.removeAll()
        info = ""
        name = ""
        coverPhoto = nil
        phone = ""
        address = ""
        email = ""
        url = ""
        positionsField = ""
        positions.removeAll()
        isSponsor = false
    }
    
    func removeSpecialCharsFromString(text: String) -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890, ".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
    func save() {
        if EngagementSubGroup.sharedInstance.subgroup != nil {
            UIApplication.shared.beginIgnoringInteractionEvents()
            SVProgressHUD.show(withStatus: "Saving")
            EngagementSubGroup.sharedInstance.subgroup![PF_SUBGROUP_INFO] = EngagementSubGroup.sharedInstance.info
            EngagementSubGroup.sharedInstance.subgroup![PF_SUBGROUP_PHONE] = EngagementSubGroup.sharedInstance.phone!
            EngagementSubGroup.sharedInstance.subgroup![PF_SUBGROUP_ADDRESS] = EngagementSubGroup.sharedInstance.address!
            EngagementSubGroup.sharedInstance.subgroup![PF_SUBGROUP_EMAIL] = EngagementSubGroup.sharedInstance.email!
            EngagementSubGroup.sharedInstance.subgroup![PF_SUBGROUP_URL] = EngagementSubGroup.sharedInstance.url!
            EngagementSubGroup.sharedInstance.subgroup![PF_SUBGROUP_IS_SPONSOR] = EngagementSubGroup.sharedInstance.isSponsor!
            
            // Custom Positions
            var responses = EngagementSubGroup.sharedInstance.positionsField!
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
            EngagementSubGroup.sharedInstance.positions = fieldsArray
            EngagementSubGroup.sharedInstance.subgroup![PF_SUBGROUP_POSITIONS] = fieldsArray
            
            EngagementSubGroup.sharedInstance.subgroup!.saveInBackground { (success: Bool, error: Error?) in
                UIApplication.shared.endIgnoringInteractionEvents()
                if !success {
                    SVProgressHUD.showError(withStatus: "Error Saving")
                } else {
                    SVProgressHUD.showSuccess(withStatus: "Saved")
                }
            }
        } else {
            print("engagement is nil")
        }
    }
    
    func unpack() {
        if subgroup![PF_SUBGROUP_MEMBERS] != nil {
            members = subgroup![PF_SUBGROUP_MEMBERS] as! [String]
        } 
        if subgroup![PF_SUBGROUP_ADMINS] != nil {
            admins = subgroup![PF_SUBGROUP_ADMINS] as! [String]
        }
        if subgroup![PF_SUBGROUP_POSITIONS] != nil {
            positions = subgroup![PF_SUBGROUP_POSITIONS] as! [String]
        }
        info = subgroup![PF_SUBGROUP_INFO] as? String
        name = subgroup![PF_SUBGROUP_NAME] as? String
        phone = subgroup![PF_SUBGROUP_PHONE] as? String
        address = subgroup![PF_SUBGROUP_ADDRESS] as? String
        url = subgroup![PF_SUBGROUP_URL] as? String
        email = subgroup![PF_SUBGROUP_EMAIL] as? String
        if subgroup![PF_SUBGROUP_IS_SPONSOR] != nil {
            isSponsor = subgroup![PF_SUBGROUP_IS_SPONSOR] as? Bool
        } else {
            isSponsor = false
        }
        if subgroup![PF_SUBGROUP_COVER_PHOTO] != nil {
            (subgroup![PF_SUBGROUP_COVER_PHOTO] as? PFFile)?.getDataInBackground(block: { (data: Data?, error: Error?) in
                EngagementSubGroup.sharedInstance.coverPhoto = UIImage(data: data!)
            })
        }
    }
    
    func join(newUser: PFUser, completion: @escaping () -> Void) {
        members.append(newUser.objectId!)
        subgroup![PF_SUBGROUP_MEMBERS] = members
        subgroup!.saveInBackground { (success: Bool, error: Error?) in
            completion()
        }
    }
    
    func create(completion: @escaping () -> Void, isSponsor: Bool) {
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        SVProgressHUD.show(withStatus: "Verifying Creation")
        let subGroupQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
            subGroupQuery.whereKey("user", equalTo: PFUser.current()!)
            subGroupQuery.includeKey("subgroup")
            subGroupQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                UIApplication.shared.endIgnoringInteractionEvents()
                SVProgressHUD.dismiss()
                if error == nil {
                    if let user = users!.first {
                        let oldSubgroup = user["subgroup"] as? PFObject
                        print(oldSubgroup)
                        if oldSubgroup != nil {
                            
                            let oldAdmins = oldSubgroup![PF_SUBGROUP_ADMINS] as? [String]
                            let removeAdminIndex = oldAdmins!.index(of: PFUser.current()!.objectId!)
                            if removeAdminIndex != nil && oldAdmins!.count == 1 {
                                SVProgressHUD.showError(withStatus: "Cannot Resign")
                                Utilities.showBanner(title: "Cannot create a new sub group", subtitle: "You are the only admin of your current sub group.", duration: 1.0)
                            } else {
                                print("Not an admin of another group")
                                // User not an admin of another group
                                UIApplication.shared.beginIgnoringInteractionEvents()
                                SVProgressHUD.show(withStatus: "Setting Things Up")
                                    
                                    var oldAdmins = oldSubgroup![PF_SUBGROUP_ADMINS] as? [String]
                                    let removeAdminIndex = oldAdmins!.index(of: PFUser.current()!.objectId!)
                                    if removeAdminIndex != nil {
                                        oldAdmins?.remove(at: removeAdminIndex!)
                                        oldSubgroup![PF_SUBGROUP_ADMINS] = oldAdmins
                                        EngagementSubGroup.sharedInstance.admins = oldAdmins!
                                    } else {
                                        print("Admin index nil")
                                    }
                                    
                                    var oldMembers = oldSubgroup![PF_SUBGROUP_MEMBERS] as? [String]
                                    let removeMemberIndex = oldMembers!.index(of: PFUser.current()!.objectId!)
                                    if removeMemberIndex != nil {
                                        oldMembers?.remove(at: removeMemberIndex!)
                                        oldSubgroup![PF_SUBGROUP_MEMBERS] = oldMembers
                                        EngagementSubGroup.sharedInstance.members = oldMembers!
                                    } else {
                                        print("Member index nil")
                                    }
                                    oldSubgroup!.saveInBackground()
                                    
                                    
                                let newSubGroup = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_SUBGROUP_CLASS_NAME)")
                                    newSubGroup[PF_SUBGROUP_MEMBERS] = [PFUser.current()!.objectId!]
                                    newSubGroup[PF_SUBGROUP_ADMINS] = [PFUser.current()!.objectId!]
                                    newSubGroup[PF_SUBGROUP_INFO] = EngagementSubGroup.sharedInstance.info!
                                    newSubGroup[PF_SUBGROUP_NAME] = EngagementSubGroup.sharedInstance.name!
                                    newSubGroup[PF_SUBGROUP_LOWERCASE_NAME] = EngagementSubGroup.sharedInstance.name!.lowercased()
                                    newSubGroup[PF_SUBGROUP_PHONE] = ""
                                    newSubGroup[PF_SUBGROUP_ADDRESS] = ""
                                    newSubGroup[PF_SUBGROUP_EMAIL] = ""
                                    newSubGroup[PF_SUBGROUP_URL] = ""
                                    newSubGroup[PF_SUBGROUP_POSITIONS] = []
                                    newSubGroup[PF_SUBGROUP_IS_SPONSOR] = isSponsor
                                    
                                    newSubGroup.saveInBackground { (success: Bool, error: Error?) in
                                        UIApplication.shared.endIgnoringInteractionEvents()
                                        if success {
                                            if isSponsor {
                                                SVProgressHUD.showSuccess(withStatus: "Sponsor Created")
                                            } else {
                                                if Engagement.sharedInstance.subGroupName != "" {
                                                    SVProgressHUD.showSuccess(withStatus: "\(Engagement.sharedInstance.subGroupName!) Created")
                                                } else {
                                                    SVProgressHUD.showSuccess(withStatus: "Subgroup Created")
                                                }
                                            }
                                            
                                            user["subgroup"] = newSubGroup
                                            user.saveInBackground()
                                            completion()
                                            
                                        } else {
                                            SVProgressHUD.showError(withStatus: "Network Error")
                                            print(error)
                                        }
                                    }
                            }
                            
                        } else {
                            
                            print("Not in another group")
                            // User in another group
                            UIApplication.shared.beginIgnoringInteractionEvents()
                            SVProgressHUD.show(withStatus: "Setting Things Up")
                            let newSubGroup = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_SUBGROUP_CLASS_NAME)")
                                newSubGroup[PF_SUBGROUP_MEMBERS] = [PFUser.current()!.objectId!]
                                newSubGroup[PF_SUBGROUP_ADMINS] = [PFUser.current()!.objectId!]
                                newSubGroup[PF_SUBGROUP_INFO] = EngagementSubGroup.sharedInstance.info!
                                newSubGroup[PF_SUBGROUP_NAME] = EngagementSubGroup.sharedInstance.name!
                                newSubGroup[PF_SUBGROUP_LOWERCASE_NAME] = EngagementSubGroup.sharedInstance.name!.lowercased()
                                newSubGroup[PF_SUBGROUP_PHONE] = ""
                                newSubGroup[PF_SUBGROUP_ADDRESS] = ""
                                newSubGroup[PF_SUBGROUP_EMAIL] = ""
                                newSubGroup[PF_SUBGROUP_URL] = ""
                                newSubGroup[PF_SUBGROUP_POSITIONS] = []
                                
                                newSubGroup.saveInBackground { (success: Bool, error: Error?) in
                                    UIApplication.shared.endIgnoringInteractionEvents()
                                    SVProgressHUD.dismiss()
                                    if success {
                                        Utilities.showBanner(title: "Sub Group Created", subtitle: "You have been assigned as an admin.", duration: 1.0)
                                        
                                        user["subgroup"] = newSubGroup
                                        user.saveInBackground(block: { (success: Bool, error: Error?) in
                                            if error == nil {
                                                // Refresh view
                                                EngagementSubGroup.sharedInstance.subgroup = newSubGroup
                                                EngagementSubGroup.sharedInstance.unpack()
                                                completion()
                                            } else {
                                                Utilities.showBanner(title: "Error Joining Sub Group", subtitle: error.debugDescription, duration: 1.0)
                                            }
                                        })
                                    } else {
                                        Utilities.showBanner(title: "Error Creating Sub Group", subtitle: error.debugDescription, duration: 1.0)
                                    }
                                }
                        }
                    }
                }
                
        })
    }
}

