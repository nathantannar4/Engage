//
//  UserSelectionViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import NTComponents
import Parse

protocol UserSelectionDelegate {
    func didMakeSelection(ofUsers users: [User])
}

class UserSelectionViewController: UserListViewController {
    
    var selectionDelegate: UserSelectionDelegate!
    var allowMultipleSelection = true
    var selectedUsers = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completedSelection(sender:)))
    }
    
    func completedSelection(sender: UIButton) {
        self.dismiss(animated: true, completion: {
            self.selectionDelegate.didMakeSelection(ofUsers: self.selectedUsers)
        })
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if self.selectedUsers.contains(where: { (user) -> Bool in
            return (self.users[indexPath.row].id == user.id)
        }) {
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
            cell.tintColor = Color.Default.Tint.View
            if self.selectedUsers.contains(where: { (user) -> Bool in
                return (self.users[indexPath.row].id == user.id)
            }) {
                self.selectedUsers.append(self.users[indexPath.row])
                cell.accessoryType = .none
            } else {
                self.selectedUsers.append(self.users[indexPath.row])
                cell.accessoryType = .checkmark
            }
        } else {
            self.dismiss(animated: true, completion: {
                self.selectionDelegate.didMakeSelection(ofUsers: [self.users[indexPath.row]])
            })
        }
    }
}


