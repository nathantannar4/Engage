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

        self.delegate = self
        self.dataSource = self
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completedSelection(sender:)))
    }
    
    func completedSelection(sender: UIButton) {
        var users = [User]()
        for id in self.selectedUsers {
            users.append(Cache.retrieveUser(id)!)
        }
        self.selectionDelegate.didMakeSelection(ofUsers: users)
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if self.selectedUsers.contains(self.users[indexPath.row].id) {
            cell.accessoryType = .checkmark
        }
        return cell
    }
    
    override func tableView(_ tableView: NTTableView, didSelectRowAt indexPath: IndexPath) {
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
            self.selectionDelegate.didMakeSelection(ofUsers: [self.users[indexPath.row]])
            self.dismiss(animated: true, completion: nil)
        }
    }
}


