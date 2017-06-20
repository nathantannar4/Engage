//
//  MessagesViewController.swift
//  CryptoChat
//
//  Created by Nathan Tannar on 6/15/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents
import Parse

class MessagesViewController: NTTableViewController {
    
    var channels = [Channel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.refreshControl = refreshControl()
        tableView.tableFooterView = UIView()
        handleRefresh()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let menuButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleMore))
        drawerController?.rootViewController?.navigationItem.setRightBarButton(menuButton, animated: true)
    }
    
    func handleMore() {
        var items = [NTActionSheetItem]()
        items.append(
            NTActionSheetItem(title: "New Message", icon: nil, action: {
                let vc = UserSelectionViewController()
                vc.confirmedSelectionMethod = { objects in
                    var users = objects
                    users.append(User.current()!)
                    vc.showActivityIndicator = true
                    Channel.create(withUsers: users) { (channel) in
                        vc.showActivityIndicator = false
                        vc.dismiss(animated: true, completion: {
                            
                            self.channels.insert(channel, at: 0)
                            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                            
                            let chatVC = ChatViewController()
                            chatVC.channel = channel
                            self.navigationController?.pushViewController(chatVC, animated: true)
                        })
                    }
                }
                self.present(NTNavigationController(rootViewController: vc), animated: true, completion: nil)
            })
        )
        let actionSheet = NTActionSheetViewController(actions: items)
        actionSheet.addDismissAction(withText: "Dismiss", icon: nil)
        self.present(actionSheet, animated: false, completion: nil)
    }
    
    override func handleRefresh() {
        
        let userQuery = PFUser.query()!
        userQuery.whereKey(PF_USER_OBJECTID, equalTo: User.current()!.id)
    
        let query = PFQuery(className: Engagement.current()!.queryName! + PF_CHANNEL_CLASS_NAME)
        query.whereKey(PF_CHANNEL_MEMBERS, matchesQuery: userQuery)
        query.addDescendingOrder(PF_CHANNEL_CREATED_AT)
        query.findObjectsInBackground(block: { (objects, error) in
            guard let channels = objects else {
                NTPing(type: .isDanger, title: error?.localizedDescription.capitalized).show()
                return
            }
            self.channels = channels.map({ (object) -> Channel in
                return Channel(object)
            })
            DispatchQueue.main.async {
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        })
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NTTableViewCell", for: indexPath) as! NTTableViewCell
        cell.textLabel?.text = channels[indexPath.row].id
        cell.detailTextLabel?.text = channels[indexPath.row].id
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCell(_:)))
        cell.addGestureRecognizer(longPress)
        longPress.view?.tag = indexPath.row
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = ChatViewController()
        vc.channel = channels[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func didLongPressCell(_ sender: UILongPressGestureRecognizer) {
        if let row = sender.view?.tag {
            sender.isEnabled = false
            let alert = NTAlertViewController(title: "Remove Chat?", subtitle: channels[row].name, type: .isDanger)
            alert.confirmButton.title = "Remove"
            alert.onConfirm = {
                self.channels[row].remove(user: User.current()!, completion: { (success) in
                    if success {
                        self.channels.remove(at: row)
                        self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .fade)
                    }
                })
            }
            alert.onCancel = {
                sender.isEnabled = true
            }
            present(alert, animated: true, completion: nil)
        }
    }
}
