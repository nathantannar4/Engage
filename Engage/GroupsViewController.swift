//
//  GroupViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 9/30/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD


class GroupsViewController: UITableViewController, UIAlertViewDelegate {
    
    var groups: [PFObject]! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl!.addTarget(self, action: #selector(GroupsViewController.loadGroups), for: .valueChanged)
        self.navigationItem.title = "Open Chats"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Plus"), style: .plain, target: self, action: #selector(newButtonPressed))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadGroups()
    }
    
    func loadGroups() {
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_GROUPS_CLASS_NAME)")
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?)
            -> Void in
            if error == nil {
                self.groups.removeAll()
                self.groups.append(contentsOf: objects as [PFObject]!)
                self.tableView.reloadData()
            } else {
                print("Network error")
                print(error)
                SVProgressHUD.showError(withStatus: "Network Error")
            }
            self.refreshControl!.endRefreshing()
        }
    }
    
    func newButtonPressed(_ sender: AnyObject) {
        self.actionNew()
    }
    
    func actionNew() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Please enter a name for your group", message: "", preferredStyle: .alert)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Do some stuff
        }
        actionSheetController.addAction(cancelAction)
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "Create", style: .default) { action -> Void in
            //Do some other stuff
            let textField = actionSheetController.textFields![0]
            if let text = textField.text {
                if text.length > 0 {
                    var groupName = text.lowercased()
                    groupName.insert("#", at: groupName.startIndex)
                    let object = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_GROUPS_CLASS_NAME)")
                    object[PF_GROUPS_NAME] = text
                    object.saveInBackground(block: { (success: Bool, error: Error?) -> Void in
                        if success {
                            self.loadGroups()
                            SVProgressHUD.showSuccess(withStatus: "Group Chat Created")
                        } else {
                            print("Network error")
                            print(error)
                            SVProgressHUD.showError(withStatus: "Network Error")
                        }
                    })
                }
            }
        }
        actionSheetController.addAction(nextAction)
        //Add a text field
        actionSheetController.addTextField { textField -> Void in
            //TextField configuration
            //textField.textColor = UIColor(red: 153.0/255, green:62.0/255.0, blue:123.0/255, alpha: 1)
        }
        actionSheetController.popoverPresentationController?.sourceView = self.view
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.accessoryType = .disclosureIndicator
        
        let group = self.groups[indexPath.row]
        cell.textLabel?.text = group[PF_GROUPS_NAME] as? String
        
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_CHAT_CLASS_NAME)")
        query.whereKey(PF_CHAT_GROUPID, equalTo: group.objectId!)
        query.order(byDescending: PF_CHAT_CREATEDAT)
        query.limit = 1000
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                let chat = objects![0] 
                let date = NSDate()
                let seconds = date.timeIntervalSince(chat.createdAt!)
                let elapsed = Utilities.timeElapsed(seconds: seconds);
                let countString = (objects!.count > 1) ? "\(objects!.count) messages" : "\(objects!.count) message"
                cell.detailTextLabel?.text = "\(countString) \(elapsed)"
            } else {
                cell.detailTextLabel?.text = "0 messages"
            }
            cell.detailTextLabel?.textColor = UIColor.lightGray
        }
        
        return cell
    }
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let group = self.groups[indexPath.row]
        let groupId = group.objectId! as String
        
        Messages.createMessageItem(user: PFUser.current()!, groupId: groupId, description: group[PF_GROUPS_NAME] as! String)
        
        let chatVC = ChatViewController()
        chatVC.hidesBottomBarWhenPushed = true
        chatVC.groupId = groupId
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
}

extension String {
    var length: Int {
        return (self as NSString).length
    }
}
