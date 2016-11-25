//
//  DelegatesViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 9/25/16.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import Material
import SVProgressHUD

class DelegatesViewController: FormViewController  {
    
    var query: String!
    var isSchool: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI and Table Properties
        tableView.contentInset.top = 10
        tableView.contentInset.bottom = 10
        title = query
        
        loadDelegates()
    }
    
    private func loadDelegates() {
        
        var members = [RowFormer]()
        let memberQuery = PFQuery(className: "WESST_WEC_Delegates")
        if !self.isSchool {
            memberQuery.whereKey("competition", equalTo: query)
        }
        memberQuery.includeKey("user")
        memberQuery.addAscendingOrder("school")
        memberQuery.limit = 300
        memberQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                if objects != nil {
                    for object in objects! {
                        members.append(CustomRowFormer<DelegateCell>(instantiateType: .Nib(nibName: "DelegateCellLeft")) {
                            $0.accessoryType = .detailButton
                            $0.iconView.backgroundColor = MAIN_COLOR
                            $0.iconView.layer.borderWidth = 1
                            $0.iconView.layer.borderColor = MAIN_COLOR?.cgColor
                            $0.iconView.image = UIImage(named: "profile_blank")
                            $0.iconView.file = (object["user"] as! PFUser).object(forKey: PF_USER_PICTURE) as? PFFile
                            $0.iconView.loadInBackground()
                            $0.nameLabel.text = (object["user"] as! PFUser).value(forKey: PF_USER_FULLNAME) as? String
                            if self.isSchool == true {
                                $0.schoolLabel.text = object["competition"] as? String
                            } else {
                                $0.schoolLabel.text = object["school"] as? String
                            }
                            if object["head"] as? Bool == true {
                                $0.titleLabel.text = "Head Delegate"
                            } else {
                                $0.titleLabel.text = "\(object["year"] as! String) Year"
                            }
                            $0.nameLabel.textAlignment = .left
                            $0.schoolLabel.textAlignment = .left
                            $0.titleLabel.textAlignment = .left
                            $0.nameLabel.font = RobotoFont.medium(with: 22)
                            $0.schoolLabel.font = RobotoFont.regular(with: 17)
                            $0.titleLabel.font = RobotoFont.regular(with: 17)
                            }.configure {
                                $0.rowHeight = UITableViewAutomaticDimension
                            }.onSelected { [weak self] _ in
                                self?.former.deselect(animated: true)
                                if Engagement.sharedInstance.admins.contains(Profile.sharedInstance.user!.objectId!) {
                                    let profileVC = DelegateProfileViewController()
                                    profileVC.user = object["user"] as! PFUser
                                    profileVC.delegateInfo = object
                                    let navVC = UINavigationController(rootViewController: profileVC)
                                    navVC.navigationBar.barTintColor = MAIN_COLOR
                                    self?.present(navVC, animated: true, completion: nil)
                                } else {
                                    let profileVC = PublicProfileViewController()
                                    profileVC.user = object["user"] as! PFUser
                                    let navVC = UINavigationController(rootViewController: profileVC)
                                    navVC.navigationBar.barTintColor = MAIN_COLOR
                                    self?.present(navVC, animated: true, completion: nil)
                                }
                        })
                    }
                    self.former.append(sectionFormer: SectionFormer(rowFormers: members))
                    self.former.reload()
                }
            }
        }
    }
}
