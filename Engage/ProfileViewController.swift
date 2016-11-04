//
//  ProfileViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD

class ProfileViewController: FormViewController  {
    
    var firstLoad = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI and Table Properties
        let editButton   = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonPressed))
        navigationItem.rightBarButtonItem = editButton
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 60
        
        Profile.sharedInstance.user = PFUser.current()
        Profile.sharedInstance.loadUser()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.revealViewController().frontViewPosition.rawValue == 4 {
            self.revealViewController().revealToggle(self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if revealViewController() != nil {
            let menuButton = UIBarButtonItem()
            menuButton.image = UIImage(named: "ic_menu_black_24dp")
            menuButton.target = revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.navigationItem.leftBarButtonItem = menuButton
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            tableView.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        former.removeAll()
        configure()
    }
    
    private lazy var zeroRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {_ in
            }.configure {
                $0.rowHeight = 0
        }
    }()

    
    private func configure() {
        let headerRow = CustomRowFormer<ProfileHeaderCell>(instantiateType: .Nib(nibName: "ProfileHeaderCell")) {
            $0.iconView.backgroundColor = MAIN_COLOR
            $0.backgroundLabel.backgroundColor = MAIN_COLOR
            $0.nameLabel.text = Profile.sharedInstance.user![PF_USER_FULLNAME] as? String
            $0.schoolLabel.text = ""
            $0.titleLabel.text = ""
            $0.iconView.image = UIImage(named: "profile_blank")
            $0.iconView.file = Profile.sharedInstance.user![PF_USER_PICTURE] as? PFFile
            $0.iconView.loadInBackground()
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected({ (cell: CustomRowFormer<ProfileHeaderCell>) in
                if cell.cell.iconView.image != nil {
                    let agrume = Agrume(image: cell.cell.iconView.image!)
                    agrume.showFrom(self)
                }
        })
        
        let phoneRow = CustomRowFormer<ProfileLabelCell>(instantiateType: .Nib(nibName: "ProfileLabelCell")) {
            $0.titleLabel.text = "Phone"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.displayLabel.text = Profile.sharedInstance.user![PF_USER_PHONE] as? String
            }.onSelected { _ in
                self.former.deselect(animated: true)
        }
        let emailRow = CustomRowFormer<ProfileLabelCell>(instantiateType: .Nib(nibName: "ProfileLabelCell")) {
            $0.titleLabel.text = "Email"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.displayLabel.text = Profile.sharedInstance.user![PF_USER_EMAIL] as? String
            }.onSelected { _ in
                self.former.deselect(animated: true)
        }
        
        var customRow = [CustomRowFormer<ProfileLabelCell>]()
        
        if Engagement.sharedInstance.engagement != nil {
            
            // Query to find current data
            let customQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
            customQuery.whereKey("user", equalTo: PFUser.current()!)
            customQuery.includeKey("subgroup")
            customQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                if error == nil {
                    if let user = users!.first {
                        
                        let subgroup = user["subgroup"] as? PFObject
                        if subgroup != nil {
                            headerRow.cellUpdate({
                                $0.schoolLabel.text = subgroup![PF_SUBGROUP_NAME] as? String
                            })
                        }
                        
                        Profile.sharedInstance.userExtended = user
                        Profile.sharedInstance.customFields.removeAll()
                        
                        for field in Engagement.sharedInstance.profileFields {
                            
                            if user[field.lowercased()] != nil {
                                Profile.sharedInstance.customFields.append(user[field.lowercased()] as! String)
                            } else {
                                Profile.sharedInstance.customFields.append("")
                            }
                            
                            customRow.append(CustomRowFormer<ProfileLabelCell>(instantiateType: .Nib(nibName: "ProfileLabelCell")) {
                                $0.titleLabel.text = field
                                $0.titleLabel.textColor = MAIN_COLOR
                                $0.displayLabel.text = user[field.lowercased()] as? String
                                $0.titleLabel.font = .boldSystemFont(ofSize: 15)
                                $0.selectionStyle = .none
                                })
                        }
                        
                        self.former.insertUpdate(rowFormers: customRow, below: emailRow, rowAnimation: .fade)
                    }
                } else {
                    print("No User Extension")
                }
            })
        } else {
            print("engagement nil")
        }

        
        // Create SectionFormers
        let profileSection = SectionFormer(rowFormer: headerRow, phoneRow, emailRow)
        profileSection.add(rowFormers: customRow)
        
        // Add sections to table
        self.former.append(sectionFormer: profileSection)
        self.former.reload()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - User actions
    
    func editButtonPressed(sender: UIBarButtonItem) {
        self.navigationController?.pushViewController(EditProfileViewController(), animated: true)
    }
}
