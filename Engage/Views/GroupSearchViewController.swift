//
//  GroupSearchViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 6/8/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents
import Parse

class GroupSearchViewController: NTTableViewController {
    
    var engagements = [PFObject]()

    let searchField: NTAnimatedTextField = {
        let textField = NTAnimatedTextField()
        textField.placeholder = "Search"
        textField.placeholderInsets = CGPoint(x: 0, y: 8)
        textField.font = Font.Default.Body.withSize(17)
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        parent?.title = "Search Groups"
        tableView.refreshControl = refreshControl()
        tableView.tableFooterView = UIView()
        
        let searchView: NTInputAccessoryView = {
            let view = NTInputAccessoryView()
            view.setDefaultShadow()
            view.layer.shadowOffset = CGSize(width: 0, height: -Color.Default.Shadow.Offset.height)
            view.clipsToBounds = false
            view.heightConstant = 54
            return view
        }()
        
        let searchButton = NTButton()
        searchButton.image = Icon.Search?.scale(to: 30)
        searchButton.trackTouchLocation = false
        searchButton.layer.cornerRadius = 25
        searchButton.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        
//        searchField.addTarget(self, action: #selector(handleRefresh), for: .editingChanged)
        
        searchView.controller = self
        searchView.addSubview(searchField)
        searchView.addSubview(searchButton)
        
        searchField.anchor(searchView.topAnchor, left: searchView.leftAnchor, bottom: searchView.bottomAnchor, right: searchButton.leftAnchor, topConstant: 2, leftConstant: 16, bottomConstant: 4, rightConstant: 4, widthConstant: 0, heightConstant: 0)
        searchButton.anchor(nil, left: nil, bottom: searchView.bottomAnchor, right: searchView.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 12, rightConstant: 16, widthConstant: 50, heightConstant: 50)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchField.resignFirstResponder()
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

        cell.textLabel?.text = self.engagements[indexPath.row].value(forKey: PF_ENGAGEMENTS_NAME) as? String
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
        if let memberCount = self.engagements[indexPath.row].value(forKey: PF_ENGAGEMENTS_MEMBER_COUNT) as? Int {
            cell.detailTextLabel?.text = "\(memberCount) Members"
        }
        
//        let url = (self.engagements[indexPath.row].value(forKey: PF_ENGAGEMENTS_COVER_PHOTO) as? PFFile)?.url
//        (cell.imageView as? NTImageView)?.loadImage(urlString: url)
//        cell.imageView?.image = UIImage.from(color: Color.Default.Tint.View)
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.layer.cornerRadius = 5
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = Color.Default.Tint.View.cgColor
        cell.imageView?.layer.masksToBounds = true

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(engagements[indexPath.row])
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchField.resignFirstResponder()
    }
    
    override func handleRefresh() {
        let query = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
        query.limit = 25
        query.order(byDescending: PF_ENGAGEMENTS_UPDATED_AT)
        if let engagements = User.current()?.engagements {
            query.whereKey(PF_ENGAGEMENTS_OBJECT_ID, doesNotMatchKey: PF_ENGAGEMENTS_OBJECT_ID, in: engagements.query())
        }
        query.whereKey(PF_ENGAGEMENTS_LOWERCASE_NAME, contains: self.searchField.text?.lowercased())
        query.findObjectsInBackground(block: { (objects, error) in
            guard let engagements = objects else {
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription.capitalized).show()
                return
            }
            print(engagements)
            self.engagements = engagements
            DispatchQueue.main.async {
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        })
    }
}
