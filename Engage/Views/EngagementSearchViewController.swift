//
//  EngagementSearchViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/20/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents
import Parse

class EngagementSearchViewController: NTNavigationViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var engagements = [Engagement]()
    
    let searchField: NTAnimatedTextField = {
        let textField = NTAnimatedTextField()
        textField.placeholder = "Search by Name"
        return textField
    }()
    
    open var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    let searchView: NTInputAccessoryView = {
        let view = NTInputAccessoryView()
        view.setDefaultShadow()
        view.layer.shadowOffset = CGSize(width: 0, height: -Color.Default.Shadow.Offset.height)
        view.clipsToBounds = false
        view.heightConstant = 54
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Search Engagements"
        backButton.image = Icon.Delete
        nextButton.image = Icon.Search?.scale(to: 30)
        
        searchView.controller = self
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.anchor(navBarView.bottomAnchor, left: view.leftAnchor, bottom: searchView.topAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        
        nextButton.removeFromSuperview()
        nextButton.removeAllConstraints()
        
        searchView.addSubview(searchField)
        searchView.addSubview(nextButton)
        
        searchField.delegate = self
        searchField.anchor(nil, left: searchView.leftAnchor, bottom: searchView.bottomAnchor, right: nextButton.leftAnchor, topConstant: 0, leftConstant: 16, bottomConstant: 10, rightConstant: 8, widthConstant: 0, heightConstant: 30)
        nextButton.anchor(nil, left: nil, bottom: searchView.bottomAnchor, right: searchView.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 10, rightConstant: 16, widthConstant: 50, heightConstant: 50)
    
        view.bringSubview(toFront: navBarView)
        view.bringSubview(toFront: searchView)
    }
    
    override func nextButtonPressed() {
        if searchField.isFirstResponder {
            searchField.resignFirstResponder()
        } else {
            searchField.becomeFirstResponder()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        reloadData()
        return true
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engagements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = NTTableViewCell()
        
        cell.textLabel?.text = self.engagements[indexPath.row].name
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
        if let members = self.engagements[indexPath.row].members {
            cell.detailTextLabel?.text = "\(members.count) Members"
        }
        
        cell.imageView?.image = self.engagements[indexPath.row].image?.scale(to: 40)
        cell.imageView?.tintColor = self.engagements[indexPath.row].color
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.layer.cornerRadius = 5
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = self.engagements[indexPath.row].color?.cgColor
        cell.imageView?.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(engagements[indexPath.row])
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchField.resignFirstResponder()
    }
    
    func reloadData() {
        let query = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
        query.limit = 25
        query.order(byDescending: PF_ENGAGEMENTS_UPDATED_AT)
        query.whereKey(PF_ENGAGEMENTS_HIDDEN, equalTo: false)
        if let currentEngagements = User.current()?.engagementRelations {
            query.whereKey(PF_ENGAGEMENTS_OBJECT_ID, doesNotMatchKey: PF_ENGAGEMENTS_OBJECT_ID, in: currentEngagements.query())
        }
        query.whereKey(PF_ENGAGEMENTS_LOWERCASE_NAME, contains: self.searchField.text?.lowercased())
        query.findObjectsInBackground(block: { (objects, error) in
            guard let engagements = objects else {
                Log.write(.error, error.debugDescription)
                NTPing(type: .isWarning, title: error?.localizedDescription.capitalized).show()
                return
            }
            print(engagements)
            self.engagements.removeAll()
            for engagement in engagements {
                self.engagements.append(Engagement(engagement))
            }
            self.tableView.reloadData()
        })
    }
}
