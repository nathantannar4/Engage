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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createChannel))
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.refreshControl = refreshControl
        self.tableView.separatorStyle = .singleLine
    }
    
    func pullToRefresh(sender: UIRefreshControl) {
        self.tableView.refreshControl?.beginRefreshing()
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    // MARK: User Actions
    
    func createChannel() {
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.textLabel?.textColor = UIColor.black
        if section == 0 {
            // Messages
            header.textLabel?.text = "Private Messages"
            return header
        } else if section == 1 {
            header.textLabel?.text = "Public Channels"
            return header
        } else {
            return nil
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return ((Engagement.current().chats.count > 0) ? 1 : 0) + ((Engagement.current().channels.count > 0) ? 1 : 0)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // Messages
            return Engagement.current().chats.count
        } else if section == 1 {
            // Channels
            return Engagement.current().channels.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.accessoryType = .disclosureIndicator
        
        if indexPath.section == 0 {
            cell.textLabel?.text = Engagement.current().chats[indexPath.row].name
            cell.imageView?.image = Engagement.current().chats[indexPath.row].image
        } else if indexPath.section == 1 {
            cell.textLabel?.text = "#" + Engagement.current().channels[indexPath.row].name!
            cell.imageView?.image = Engagement.current().channels[indexPath.row].image
        }
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.layer.cornerRadius = 22
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = Color.defaultNavbarTint.cgColor
        cell.imageView?.layer.masksToBounds = true
        
        return cell
    }
    
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        
        /*
         if indexPath.section == 0 {
         Engagement.current().chats.remove(at: indexPath.row)
         tableView.deleteRows(at: [indexPath], with: .fade)
         } else if indexPath.section == 1{
         Engagement.current().channels.remove(at: indexPath.row)
         tableView.deleteRows(at: [indexPath], with: .fade)
         }
         */
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let vc = ChannelViewController(channel: Engagement.current().chats[indexPath.row])
            self.navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 1 {
            let vc = ChannelViewController(channel: Engagement.current().channels[indexPath.row])
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: UserSelectionDelegate
    
    func didMakeSelection(ofUsers users: [User]) {
        if users.count == 1 {
            // Make Private Chat Channel
            Channel.create(users: users, completion: { (success) in
                if success {
                    
                }
            })
        } else if users.count > 1 {
            // Make Channel
            
            let actionSheetController: UIAlertController = UIAlertController(title: "Channel Name", message: "", preferredStyle: .alert)
            actionSheetController.view.tintColor = Color.defaultNavbarTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            actionSheetController.addAction(cancelAction)
            
            let nextAction: UIAlertAction = UIAlertAction(title: "Create", style: .default) { action -> Void in
                
                let textField = actionSheetController.textFields![0]
                if let text = textField.text {
                    let name = text.replacingOccurrences(of: " ", with: "_")
                    Channel.create(users: users, name: name, completion: { (success) in
                        if success {
                            self.tableView.reloadData()
                            self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
                        }
                    })
                } else {
                    Channel.create(users: users, completion: { (success) in
                        if success {
                            self.tableView.reloadData()
                        }
                    })
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
