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

class ActivityFeedViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate, DZNEmptyDataSetSource {
    
    private var posts: [Post] = [Post]()
    private var isQuerying: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Activity Feed"
        self.dataSource = self
        self.delegate = self
        self.prepareTableView()
        self.prepareButton()
        //self.queryForPosts()
    }
    
    func pullToRefresh(sender: UIRefreshControl) {
        self.tableView.refreshControl?.beginRefreshing()
        self.posts.removeAll()
        self.reloadData()
        self.queryForPosts()
    }
    
    // MARK: Preperation Functions
    
    private func prepareTableView() {
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyHeaderHeight = 10
        self.tableView.emptyFooterHeight = 10
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    func prepareButton() {
        let button = UIButton()
        button.frame = CGRect(x: self.view.frame.width - 75, y: self.view.frame.height - 75, width: 50, height: 50)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.backgroundColor = Color.defaultNavbarBackground
        button.addTarget(self, action: #selector(createNewPost(sender:)), for: .touchUpInside)
        button.layer.shadowColor = Color.darkGray.cgColor
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 2
        button.setImage(Icon.Google.add?.resizeImage(width: 30, height: 30, renderingMode: .alwaysTemplate), for: .normal)
        button.tintColor = Color.defaultNavbarTint
        self.view.addSubview(button)
    }
    
    // MARK: User Actions
    
    func toggleLike(sender: UIButton) {
        guard let likes = self.posts[sender.tag].likes else {
            return
        }
        if likes.contains(User.current().id) {
            sender.setTitle(" \(likes.count - 1)", for: .normal)
            self.posts[sender.tag].unliked(byUser: User.current()) { (success) in
                if !success {
                    // Reset if save failed
                    let likes = self.posts[sender.tag].likes
                    let likeCount = likes?.count ?? 0
                    sender.setTitle(" \(likeCount)", for: .normal)
                }
            }
        } else {
            sender.setTitle(" \(likes.count + 1)", for: .normal)
            self.posts[sender.tag].liked(byUser: User.current()) { (success) in
                if !success {
                    // Reset if save failed
                    let likes = self.posts[sender.tag].likes
                    let likeCount = likes?.count ?? 0
                    sender.setTitle(" \(likeCount)", for: .normal)
                }
            }
        }
    }
    
    func handleMore(sender: UIButton) {
        let post = self.posts[sender.tag]
        if post.user.id == User.current().id {
            post.handleByOwner(target: self, sender: sender)
        } else {
            post.handle(target: self, sender: sender)
        }
    }
    
    func createNewPost(sender: UIButton) {
        let navVC = UINavigationController(rootViewController: NewPostViewController())
        navVC.view.frame = CGRect(x: 25 , y: 60, width: self.view.frame.width - 50, height: self.view.frame.height / 2)
        navVC.view.center = self.view.center
        self.getNTNavigationContainer?.presentOverlay(navVC, from: .bottom)
    }
    
    // MARK: NTTableViewDataSource
    
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
            let cell = NTProfileCell.initFromNib()
            cell.setDefaults()
            cell.setImageViewDefaults()
            cell.imageView.layer.borderWidth = 1
            cell.imageView.layer.borderColor = Color.defaultButtonTint.cgColor
            cell.cornersRounded = [.topLeft, .topRight]
            cell.title = self.posts[indexPath.section].user.fullname
            cell.image = self.posts[indexPath.section].user.image
            cell.accessoryButton.setImage(Icon.Apple.moreVerticalFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
            cell.accessoryButton.addTarget(self, action: #selector(handleMore(sender:)), for: .touchUpInside)
            return cell
        case 1:
            let cell = NTImageCell.initFromNib()
            cell.horizontalInset = 10
            cell.contentImageView.layer.borderWidth = 2
            cell.contentImageView.layer.borderColor = UIColor.white.cgColor
            cell.contentImageView.layer.cornerRadius = 5
            cell.image = self.posts[indexPath.section].image
            if cell.image == nil {
                cell.contentImageView.removeFromSuperview()
                cell.bounds = CGRect.zero
            }
            return cell
        case 2:
            let cell = NTDynamicHeightTextCell.initFromNib()
            cell.verticalInset = -5
            cell.horizontalInset = 10
            cell.text = self.posts[indexPath.section].content
            return cell
        case 3:
            let cell = NTActionCell.initFromNib()
            cell.setDefaults()
            cell.cornersRounded = [.bottomLeft, .bottomRight]
            cell.leftButton.setImage(Icon.Apple.likeFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
            let likes = self.posts[indexPath.section].likes
            let likeCount = likes?.count ?? 0
            cell.leftButton.setTitle(" \(likeCount)", for: .normal)
            cell.leftButton.tag = indexPath.section
            cell.leftButton.addTarget(self, action: #selector(toggleLike(sender:)), for: .touchUpInside)
            cell.centerButton.setImage(Icon.Apple.commentFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
            let comments = self.posts[indexPath.section].comments
            let commentsCount = comments?.count ?? 0
            cell.centerButton.setTitle(" \(commentsCount)", for: .normal)
            cell.centerButton.tag = indexPath.section
            let createdAt = self.posts[indexPath.section].createdAt
            cell.rightButton.setTitle(String.mediumDateNoTime(date: createdAt ?? Date()), for: .normal)
            cell.rightButton.setTitleColor(UIColor.black, for: .normal)
            cell.rightButton.isEnabled = false
            return cell
        default:
            return NTTableViewCell()
        }
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == (self.numberOfSections(in: self.tableView) - 1) {
            Log.write(.status, "Loading more posts")
            self.queryForPosts()
        }
    }
    
    // MARK: Data Connecter
    
    func queryForPosts() {
        if self.isQuerying {
            return
        } else {
            self.isQuerying = true
        }
        guard let engagement = Engagement.current() else {
            return
        }
        let postQuery = PFQuery(className: engagement.queryName! + PF_POST_CLASSNAME)
        postQuery.includeKey(PF_POST_USER)
        postQuery.skip = self.posts.count
        postQuery.limit = 10
        postQuery.addDescendingOrder(PF_POST_CREATED_AT)
        postQuery.findObjectsInBackground { (objects, error) in
            guard let posts = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            for post in posts {
                self.posts.append(Cache.retrievePost(post))
            }
            if posts.count > 0 {
                Log.write(.status, "Downloaded \(posts.count) posts")
                self.reloadData()
            } else {
                Log.write(.status, "No more posts are left to download")
            }
            self.isQuerying = false
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    
    // MARK: DZNEmptyDataSetSource
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: Engagement.current()?.name ?? "Engage", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 36)])
    }
}

