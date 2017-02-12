//
//  MessagesViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2/3/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import Former

class MessagesViewController: NTTableViewController, UserSelectionDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Messages"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newMessage))
        
        self.prepareTableView()
        
        let _ = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(checkForUpdates), userInfo: nil, repeats: true)
    }

    func checkForUpdates() {
        for chat in Engagement.current().chats {
            chat.updateObject(completion: { (isNew) in
                if isNew {
                    let index = Engagement.current().chats.index(where: { (findChat) -> Bool in
                        if chat.id == findChat.id {
                            return true
                        }
                        return false
                    })
                    if index != nil {
                        self.updateBadge()
                        self.tableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .none)
                    }
                }
            })
        }
        for channel in Engagement.current().myChannels {
            channel.updateObject(completion: { (isNew) in
                if isNew {
                    let index = Engagement.current().myChannels.index(where: { (findChannel) -> Bool in
                        if channel.id == findChannel.id {
                            return true
                        }
                        return false
                    })
                    if index != nil {
                        self.updateBadge()
                        self.tableView.reloadRows(at: [IndexPath(row: index!, section: 1)], with: .none)
                    }
                }
            })
        }
        for channel in Engagement.current().otherChannels {
            channel.updateObject(completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateBadge()
    }
    
    func updateBadge() {
        var counter = 0
        for chat in Engagement.current().chats {
            counter += chat.isNew ? 1 : 0
        }
        for channel in Engagement.current().myChannels {
            counter += channel.isNew ? 1 : 0
        }
        if counter == 0 {
            self.tabBarController?.tabBar.items?[4].badgeValue = nil
        } else {
            self.tabBarController?.tabBar.items?[4].badgeValue = String(counter)
        }
    }
    
    func pullToRefresh(sender: UIRefreshControl) {
        self.tableView.refreshControl?.beginRefreshing()
        self.tableView.reloadData()
        self.updateBadge()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    // MARK: Preperation
    
    func prepareTableView() {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.refreshControl = refreshControl
        self.tableView.separatorStyle = .singleLine
    }
    
    // MARK: User Actions
    
    func newMessage() {
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = Color.defaultNavbarTint
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        let single: UIAlertAction = UIAlertAction(title: "Single Recipient", style: .default)
        { action -> Void in
            let vc = UserSelectionViewController(group: Engagement.current())
            vc.selectionDelegate = self
            vc.allowMultipleSelection = false
            let navVC = UINavigationController(rootViewController: vc)
            self.present(navVC, animated: true, completion: nil)
        }
        actionSheetController.addAction(single)
        let multiple: UIAlertAction = UIAlertAction(title: "Multiple Recipients", style: .default)
        { action -> Void in
            let vc = UserSelectionViewController(group: Engagement.current())
            vc.selectionDelegate = self
            let navVC = UINavigationController(rootViewController: vc)
            self.present(navVC, animated: true, completion: nil)
        }
        actionSheetController.addAction(multiple)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.textLabel?.textColor = UIColor.black
        if section == 0 {
            // Messages
            header.textLabel?.text = "Private Messages"
            return header
        } else if section == 1 {
            header.textLabel?.text = "Joined Channels"
            return header
        } else if section == 2 {
            header.textLabel?.text = "Other Channels"
            return header
        }
        return nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // Messages
            return Engagement.current().chats.count
        } else if section == 1 {
            // Channels
            return Engagement.current().myChannels.count
        } else if section == 2 {
            // Channels
            return Engagement.current().otherChannels.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.accessoryType = .disclosureIndicator
        
        if indexPath.section == 0 {
            cell.textLabel?.text = Engagement.current().chats[indexPath.row].name
            if let lastMessage = Engagement.current().chats[indexPath.row].messages.last {
                if lastMessage.user?.id == User.current().id {
                    cell.detailTextLabel?.text = "You: " + (lastMessage.text ?? "New Message")
                } else {
                    let nameArray = lastMessage.user?.fullname!.components(separatedBy: " ")
                    cell.detailTextLabel?.text = (nameArray?[0] ?? "User") + ": " + (lastMessage.text ?? "New Message")
                    if Engagement.current().chats[indexPath.row].isNew {
                        cell.detailTextLabel?.textColor = UIColor.red
                    } else {
                        cell.detailTextLabel?.textColor = Color.darkGray
                    }
                }
            }
            cell.imageView?.image = Engagement.current().chats[indexPath.row].image?.cropToSquare()
        } else if indexPath.section == 1 {
            let channelName = NSMutableAttributedString(string: "#" + Engagement.current().myChannels[indexPath.row].name!, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18)])
            channelName.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 16, weight: UIFontWeightBold), range: NSRange(location:0, length:1))
            cell.textLabel?.attributedText = channelName
        } else if indexPath.section == 2 {
            let channelName = NSMutableAttributedString(string: "#" + Engagement.current().otherChannels[indexPath.row].name!, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18)])
            channelName.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 16, weight: UIFontWeightBold), range: NSRange(location:0, length:1))
            cell.textLabel?.attributedText = channelName
        }
        
        cell.imageView?.contentMode = .scaleAspectFit
        cell.imageView?.layer.cornerRadius = 25
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = Color.defaultNavbarTint.cgColor
        cell.imageView?.layer.masksToBounds = true
        
        return cell
    }
    
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            Engagement.current().chats[indexPath.row].isNew = false
            self.updateBadge()
            let vc = ChannelViewController(channel: Engagement.current().chats[indexPath.row])
            self.navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 1 {
            Engagement.current().myChannels[indexPath.row].isNew = false
            self.updateBadge()
            let vc = ChannelViewController(channel: Engagement.current().myChannels[indexPath.row])
            self.navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 2 {
            
            let actionSheetController: UIAlertController = UIAlertController(title: nil, message: "Would you like to join #\(Engagement.current().otherChannels[indexPath.row].name!)", preferredStyle: .alert)
            actionSheetController.view.tintColor = Color.defaultNavbarTint
            
            let privateAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheetController.addAction(privateAction)
            
            let publicAction: UIAlertAction = UIAlertAction(title: "Join", style: .default) { action -> Void in
                Engagement.current().otherChannels[indexPath.row].join(user: User.current(), completion: { (success) in
                    if success {
                        self.tableView.reloadSections([1,2], with: .automatic)
                    }
                })
            }
            actionSheetController.addAction(publicAction)
            
            actionSheetController.popoverPresentationController?.sourceView = self.view
            
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let leave = UITableViewRowAction(style: .normal, title: "Leave") { action, index in
            if index.section == 0 {
                Engagement.current().chats[index.row].leave(user: User.current(), completion: { (success) in
                    if success {
                        Engagement.current().chats.remove(at: index.row)
                        self.tableView.deleteRows(at: [index], with: .fade)
                    }
                })
            } else if index.section == 1 {
                Engagement.current().myChannels[index.row].leave(user: User.current(), completion: { (success) in
                    if success {
                        self.tableView.reloadSections([1,2], with: .automatic)
                    }
                })
            }
        }
        leave.backgroundColor = UIColor.orange
        
        let join = UITableViewRowAction(style: .normal, title: " Join ") { action, index in
            Engagement.current().otherChannels[indexPath.row].join(user: User.current(), completion: { (success) in
                if success {
                    self.tableView.reloadSections([1,2], with: .automatic)
                }
            })
        }
        join.backgroundColor = Color.darkGreen
        
        let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            if index.section == 0 {
                Engagement.current().chats[index.row].delete(completion: { (success) in
                    if success {
                        Engagement.current().chats.remove(at: index.row)
                        self.tableView.deleteRows(at: [index], with: .fade)
                    }
                })
            } else if index.section == 1 {
                Engagement.current().myChannels[index.row].delete(completion: { (success) in
                    if success {
                        self.tableView.reloadSections([1,2], with: .automatic)
                    }
                })
            }
        }
        delete.backgroundColor = UIColor.red
        
        if indexPath.section == 0 {
            if let members = Engagement.current().chats[indexPath.row].members {
                if members.count > 2 {
                    return [delete, leave]
                } else {
                    return [delete]
                }
            }
        } else if indexPath.section == 1 {
            if let admins = Engagement.current().myChannels[indexPath.row].admins {
                if admins.contains(User.current().id) {
                    return [delete, leave]
                } else {
                    return [leave]
                }
            }
        } else if indexPath.section == 2 {
            return [join]
        }
        return nil
    }


    // MARK: UserSelectionDelegate
    
    func didMakeSelection(ofUsers users: [User]) {
        
        if users.count == 0 {
            return
        } else if users.count == 1 {
            self.createChannel(withUsers: users, isPrivate: true)
            return
        }
        
        let actionSheetController: UIAlertController = UIAlertController(title: "Privacy Option", message: "", preferredStyle: .alert)
        actionSheetController.view.tintColor = Color.defaultNavbarTint
        
        let privateAction: UIAlertAction = UIAlertAction(title: "Private", style: .cancel) { action -> Void in
            self.createChannel(withUsers: users, isPrivate: true)
        }
        actionSheetController.addAction(privateAction)
        
        let publicAction: UIAlertAction = UIAlertAction(title: "Public", style: .default) { action -> Void in
            self.createChannel(withUsers: users, isPrivate: false)
        }
        actionSheetController.addAction(publicAction)
        
        actionSheetController.popoverPresentationController?.sourceView = self.view
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func createChannel(withUsers users: [User], isPrivate: Bool) {
        if users.count <= 2 && isPrivate {
            Channel.create(users: users, isPrivate: isPrivate, completion: { (success) in
                if success {
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                }
            })
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Channel Name", message: "", preferredStyle: .alert)
            if isPrivate {
                actionSheetController.title = "Group Name"
            }
            actionSheetController.view.tintColor = Color.defaultNavbarTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheetController.addAction(cancelAction)
            
            let nextAction: UIAlertAction = UIAlertAction(title: "Create", style: .default) { action -> Void in
                
                let textField = actionSheetController.textFields![0]
                if let text = textField.text {
                    let name = text.replacingOccurrences(of: " ", with: "_")
                    Channel.create(users: users, name: name, isPrivate: isPrivate, completion: { (success) in
                        if success {
                            self.tableView.beginUpdates()
                            if isPrivate {
                                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                            } else {
                                self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
                            }
                            self.tableView.endUpdates()
                        }
                    })
                } else {
                    let toast = Toast(text: "Cancelled", button: nil, color: Color.darkGray, height: 44)
                    toast.show(duration: 1.0)
                }
            }
            actionSheetController.addAction(nextAction)
            
            actionSheetController.addTextField { textField -> Void in
                //TextField configuration
                //textField.textColor = UIColor(red: 153.0/255, green:62.0/255.0, blue:123.0/255, alpha: 1)
            }
            actionSheetController.popoverPresentationController?.sourceView = self.view
            
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
}
