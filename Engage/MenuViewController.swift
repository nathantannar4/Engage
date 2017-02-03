//
//  MenuViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse

class MenuViewController: UITableViewController {
    
    var viewControllers = [UIViewController]()
    var titles = [String]()
    var currentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prepareTable()
        
        self.viewControllers = [ActivityFeedViewController(), ProfileViewController(user: User.current()), EngagementViewController(engagement: Engagement.current()), NTTableViewController()]
        self.titles = ["Activity Feed", "Profile", Engagement.current().name ?? "Engagement", User.current().userExtension?.team?.name ?? "Join a Team"] as [String]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let team = User.current().userExtension?.team {
            self.titles[3] = team.name!
            self.viewControllers[3] = TeamViewController(team: team)
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewControllers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.contentView.backgroundColor = self.tableView.backgroundColor
        cell.textLabel?.text = self.titles[indexPath.row]
        cell.textLabel?.textColor = Color.darkGray
        if indexPath.row == currentIndex {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.transitionToViewController(index: indexPath.row)
    }
    
    // MARK: - Preperation Functions
    private func prepareTable() {
        self.tableView.contentInset.top = 20
        self.tableView.separatorStyle = .none
        self.tableView.bounces = false
        self.tableView.backgroundColor = UIColor.groupTableViewBackground
        self.tableView.estimatedRowHeight = 44
    }
    
    // MARK: - Navigation
    private func transitionToViewController(index: Int) {
        self.currentIndex = index
        self.tableView.reloadData()
        self.getNTNavigationContainer?.setCenterView(newView: self.viewControllers[index])
        self.getNTNavigationContainer?.toggleLeftPanel()
    }
}

