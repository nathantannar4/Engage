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
        
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.cleanup), name: NSNotification.Name(rawValue: NOTIFICATION_USER_LOGGED_OUT), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.loadMessages), name: NSNotification.Name(rawValue: "reloadMessages"), object: nil)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(MessagesViewController.loadMessages), for: UIControlEvents.valueChanged)
        self.tableView?.addSubview(self.refreshControl!)
        
        self.emptyView?.isHidden = true
    }
    
    private func prepareToolbar() {
        guard let tc = toolbarController else {
            return
        }
        tc.toolbar.title = "Messages"
        tc.toolbar.detail = ""
        tc.toolbar.backgroundColor = MAIN_COLOR
        let groupButton = IconButton(image: UIImage(named: "Group")?.withRenderingMode(.alwaysTemplate))
        groupButton.tintColor = UIColor.white
        groupButton.title = "Groups"
        groupButton.titleLabel?.font = RobotoFont.regular(with: 14.0)
        groupButton.addTarget(self, action: #selector(showGroups), for: .touchUpInside)
        appToolbarController.prepareToolbarMenu(right: [groupButton])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appMenuController.menu.views.first?.isHidden = false
        prepareToolbar()
        prepareAddButton()
        prepareSingleButton()
        prepareGroupButton()
        prepareMenuController()
        self.loadMessages()
    }
    
    func showGroups() {
        appToolbarController.push(from: self, to: GroupsViewController())
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
        appToolbarController.push(from: self, to: messageVC)
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
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath:
        IndexPath) {
        Messages.deleteMessageItem(message: self.messages[indexPath.row])
        self.messages.remove(at: indexPath.row)
        self.tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
        self.updateEmptyView()
        self.updateTabCounter()
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let message = self.messages[indexPath.row] as PFObject
        self.openChat(groupId: message[PF_MESSAGES_GROUPID] as! String, title: message[PF_MESSAGES_DESCRIPTION] as! String)
    }
    
    // Menu Controller
    // Handle the menu toggle event.
    internal func handleToggleMenu(button: Button) {
        guard let mc = menuController as? AppMenuController else {
            return
        }
        
        if mc.menu.isOpened {
            print("closeMenu")
            addButton.backgroundColor = MAIN_COLOR
            addButton.tintColor = UIColor.white
            mc.closeMenu { (view) in
                (view as? MenuItem)?.hideTitleLabel()
            }
        } else {
            print("openMenu")
            addButton.backgroundColor = Color.red.base
            addButton.tintColor = UIColor.white
            mc.openMenu { (view) in
                (view as? MenuItem)?.showTitleLabel()
            }
        }
    }
    
    internal func handleSingleButton(button: Button) {
        let vc = SelectSingleViewController()
        vc.delegate = self
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.barTintColor = MAIN_COLOR!
        self.present(navVC, animated: true, completion: { self.closeMenu() })
    }
    
    internal func handleGroupButton(button: Button) {
        let vc = SelectMultipleViewController()
        vc.delegate = self
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.barTintColor = MAIN_COLOR!
        self.present(navVC, animated: true, completion: { self.closeMenu() })
    }
    
    private func closeMenu() {
        guard let mc = menuController as? AppMenuController else {
            print("isMc")
            return
        }
        
        mc.closeMenu { (view) in
            (view as? MenuItem)?.hideTitleLabel()
        }
    }
    
    private func prepareAddButton() {
        addButton = FabButton(image: Icon.cm.add)
        addButton.tintColor = UIColor.white
        addButton.backgroundColor = MAIN_COLOR
        addButton.addTarget(self, action: #selector(handleToggleMenu), for: .touchUpInside)
    }
    
    private func prepareSingleButton() {
        singleButtonItem = MenuItem()
        singleButtonItem.tintColor = UIColor.white
        singleButtonItem.title = "Single Recipient"
        singleButtonItem.button.image = UIImage(named: "Profile")?.withRenderingMode(.alwaysTemplate)
        singleButtonItem.button.backgroundColor = MAIN_COLOR
        singleButtonItem.button.depthPreset = .depth1
        singleButtonItem.button.addTarget(self, action: #selector(handleSingleButton), for: .touchUpInside)
    }
    
    private func prepareGroupButton() {
        groupButtonItem = MenuItem()
        groupButtonItem.tintColor = UIColor.white
        groupButtonItem.title = "Multiple Recipients"
        groupButtonItem.button.image = UIImage(named: "Group")?.withRenderingMode(.alwaysTemplate)
        groupButtonItem.button.backgroundColor = MAIN_COLOR
        groupButtonItem.button.depthPreset = .depth1
        groupButtonItem.button.addTarget(self, action: #selector(handleGroupButton), for: .touchUpInside)
    }
    
    private func prepareMenuController() {
        guard let mc = menuController as? AppMenuController else {
            return
        }
        
        mc.menu.delegate = self
        mc.menu.views = [addButton, groupButtonItem, singleButtonItem]
    }
    
    func menu(menu: Menu, tappedAt point: CGPoint, isOutside: Bool) {
        guard isOutside else {
            return
        }
        closeMenu()
    }
}
