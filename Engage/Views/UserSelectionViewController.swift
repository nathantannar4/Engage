//
//  UserSelectionViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import NTComponents
import Parse


class UserSelectionViewController: NTSearchSelectViewController<User> {
    
    var confirmedSelectionMethod: (([User])->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "User Selection"
    }
    
    override func updateResults() {
        guard let query = Engagement.current()?.members.query() else {
            return
        }
        query.limit = 1000
        query.order(byAscending: PF_USER_FULLNAME)
        query.whereKey(PF_USER_OBJECTID, notEqualTo: User.current()!.id)
        query.whereKey(PF_USER_FULLNAME_LOWER, contains: self.searchBar.text?.lowercased())
        query.findObjectsInBackground(block: { (objects, error) in
            guard let users = objects as? [PFUser] else {
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription.capitalized).show()
                return
            }
            self.objects = users.map { return User($0) }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.textLabel?.text = objects[indexPath.row].fullname
        cell.imageView?.image = objects[indexPath.row].image?.toSquare()
        cell.imageView?.fullyRound(diameter: 44, borderColor: Color.Default.Tint.View, borderWidth: 1)
        return cell
    }
    
    override func searchController(confirmedSelectionOfObjects objects: [User]) {
        confirmedSelectionMethod?(objects)
    }
    
    override func searchController(didCancelSelectionOfObject: User, atRow row: Int) {
        
    }
    
    override func searchController(didMakeSelectionOfObject object: User, atRow row: Int) {
        
    }
}


