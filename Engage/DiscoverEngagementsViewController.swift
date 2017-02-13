//
//  DiscoverEngagementsViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse

class DiscoverEngagementsViewController: NTSearchViewController, NTTableViewDelegate {
    
    var engagements = [Engagement]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.searchBar.placeholder = "Search Engagements"
        self.tableView.separatorStyle = .singleLine
    }
    
    // MARK: User Actions
    
    override func updateResults() {
        let query = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
        query.cachePolicy = .cacheElseNetwork
        query.limit = 100
        query.order(byDescending: PF_ENGAGEMENTS_UPDATED_AT)
        query.whereKey(PF_ENGAGEMENTS_HIDDEN, equalTo: false)
        query.whereKey(PF_ENGAGEMENTS_LOWERCASE_NAME, contains: self.searchBar.text?.lowercased())
        query.findObjectsInBackground(block: { (objects, error) in
            guard let engagements = objects else {
                Log.write(.error, error.debugDescription)
                Toast.genericErrorMessage()
                return
            }
            self.engagements.removeAll()
            for engagement in engagements {
                self.engagements.append(Cache.retrieveEngagement(engagement))
            }
            self.tableView.reloadData()
        })
    }
    
    // MARK: NTTableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.engagements.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        cell.textLabel?.text = self.engagements[indexPath.row].name
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
        if let members = self.engagements[indexPath.row].members {
            cell.detailTextLabel?.text = "\(members.count) Members"
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
            cell.detailTextLabel?.textColor = Color.defaultSubtitle
        }
        
        cell.imageView?.image = self.engagements[indexPath.row].image != nil ? self.engagements[indexPath.row].image?.resizeImage(width: 40, height: 40, renderingMode: .alwaysOriginal) : #imageLiteral(resourceName: "hub").resizeImage(width: 40, height: 40, renderingMode: .alwaysTemplate)
        cell.imageView?.tintColor = self.engagements[indexPath.row].color
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.layer.cornerRadius = 5
        cell.imageView?.layer.borderWidth = 1.5
        cell.imageView?.layer.borderColor = self.engagements[indexPath.row].color?.cgColor
        cell.imageView?.layer.masksToBounds = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let members = self.engagements[indexPath.row].members else {
            return
        }
        
        if members.contains(User.current().id) {
            Engagement.didSelect(with: self.engagements[indexPath.row])
        } else {
            self.engagements[indexPath.row].join(target: self)
        }
    }
}

