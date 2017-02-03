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

class ActivityFeedViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate, DZNEmptyDataSetSource, PostModificationDelegate {
    
    private var posts: [Post] = [Post]()
    private var isQuerying: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Activity Feed"
        self.subtitle = "All Posts"
        self.dataSource = self
        self.delegate = self
        self.tableView.contentInset.bottom = 100
        self.prepareTableView()
        self.prepareButton()
        self.queryForPosts()
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
        button.layer.shadowOffset = CGSize(width: 1, height: 1)
        button.layer.shadowRadius = 2
        button.setImage(Icon.Google.add, for: .normal)
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
            sender.setImage(Icon.Apple.like, for: .normal)
            self.posts[sender.tag].unliked(byUser: User.current()) { (success) in
                if !success {
                    // Reset if save failed
                    let likes = self.posts[sender.tag].likes
                    let likeCount = likes?.count ?? 0
                    sender.setTitle(" \(likeCount)", for: .normal)
                    sender.setImage(Icon.Apple.likeFilled, for: .normal)
                }
            }
        } else {
            sender.setTitle(" \(likes.count + 1)", for: .normal)
            sender.setImage(Icon.Apple.likeFilled, for: .normal)
            self.posts[sender.tag].liked(byUser: User.current()) { (success) in
                if !success {
                    // Reset if save failed
                    let likes = self.posts[sender.tag].likes
                    let likeCount = likes?.count ?? 0
                    sender.setTitle(" \(likeCount)", for: .normal)
                    sender.setImage(Icon.Apple.like, for: .normal)
                }
            }
        }
    }
    
    func addComment(sender: UIButton) {
        let detailVC = PostDetailViewController(post: self.posts[sender.tag])
        detailVC.textInputBar.textView.becomeFirstResponder()
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func handleMore(sender: UIButton) {
        let post = self.posts[sender.tag]
        if post.user.id == User.current().id {
            post.handleByOwner(target: self, delegate: self, sender: sender)
        } else {
            post.handle(target: self, sender: sender)
        }
    }
    
    // MARK: PostModificationDelegate
    
    func didUpdatePost() {
        self.posts.removeAll()
        self.reloadData()
        self.queryForPosts()
    }
    
    func didDeletePost() {
        self.posts.removeAll()
        self.reloadData()
        self.queryForPosts()
    }
    
    func createNewPost(sender: UIButton) {
        let navVC = UINavigationController(rootViewController: EditPostViewController())
        self.presentViewController(navVC, from: .bottom, completion: nil)
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
        if indexPath.section < self.posts.count {
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
                cell.accessoryButton.tag = indexPath.section
                cell.accessoryButton.setImage(Icon.Apple.moreVerticalFilled, for: .normal)
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
                let likes = self.posts[indexPath.section].likes ?? [String]()
                if likes.contains(User.current().id) {
                    cell.leftButton.setImage(Icon.Apple.likeFilled, for: .normal)
                } else {
                    cell.leftButton.setImage(Icon.Apple.like, for: .normal)
                }
                cell.leftButton.setTitle(" \(likes.count)", for: .normal)
                cell.leftButton.tag = indexPath.section
                cell.leftButton.addTarget(self, action: #selector(toggleLike(sender:)), for: .touchUpInside)
                let comments = self.posts[indexPath.section].comments
                let commentsCount = comments.count
                if commentsCount > 0 {
                    cell.centerButton.setImage(Icon.Apple.commentFilled, for: .normal)
                } else {
                    cell.centerButton.setImage(Icon.Apple.comment, for: .normal)
                }
                cell.centerButton.setTitle(" \(commentsCount)", for: .normal)
                cell.centerButton.tag = indexPath.section
                cell.centerButton.addTarget(self, action: #selector(addComment(sender:)), for: .touchUpInside)
                let createdAt = self.posts[indexPath.section].createdAt
                cell.rightButton.setTitle(String.mediumDateNoTime(date: createdAt ?? Date()), for: .normal)
                cell.rightButton.setTitleColor(UIColor.black, for: .normal)
                cell.rightButton.isEnabled = false
                return cell
            default:
                return NTTableViewCell()
            }
        } else {
            return NTTextViewCell()
        }
    }
    
    // MARK: NTTableViewDelegate
    
    func tableView(_ tableView: NTTableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = PostDetailViewController(post: self.posts[indexPath.section])
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == (self.numberOfSections(in: self.tableView) - 1) {
            Log.write(.status, "Loading more posts")
            //self.queryForPosts()
        }
    }
    
    // MARK: Data Connecter
    
    func queryForPosts() {
        if self.isQuerying {
            return
        } else {
            self.isQuerying = true
        }
        let postQuery = PFQuery(className: Engagement.current().queryName! + PF_POST_CLASSNAME)
        postQuery.skip = self.posts.count
        postQuery.limit = 10
        postQuery.includeKey(PF_POST_USER)
        postQuery.addDescendingOrder(PF_POST_CREATED_AT)
        postQuery.findObjectsInBackground { (objects, error) in
            guard let posts = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            for post in posts {
                self.posts.append(Cache.retrievePost(post))
            }
            self.reloadData()
            self.isQuerying = false
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    
    // MARK: DZNEmptyDataSetSource
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: Engagement.current().name ?? "Engage", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 36)])
    }
}

