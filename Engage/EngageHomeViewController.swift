//
//  EngagementHomeViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Agrume
import Parse

class EngagementHomeViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate {
    
    var engagements = [Engagement]()
    var isRefreshing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageView = UIImageView(image: UIImage(named: "Engage_Logo")?.resizeImage(width: 45, height: 45, renderingMode: .alwaysOriginal))
        self.navigationItem.titleView = imageView
        self.dataSource = self
        self.delegate = self
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createEngagement(sender:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout(sender:)))
        self.prepareTableView()
        self.refreshEngagements()
    }
    
    func pullToRefresh(sender: UIRefreshControl) {
        self.tableView.refreshControl?.beginRefreshing()
        self.refreshEngagements()
    }
    
    // MARK: Preperation Functions
    
    private func prepareTableView() {
        self.tableView.contentInset.bottom = 100
        self.tableView.emptyHeaderHeight = 50
        self.tableView.emptyFooterHeight = 20
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    // MARK: User Action
    
    func createEngagement(sender: UIBarButtonItem) {
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = Color.defaultButtonTint
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Dismiss", style: .cancel)
        actionSheetController.addAction(cancelAction)
        
        let previewAction: UIAlertAction = UIAlertAction(title: "Create Engagement", style: .default) { action -> Void in
            let navVC = UINavigationController(rootViewController: CreateGroupViewController(asEngagement: true))
            self.present(navVC, animated: true, completion: nil)
        }
        actionSheetController.addAction(previewAction)
        
        let joinAction: UIAlertAction = UIAlertAction(title: "Join By Name", style: .default) { action -> Void in
            let actionSheetController: UIAlertController = UIAlertController(title: "Engagement Name", message: "Not case sensitive", preferredStyle: .alert)
            actionSheetController.view.tintColor = Color.defaultNavbarTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .destructive)
            actionSheetController.addAction(cancelAction)
            
            let nextAction: UIAlertAction = UIAlertAction(title: "Join", style: .default) { action -> Void in
                let name = actionSheetController.textFields![0].text?.lowercased()
                let query = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
                query.whereKey(PF_ENGAGEMENTS_LOWERCASE_NAME, equalTo: name ?? String())
                query.getFirstObjectInBackground(block: { (object, error) in
                    guard let engagementObject = object else {
                        Log.write(.error, error.debugDescription)
                        let toast = Toast(text: error?.localizedDescription, button: nil, color: Color.darkGray, height: 44)
                        toast.show(duration: 1.5)
                        return
                    }
                    
                    let engagement = Cache.retrieveEngagement(engagementObject)
                    engagement.join(target: self)
                })
            }
            actionSheetController.addAction(nextAction)
            
            actionSheetController.addTextField { textField -> Void in
                textField.textColor = Color.darkGray
            }
            self.present(actionSheetController, animated: true, completion: nil)
        }
        actionSheetController.addAction(joinAction)
        
        actionSheetController.popoverPresentationController?.sourceView = self.view
        actionSheetController.popoverPresentationController?.sourceRect = self.view.bounds
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func logout(sender: UIBarButtonItem) {
        User.current().logout(self)
    }
    
    // MARK: NTTableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 80
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    func tableView(_ tableView: NTTableView, cellForHeaderInSection section: Int) -> NTHeaderCell? {
        if section == 0 {
            let header = NTHeaderCell.initFromNib()
            header.titleLabel.text = self.engagements.count > 0 ? "Your Engagements" : String()
            return header
        }
        return NTHeaderCell()
    }

    func numberOfSections(in tableView: NTTableView) -> Int {
        return self.engagements.count
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if indexPath.section < self.engagements.count {
            let cell = NTPageHeaderCell.initFromNib()
            cell.setDefaults()
            cell.image = self.engagements[indexPath.row].image != nil ? self.engagements[indexPath.row].image?.resizeImage(width: 40, height: 40, renderingMode: .alwaysOriginal) : #imageLiteral(resourceName: "hub").withRenderingMode(.alwaysTemplate)
            cell.pageImageView.tintColor = self.engagements[indexPath.section].color
            cell.name = self.engagements[indexPath.section].name
            return cell
        }
        return NTTableViewCell()
    }
    
    // MARK: NTTableViewDelegate
    
    func tableView(_ tableView: NTTableView, didSelectRowAt indexPath: IndexPath) {
        self.getNTNavigationContainer?.toggleLeftPanel()
        Engagement.didSelect(with: self.engagements[indexPath.section])
    }
    
    // MARK: Backend Connection
    
    func refreshEngagements() {
        if self.isRefreshing {
            return
        }
        self.isRefreshing = true
        let engagementQuery = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
        engagementQuery.whereKey(PF_ENGAGEMENTS_OBJECT_ID, containedIn: User.current().engagementsIds)
        engagementQuery.findObjectsInBackground { (objects, error) in
            guard let engagements = objects else {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: error?.localizedDescription, button: nil, color: Color.darkGray, height: 44)
                toast.show(duration: 1.5)
                return
            }
            self.engagements.removeAll()
            for engagement in engagements {
                self.engagements.append(Cache.retrieveEngagement(engagement))
            }
            self.isRefreshing = false
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
}


