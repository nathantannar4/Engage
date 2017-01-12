//
//  ActivityFeedViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import ParseUI
import Agrume
import DZNEmptyDataSet

class ActivityFeedViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate {
    
    private var posts: [Post] = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Activity Feed"
        self.dataSource = self
        self.delegate = self
        self.tableView.emptyHeaderHeight = 10
        self.tableView.emptyFooterHeight = 10
        self.tableView.contentInset.bottom = 100
        self.queryForPosts()
    }
    
    func tableView(_ tableView: NTTableView, cellForHeaderInSection section: Int) -> NTHeaderCell? {
        if section == 0 {
            return NTHeaderCell()
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: NTTableView, cellForFooterInSection section: Int) -> NTFooterCell? {
        return NTFooterCell()
    }
    
    func numberOfSections(in tableView: NTTableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        switch indexPath.row {
        case 0:
            let cell = NTDetailedProfileCell.initFromNib()
            cell.setDefaults()
            cell.setImageViewDefaults()
            cell.cornersRounded = [.topLeft, .topRight]
            cell.title = self.posts[indexPath.section].user.fullname
            cell.subtitle = "iOS Developer"
            cell.image = self.posts[indexPath.section].user.image
            cell.accessoryButton.setImage(Icon.Apple.moreVerticalFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
            return cell
        case 1:
            let cell = NTImageCell.initFromNib()
            cell.horizontalInset = 10
            cell.contentImageView.layer.borderWidth = 2
            cell.contentImageView.layer.borderColor = UIColor.white.cgColor
            cell.contentImageView.layer.cornerRadius = 5
            cell.image = self.posts[indexPath.section].image
            return cell
        case 2:
            let cell = NTDynamicHeightTextCell.initFromNib()
            cell.horizontalInset = 10
            cell.verticalInset = -5
            cell.text = self.posts[indexPath.section].content
            return cell
        case 3:
            let cell = NTActionCell.initFromNib()
            cell.setDefaults()
            cell.cornersRounded = [.bottomLeft, .bottomRight]
            cell.leftButton.setImage(Icon.Apple.likeFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
            cell.leftButton.setTitle(" Like", for: .normal)
            cell.centerButton.setImage(Icon.Apple.commentFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
            let comments = self.posts[indexPath.section].comments
            let count = comments?.count ?? 0
            var commentString = " \(count) Comments"
            if count == 1 {
                commentString.remove(at: commentString.endIndex)
            }
            cell.centerButton.setTitle(commentString, for: .normal)
            let createdAt = self.posts[indexPath.section].createdAt
            cell.rightButton.setTitle(String.mediumDateNoTime(date: createdAt ?? Date()), for: .normal)
            cell.rightButton.setTitleColor(UIColor.black, for: .normal)
            cell.rightButton.isEnabled = false
            return cell
        default:
            return NTTableViewCell()
        }
    }
    
    
    // MARK: Data Connecter
    
    func queryForPosts() {
        let postQuery = PFQuery(className: "ChatterBox_Posts")
        postQuery.includeKey(PF_POST_USER)
        postQuery.addDescendingOrder(PF_POST_CREATED_AT)
        postQuery.findObjectsInBackground { (objects, error) in
            guard let posts = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            Log.write(.status, "Downloaded \(posts.count) posts")
            for post in posts {
                self.posts.append(Post(fromObject: post))
            }
            self.reloadData()
        }
    }
    
    
    // MARK: DZNEmptyDataSetSource
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Engage", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 44)])
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "Engage_Logo")
    }
}

