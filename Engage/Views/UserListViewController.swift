//
//  UserListViewController.swift
//  Count on Us
//
//  Created by Tannar, Nathan on 2016-08-06.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import NTComponents
import Parse

class UserListViewController: NTSearchViewController {
    
    var group: Group!
    
    var users = [User]()
    
    // MARK: - Initializers
    public convenience init(group: Group) {
        self.init()
        self.group = group
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorStyle = .singleLine
    }
    
    // MARK: User Actions
    
    override func updateResults() {
        let query = group.members.query()
        query.limit = 1000
        query.order(byAscending: PF_USER_FULLNAME)
        query.whereKey(PF_USER_FULLNAME_LOWER, contains: self.searchBar.text?.lowercased())
        query.findObjectsInBackground(block: { (objects, error) in
            guard let users = objects as? [PFUser] else {
                Log.write(.error, error.debugDescription)
                NTPing.genericErrorMessage()
                return
            }
            self.users.removeAll()
            for user in users {
                self.users.append(User(user))
            }
            self.reloadData()
        })
    }
    
    // MARK: NTTableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        cell.textLabel?.text = self.users[indexPath.row].fullname
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
//        if self.adminMembers.contains(self.users[indexPath.row].id) {
//            cell.detailTextLabel?.text = "Admin"
//            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
//            cell.detailTextLabel?.textColor = Color.darkGray
//        }
        cell.imageView?.image = self.users[indexPath.row].image?.toSquare()
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.layer.cornerRadius = 5
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = Color.Default.Tint.View.cgColor
        cell.imageView?.layer.masksToBounds = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let profileVC = UserViewController(self.users[indexPath.row])
        //self.present(UINavigationController(rootViewController: profileVC), animated: true, completion: nil)
    }
}