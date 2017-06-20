//
//  SideBarMenuViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/19/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents
import Parse

class SideBarMenuViewController: NTTableViewController, UIViewControllerTransitioningDelegate{
    
    var engagements = [Engagement]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rc = refreshControl()
        tableView.refreshControl = rc
        tableView.tableFooterView = UIView()
        
        // Add navigation items
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Help?.scale(to: 25), style: .plain, target: self, action: #selector(helpButtonPressed))
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createEngagement)), UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchEngagements))]
        
        handleRefresh()
    }
    
    func createEngagement() {
        let group = Engagement(PFObject(className: PF_ENGAGEMENTS_CLASS_NAME))
        let navVC = NTNavigationViewController(rootViewController: EditGroupViewController(fromGroup: group))
        navVC.transitioningDelegate = self
        navVC.modalPresentationStyle = .custom
        present(navVC, animated: true, completion: nil)
    }
    
    func searchEngagements() {
        let navVC = NTNavigationViewController(rootViewController: GroupSearchViewController())
        navVC.transitioningDelegate = self
        navVC.modalPresentationStyle = .custom
        present(navVC, animated: true, completion: nil)
    }
    
    func helpButtonPressed() {
        
    }
    
    func logout() {
        User.current()?.logout()
    }

    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engagements.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = NTTableViewCell()
        
        cell.textLabel?.text = self.engagements[indexPath.row].name
        cell.textLabel?.font = Font.Default.Body.withSize(18)
        cell.detailTextLabel?.text = "\(self.engagements[indexPath.row].memberCount) Members"
    
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.layer.cornerRadius = 5
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = Color.Default.Tint.View.cgColor
        cell.imageView?.layer.masksToBounds = true
        
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if engagements[indexPath.row].id != Engagement.current()?.id {
            Engagement.select(engagements[indexPath.row])
        }
    }
    
    override func handleRefresh() {
        let query = User.current()?.engagements?.query()
        query?.findObjectsInBackground(block: { (objects, error) in
            guard let engagements = objects else {
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription.capitalized).show()
                return
            }
            self.engagements = engagements.map({ (engagement) -> Engagement in
                return Engagement(engagement)
            })
            DispatchQueue.main.async {
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        })
    }
}
