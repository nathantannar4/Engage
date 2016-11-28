//
//  MessagesViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 9/30/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import Parse
import Material

class MessagesViewController: UITableViewController, UIActionSheetDelegate, SelectSingleViewControllerDelegate, SelectMultipleViewControllerDelegate, MenuDelegate  {
    
    var messages = [PFObject]()
    internal var addButton: FabButton!
    internal var singleButtonItem: MenuItem!
    internal var groupButtonItem: MenuItem!
    
    @IBOutlet var composeButton: UIBarButtonItem!
    @IBOutlet var emptyView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Messages"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.cm.menu, style: .plain, target: self, action: #selector(leftDrawerButtonPressed))
        
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.cleanup), name: NSNotification.Name(rawValue: NOTIFICATION_USER_LOGGED_OUT), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.loadMessages), name: NSNotification.Name(rawValue: "reloadMessages"), object: nil)
        
        let groupButton = UIBarButtonItem(image: UIImage(named: "Conference"), style: .plain, target: self, action: #selector(showGroups))
        let composeButton = UIBarButtonItem(image: Icon.cm.add, style: .plain, target: self, action: #selector(compose))
        
        navigationItem.rightBarButtonItems = [composeButton, groupButton]
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(MessagesViewController.loadMessages), for: UIControlEvents.valueChanged)
        self.tableView?.addSubview(self.refreshControl!)
        
        self.emptyView?.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadMessages()
    }
    
    func showGroups() {
        self.navigationController?.pushViewController(GroupsViewController(), animated: true)
    }
    
    
    // MARK: - Backend methods
    
    func loadMessages() {
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_MESSAGES_CLASS_NAME)")
        let blockedUserQuery = PFUser.query()
        blockedUserQuery?.whereKey(PF_USER_OBJECTID, containedIn: Profile.sharedInstance.blockedUsers)
        query.whereKey(PF_MESSAGES_LASTUSER, doesNotMatch: blockedUserQuery!)
        query.whereKey(PF_MESSAGES_USER, equalTo: PFUser.current()!)
        query.includeKey(PF_MESSAGES_LASTUSER)
        query.order(byDescending: PF_MESSAGES_UPDATEDACTION)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                self.messages.removeAll(keepingCapacity: false)
                self.messages += objects as [PFObject]!
                self.tableView.reloadData()
                self.updateEmptyView()
                self.updateTabCounter()
            } else {
                print("Network error")
            }
            self.refreshControl!.endRefreshing()
        }
    }
    
    // MARK: - Helper methods
    
    func updateEmptyView() {
        self.emptyView?.isHidden = (self.messages.count != 0)
    }
    
    
    func updateTabCounter() {
        var total = 0
        for message in self.messages {
            total += (message[PF_MESSAGES_COUNTER]! as AnyObject).integerValue
        }
        UIApplication.shared.applicationIconBadgeNumber = total
    }
 
    
    // MARK: - User actions
    
    func openChat(groupId: String, title: String) {
        let messageVC = ChatViewController()
        messageVC.groupId = groupId
        messageVC.groupName = title
        self.navigationController?.pushViewController(messageVC, animated: true)
    }
    
    func cleanup() {
        self.messages.removeAll(keepingCapacity: false)
        self.tableView.reloadData()
        self.updateTabCounter()
        self.updateEmptyView()
    }

    // MARK: - SelectSingleDelegate
    
    func didSelectSingleUser(user user2: PFUser) {
        let user1 = PFUser.current()!
        let groupId = Messages.startPrivateChat(user1: user1, user2: user2)
        self.openChat(groupId: groupId, title: user2.value(forKey: PF_USER_FULLNAME) as! String)
    }
    
    // MARK: - SelectMultipleDelegate
    
    func didSelectMultipleUsers(selectedUsers: [PFUser]!) {
        let groupId = Messages.startMultipleChat(users: selectedUsers)
        self.openChat(groupId: groupId, title: "Group Chat")
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messagesCell") as! MessagesCell
        cell.bindData(message: self.messages[indexPath.row])
        cell.accessoryType = .detailButton
        cell.tintColor = MAIN_COLOR
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Delete?", message: "", preferredStyle: .alert)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Do some stuff
        }
        actionSheetController.addAction(cancelAction)
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { action -> Void in
            Messages.deleteMessageItem(message: self.messages[indexPath.row])
            self.messages.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
            self.updateEmptyView()
            self.updateTabCounter()
        }
        actionSheetController.addAction(nextAction)
        //Add a text field
        
        actionSheetController.popoverPresentationController?.sourceView = self.view
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let message = self.messages[indexPath.row] as PFObject
        self.openChat(groupId: message[PF_MESSAGES_GROUPID] as! String, title: message[PF_MESSAGES_DESCRIPTION] as! String)
    }
    
    func compose() {
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        let single: UIAlertAction = UIAlertAction(title: "Single Recipient", style: .default)
        { action -> Void in
            let vc = SelectSingleViewController()
            vc.delegate = self
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.barTintColor = MAIN_COLOR!
            self.present(navVC, animated: true, completion: nil)
        }
        actionSheetController.addAction(single)
        let multiple: UIAlertAction = UIAlertAction(title: "Multiple Recipients", style: .default)
        { action -> Void in
            let vc = SelectMultipleViewController()
            vc.delegate = self
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.barTintColor = MAIN_COLOR!
            self.present(navVC, animated: true, completion: nil)
        }
        actionSheetController.addAction(multiple)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func leftDrawerButtonPressed() {
        self.evo_drawerController?.toggleDrawerSide(.left, animated: true, completion: nil)
    }
}
