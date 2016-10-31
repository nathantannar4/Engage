//
//  Profile.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

final class Profile {
    
    static let sharedInstance = Profile()
    
    var user: PFUser?
    var image: UIImage?
    var name: String?
    var phoneNumber: String?
    var email: String?
    var password: String?
    var engagements = [String]()
    var userExtended: PFObject?
    var customFields = [String]()
    var blockedUsers = [String]()
    
    
    func clear() {
        user = nil
        image = nil
        name = ""
        phoneNumber = ""
        email = ""
        password = ""
        engagements.removeAll()
        customFields.removeAll()
        userExtended = nil
        blockedUsers.removeAll()
    }
    
    func loadUser() {
        if let user = user {
            let userImageFile = user[PF_USER_PICTURE] as? PFFile
            if userImageFile != nil {
                userImageFile!.getDataInBackground {
                    (imageData: Data?, error: Error?) -> Void in
                    if error == nil {
                        if let imageData = imageData {
                            self.image = UIImage(data:imageData)
                        }
                    }
                }
            }
            
            name = user[PF_USER_FULLNAME] as? String
            if (user[PF_USER_PHONE] != nil) {
                phoneNumber = user[PF_USER_PHONE] as? String
            } else {
                phoneNumber = ""
            }
            var currentGroupIDs = [String]()
            if PFUser.current()?.value(forKey: PF_USER_ENGAGEMENTS) != nil {
                for group in (PFUser.current()?.value(forKey: PF_USER_ENGAGEMENTS) as! [PFObject]) {
                    currentGroupIDs.append(group.objectId!)
                }
            }
            engagements = currentGroupIDs
            
            if user[PF_USER_BLOCKED] != nil {
                blockedUsers = user[PF_USER_BLOCKED] as! [String]
            } else {
                blockedUsers = []
            }
            
            if Engagement.sharedInstance.engagement != nil {
                let userExtendedQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                userExtendedQuery.whereKey("user", equalTo: PFUser.current()!)
                userExtendedQuery.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        if objects?.count == 0 {
                            let newUserExtension = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                            newUserExtension["user"] = PFUser.current()
                            newUserExtension.saveInBackground()
                            for _ in Engagement.sharedInstance.profileFields {
                                Profile.sharedInstance.customFields.append("")
                            }
                        } else {
                            let object = objects?.first
                            for field in Engagement.sharedInstance.profileFields {
                                if object![field.lowercased()] != nil {
                                    Profile.sharedInstance.customFields.append(object![field.lowercased()] as! String)
                                } else {
                                    Profile.sharedInstance.customFields.append("")
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    func saveUser() {
        let fullName = name
        if fullName!.characters.count > 0 {
            UIApplication.shared.beginIgnoringInteractionEvents()
            SVProgressHUD.show(withStatus: "Saving")
            
            let user = Profile.sharedInstance.user!
            user[PF_USER_FULLNAME] = fullName!
            user[PF_USER_FULLNAME_LOWER] = fullName!.lowercased()
            user[PF_USER_PHONE] = Profile.sharedInstance.phoneNumber
            user[PF_USER_BLOCKED] = Profile.sharedInstance.blockedUsers
            user.saveInBackground(block: { (succeeded: Bool, error: Error?) -> Void in
                UIApplication.shared.endIgnoringInteractionEvents()
                
                if error == nil {
                    let userExtended = Profile.sharedInstance.userExtended
                    if userExtended != nil {
                        var index = 0
                        for field in Engagement.sharedInstance.profileFields {
                            userExtended![field.lowercased()] = Profile.sharedInstance.customFields[index]
                            index += 1
                        }
                        userExtended!.saveInBackground(block: { (succeeded: Bool, error: Error?) in
                            if error != nil {
                                SVProgressHUD.showError(withStatus: "Network Error")
                            } else {
                                SVProgressHUD.dismiss()
                            }
                        })
                    }
                } else {
                    print("Network error")
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            })
        } else {
            SVProgressHUD.showError(withStatus: "Blank Name")
        }
    }
}
