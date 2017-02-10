//
//  SelectSingleViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse

protocol UserSelectionDelegate {
    func didMakeSelection(ofUsers users: [User])
}

class UserSelectionViewController: UserListViewController {
    
    var selectionDelegate: UserSelectionDelegate!
    var allowMultipleSelection = true
    var selectedUsers = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completedSelection(sender:)))
    }
    
    override func updateResults() {
        let query = PFUser.query()
        query?.limit = 1000
        query?.order(byAscending: PF_USER_FULLNAME)
        query?.whereKey(PF_USER_OBJECTID, containedIn: self.searchMembers)
        query?.whereKey(PF_USER_FULLNAME_LOWER, contains: self.searchBar.text?.lowercased())
        query?.findObjectsInBackground(block: { (objects, error) in
            guard let users = objects as? [PFUser] else {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: "Could not fetch users", button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 1.0)
                return
            }
            self.users.removeAll()
            for user in users {
                if user.objectId! != User.current().id {
                    self.users.append(Cache.retrieveUser(user))
                }
            }
            self.reloadData()
        })
    }
    
    func completedSelection(sender: UIButton) {
        var users = [User]()
        for id in self.selectedUsers {
            users.append(Cache.retrieveUser(id)!)
        }
        self.dismiss(animated: true, completion: {
            self.selectionDelegate.didMakeSelection(ofUsers: users)
        })
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if self.selectedUsers.contains(self.users[indexPath.row].id) {
            cell.accessoryType = .checkmark
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        if self.allowMultipleSelection {
            guard let cell = self.tableView.cellForRow(at: indexPath) else {
                return
            }
            cell.tintColor = Color.defaultNavbarTint
            if self.selectedUsers.contains(self.users[indexPath.row].id) {
                if let index = self.selectedUsers.index(of: self.users[indexPath.row].id) {
                    self.selectedUsers.remove(at: index)
                    cell.accessoryType = .none
                }
            } else {
                self.selectedUsers.append(self.users[indexPath.row].id)
                cell.accessoryType = .checkmark
            }
        } else {
            self.dismiss(animated: true, completion: {
                self.selectionDelegate.didMakeSelection(ofUsers: [self.users[indexPath.row]])
            })
        }
    }
}


