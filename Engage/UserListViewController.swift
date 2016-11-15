//
//  ColleaguesViewController.swift
//  Count on Us
//
//  Created by Tannar, Nathan on 2016-08-06.
//  Copyright © 2016 NathanTannar. All rights reserved.
//


import UIKit
import Parse
import Former
import SVProgressHUD
import Material

class UserListViewController: FormViewController, UISearchBarDelegate {
    
    var positionIDs = [String]()
    var searchMembers = [String]()
    var adminMembers = [String]()
    var isSub = false
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        title = "Members"
        tableView.contentInset.top = 40
        
        self.searchBar.delegate = self
        self.searchBar.tintColor = MAIN_COLOR
        
        // Populate table
        SVProgressHUD.show(withStatus: "Loading Members")
        searchUsers(searchLower: "")
        prepareToolbar()
    }
    
    private func prepareToolbar() {
        guard let tc = toolbarController else {
            return
        }
        tc.toolbar.title = "Members"
        if isSub {
            tc.toolbar.detail = EngagementSubGroup.sharedInstance.name!
        } else {
            tc.toolbar.detail = Engagement.sharedInstance.name!
        }
        tc.toolbar.backgroundColor = MAIN_COLOR
        let backButton = IconButton(image: Icon.cm.arrowBack)
        backButton.tintColor = UIColor.white
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        appToolbarController.prepareToolbarCustom(left: [backButton], right: [])
    }
    
    @objc private func handleBackButton() {
        appToolbarController.pull(from: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    // MARK: Private
    
    func searchUsers(searchLower: String) {
        
        var members = [RowFormer]()
        let memberQuery = PFUser.query()
        memberQuery!.whereKey(PF_USER_OBJECTID, containedIn: searchMembers)
        memberQuery!.addAscendingOrder(PF_USER_FULLNAME)
        if searchLower != "" {
            memberQuery!.whereKey(PF_USER_FULLNAME_LOWER, contains: searchLower)
        }
        memberQuery!.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
            SVProgressHUD.dismiss()
            if error == nil {
                if users != nil {
                    for user in users! {
                        if self.positionIDs.contains(user.objectId!) {
                            members.append(LabelRowFormer<ProfileImageDetailCell>(instantiateType: .Nib(nibName: "ProfileImageDetailCell")) {
                                $0.accessoryType = .detailButton
                                $0.tintColor = MAIN_COLOR
                                $0.iconView.backgroundColor = MAIN_COLOR
                                $0.iconView.layer.borderWidth = 1
                                $0.iconView.layer.borderColor = MAIN_COLOR?.cgColor
                                $0.iconView.image = UIImage(named: "profile_blank")
                                $0.iconView.file = user[PF_USER_PICTURE] as? PFFile
                                $0.iconView.loadInBackground()
                                $0.titleLabel.textColor = UIColor.black
                                $0.detailLabel.textColor = UIColor.gray
                                let index = self.positionIDs.index(of: user.objectId!)
                                if self.isSub {
                                    $0.detailLabel.text = "\(EngagementSubGroup.sharedInstance.positions[index!])"
                                } else {
                                    $0.detailLabel.text = "\(Engagement.sharedInstance.positions[index!])"
                                }
                                if self.adminMembers.contains(user.objectId!) {
                                    $0.detailLabel.text = $0.detailLabel.text! + " (Admin)"
                                }
                                }.configure {
                                    $0.text = user[PF_USER_FULLNAME] as? String
                                    $0.rowHeight = 60
                                }.onSelected { [weak self] _ in
                                    self?.former.deselect(animated: true)
                                    let profileVC = PublicProfileViewController()
                                    profileVC.user = user
                                    let navVC = UINavigationController(rootViewController: profileVC)
                                    navVC.navigationBar.barTintColor = MAIN_COLOR!
                                    appToolbarController.show(navVC, sender: self)
                                })
                        } else if self.adminMembers.contains(user.objectId!) {
                            members.append(LabelRowFormer<ProfileImageDetailCell>(instantiateType: .Nib(nibName: "ProfileImageDetailCell")) {
                                $0.accessoryType = .detailButton
                                $0.tintColor = MAIN_COLOR
                                $0.iconView.backgroundColor = MAIN_COLOR
                                $0.iconView.layer.borderWidth = 1
                                $0.iconView.layer.borderColor = MAIN_COLOR?.cgColor
                                $0.iconView.image = UIImage(named: "profile_blank")
                                $0.iconView.file = user[PF_USER_PICTURE] as? PFFile
                                $0.iconView.loadInBackground()
                                $0.titleLabel.textColor = UIColor.black
                                $0.detailLabel.textColor = UIColor.gray
                                $0.detailLabel.text = "Admin"
                                }.configure {
                                    $0.text = user[PF_USER_FULLNAME] as? String
                                    $0.rowHeight = 60
                                }.onSelected { [weak self] _ in
                                    self?.former.deselect(animated: true)
                                    let profileVC = PublicProfileViewController()
                                    profileVC.user = user
                                    let navVC = UINavigationController(rootViewController: profileVC)
                                    navVC.navigationBar.barTintColor = MAIN_COLOR!
                                    appToolbarController.show(navVC, sender: self)
                                })
                        } else {
                            members.append(LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
                                $0.accessoryType = .detailButton
                                $0.tintColor = MAIN_COLOR
                                $0.iconView.backgroundColor = MAIN_COLOR
                                $0.iconView.layer.borderWidth = 1
                                $0.iconView.layer.borderColor = MAIN_COLOR?.cgColor
                                $0.iconView.image = UIImage(named: "profile_blank")
                                $0.iconView.file = user[PF_USER_PICTURE] as? PFFile
                                $0.iconView.loadInBackground()
                                $0.titleLabel.textColor = UIColor.black
                                }.configure {
                                    $0.text = user[PF_USER_FULLNAME] as? String
                                    $0.rowHeight = 60
                                }.onSelected { [weak self] _ in
                                    self?.former.deselect(animated: true)
                                    let profileVC = PublicProfileViewController()
                                    profileVC.user = user
                                    let navVC = UINavigationController(rootViewController: profileVC)
                                    navVC.navigationBar.barTintColor = MAIN_COLOR!
                                    appToolbarController.show(navVC, sender: self)
                                })
                        }
                    }
                    if searchLower != "" {
                        self.former.removeAll()
                        self.former.reload()
                    }
                    self.former.append(sectionFormer: SectionFormer(rowFormers: members))
                    self.former.reload()
                }
            }
        })
    }

    
    // MARK: - UISearchBar Delegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.characters.count > 0 {
            self.searchUsers(searchLower: searchText.lowercased())
        } else {
            former.removeAll()
            SVProgressHUD.show(withStatus: "Loading Members")
            self.searchUsers(searchLower: "")
            
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBarCancelled()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
    
    func searchBarCancelled() {
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        
        self.former.removeAll()
        former.reload()
        SVProgressHUD.show(withStatus: "Loading Members")
        self.searchUsers(searchLower: "")
        
    }
}
