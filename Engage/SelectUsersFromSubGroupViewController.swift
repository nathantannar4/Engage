//
//  SelectUsersFromSubGroup.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Material
import SVProgressHUD

protocol SelectUsersFromSubGroupDelegate {
    func didSelectMultipleUsers(selectedUsers: [PFUser]!)
}

class SelectUsersFromSubGroupViewController: UITableViewController {
    
    var users = [PFUser]()
    var selection = [String]()
    var delegate: SelectUsersFromSubGroupDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.cm.close, style: .plain, target: self, action: #selector(cancelButtonPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.cm.check, style: .plain, target: self, action: #selector(doneButtonPressed))
        
        self.loadUsers()
    }
    
    // MARK: - Backend Functions
    private func loadUsers() {
        let memberQuery = PFUser.query()
        memberQuery!.whereKey(PF_USER_OBJECTID, containedIn: EngagementSubGroup.sharedInstance.members)
        memberQuery!.whereKey(PF_USER_OBJECTID, notContainedIn: EngagementSubGroup.sharedInstance.admins)
        memberQuery!.whereKey(PF_USER_OBJECTID, notEqualTo: PFUser.current()!.objectId!)
        memberQuery!.addAscendingOrder(PF_USER_FULLNAME)
        memberQuery!.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
            if error == nil {
                if users != nil {
                    self.users.removeAll(keepingCapacity: false)
                    for user in users! {
                        self.users.append(user as! PFUser)
                    }
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    // MARK: - User Actions
    func cancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonPressed(_ sender: AnyObject) {
        if self.selection.count == 0 {
            SVProgressHUD.showError(withStatus: "No Users Selected")
        } else {
            self.dismiss(animated: true, completion: { () -> Void in
                var selectedUsers = [PFUser]()
                for user in self.users {
                    if self.selection.contains(user.objectId!) {
                        selectedUsers.append(user)
                    }
                }
                selectedUsers.append(PFUser.current()!)
                self.delegate.didSelectMultipleUsers(selectedUsers: selectedUsers)
            })
        }
    }
    
    // MARK: - UIScrollView Functions
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        SVProgressHUD.dismiss()
    }
    
    // MARK: - UITableView Functions
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        let user = self.users[indexPath.row]
        cell.textLabel?.text = user[PF_USER_FULLNAME] as? String
        
        let selected = self.selection.contains(user.objectId!)
        cell.accessoryType = selected ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let user = self.users[indexPath.row]
        let selected = self.selection.contains(user.objectId!)
        if selected {
            if let index = self.selection.index(of: user.objectId!) {
                self.selection.remove(at: index)
            }
        } else {
            self.selection.append(user.objectId!)
        }
        
        self.tableView.reloadData()
    }
}
