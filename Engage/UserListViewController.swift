//
//  ColleaguesViewController.swift
//  Count on Us
//
//  Created by Tannar, Nathan on 2016-08-06.
//  Copyright © 2016 NathanTannar. All rights reserved.
//


import UIKit
import NTUIKit
import Parse

class UserListViewController: NTSearchViewController, NTTableViewDataSource, NTTableViewDelegate {
    
    var positionIDs = [String]()
    var searchMembers = [String]()
    var adminMembers = [String]()
    
    var users = [User]()
    
    // MARK: - Initializers
    public convenience init(group: Group) {
        self.init()
        self.searchMembers = group.members!
        self.adminMembers = group.admins!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.dataSource = self
    }
    
    // MARK: User Actions
    
    override func updateResults() {
        self.users.removeAll()
        let query = PFUser.query()
        query?.limit = self.searchMembers.count
        query?.order(byAscending: PF_USER_FULLNAME)
        query?.whereKey(PF_USER_OBJECTID, containedIn: self.searchMembers)
        query?.whereKey(PF_USER_OBJECTID, notContainedIn: Cache.ids)
        query?.whereKey(PF_USER_FULLNAME_LOWER, contains: self.searchBar.text?.lowercased())
        query?.findObjectsInBackground(block: { (objects, error) in
            guard let users = objects as? [PFUser] else {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: "Could not fetch users", button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 1.0)
                return
            }
            for user in users {
                self.users.append(Cache.retrieveUser(user))
            }
            for id in Cache.ids {
                if self.searchMembers.contains(id) {
                    let user = Cache.retrieveUser(id)!
                    if let name = user.fullname?.lowercased() {
                        if let searchText = self.searchBar.text {
                            if searchText.isEmpty {
                                if !self.users.contains(where: { (user) -> Bool in
                                    return true
                                }) {
                                    self.users.append(user)
                                }
                            } else if name.contains(searchText.lowercased()) {
                                if !self.users.contains(where: { (user) -> Bool in
                                    return true
                                }) {
                                    self.users.append(user)
                                }
                            }
                        }
                    }
                }
            }
            self.reloadData()
        })
    }
    
    // MARK: NTTableViewDataSource
    
    func numberOfSections(in tableView: NTTableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if self.users.count == 0 {
            return NTTableViewCell()
        }
        if self.adminMembers.contains(self.users[indexPath.row].id) {
            let cell = NTDetailedProfileCell.initFromNib()
            cell.setImageViewDefaults()
            cell.image = self.users[indexPath.row].image
            cell.title = self.users[indexPath.row].fullname
            cell.subtitle = "Admin"
            cell.addBorder(edges: [.bottom, .top], colour: Color.darkGray, thickness: 0.3)
            return cell
        } else {
            let cell = NTProfileCell.initFromNib()
            cell.setDefaults()
            cell.setImageViewDefaults()
            cell.image = self.users[indexPath.row].image
            cell.title = self.users[indexPath.row].fullname
            cell.addBorder(edges: [.bottom, .top], colour: Color.darkGray, thickness: 0.3)
            return cell
        }
    }
    
    // MARK: NTTableViewDelegate
    
    func tableView(_ tableView: NTTableView, didSelectRowAt indexPath: IndexPath) {
        let profileVC = ProfileViewController(user: self.users[indexPath.row])
        self.present(UINavigationController(rootViewController: profileVC), animated: true, completion: nil)
    }
}
