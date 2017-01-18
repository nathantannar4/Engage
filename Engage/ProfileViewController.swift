//
//  DemoTableViewController.swift
//  NTUIKit Demo
//
//  Created by Nathan Tannar on 12/28/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Agrume
import Parse

class ProfileViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate {
    
    private var user: User!
    private var posts: [Post] = [Post]()
    
    // MARK: - Initializers
    public convenience init(user: User) {
        self.init()
        self.user = user
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.user.fullname
        self.dataSource = self
        self.delegate = self
        self.prepareTableView()
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
        self.tableView.contentInset.top = 190
        self.tableView.contentInset.bottom = 100
        self.tableView.emptyHeaderHeight = 10
        self.fadeInNavBarOnScroll = true
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    // MARK: User Action
    
    func createNewPost(sender: UIButton) {
        
    }
    
    func editProfile(sender: UIButton) {
        
    }
    
    func viewProfilePhoto() {
        guard let image = self.user.image else {
            return
        }
        let agrume = Agrume(image: image)
        agrume.showFrom(self)
    }
    
    // MARK: NTTableViewDataSource
    
    func tableView(_ tableView: NTTableView, cellForHeaderInSection section: Int) -> NTHeaderCell? {
        if section == 0 {
            return NTHeaderCell()
        } else if section == 2 {
            let header = NTHeaderCell.initFromNib()
            header.titleLabel.text = "Recent Posts"
            if self.user.id == User.current().id {
                header.actionButton.setTitle("New Post", for: .normal)
                header.actionButton.addTarget(self, action: #selector(createNewPost(sender:)), for: .touchUpInside)
            }
            return header
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: NTTableView, cellForFooterInSection section: Int) -> NTFooterCell? {
        return NTFooterCell()
    }
    
    func numberOfSections(in tableView: NTTableView) -> Int {
        return 2 + self.posts.count
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        if section >= 2 {
            return 4
        } else if section == 1 {
            return Engagement.current()?.profileFields?.count ?? 0
        }
        return 1
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if indexPath.section == 0 {
            let cell = NTProfileHeaderCell.initFromNib()
            cell.setDefaults()
            cell.image = self.user.image
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewProfilePhoto))
            cell.imageView.addGestureRecognizer(tapGesture)
            cell.name = self.user.fullname
            cell.title = ""
            cell.subtitle = ""
            if self.user.id == User.current().id {
                cell.rightButton.setImage(Icon.Apple.editFilled?.resizeImage(width: 25, height: 25, renderingMode: .alwaysTemplate), for: .normal)
                cell.rightButton.addTarget(self, action: #selector(editProfile(sender:)), for: .touchUpInside)
            }
            return cell
        } else if indexPath.section == 1 {
            let cell = NTLabeledCell.initFromNib()
            cell.horizontalInset = 10
            cell.cornerRadius = 5
            let rows = self.tableView(self.tableView, numberOfRowsInSection: indexPath.section)
            if indexPath.row == 0 {
                cell.cornersRounded = [.topLeft, .topRight]
            } else if indexPath.row == (rows - 1) {
                cell.cornersRounded = [.bottomLeft, .bottomRight]
            }
            cell.title = Engagement.current()?.profileFields?[indexPath.row]
            cell.text = self.user.userExtension!.field(forIndex: indexPath.row)
            return cell
        } else {
            let section = indexPath.section - 2
            switch indexPath.row {
            case 0:
                let cell = NTProfileCell.initFromNib()
                cell.setDefaults()
                cell.setImageViewDefaults()
                cell.imageView.layer.borderWidth = 1
                cell.imageView.layer.borderColor = Color.defaultButtonTint.cgColor
                cell.cornersRounded = [.topLeft, .topRight]
                cell.title = self.posts[section].user.fullname
                cell.image = self.posts[section].user.image
                cell.accessoryButton.setImage(Icon.Apple.moreVerticalFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
                cell.accessoryButton.addTarget(self, action: #selector(handleMore(sender:)), for: .touchUpInside)
                return cell
            case 1:
                let cell = NTImageCell.initFromNib()
                cell.horizontalInset = 10
                cell.contentImageView.layer.borderWidth = 2
                cell.contentImageView.layer.borderColor = UIColor.white.cgColor
                cell.contentImageView.layer.cornerRadius = 5
                cell.image = self.posts[section].image
                if cell.image == nil {
                    cell.contentImageView.removeFromSuperview()
                    cell.bounds = CGRect.zero
                }
                return cell
            case 2:
                let cell = NTDynamicHeightTextCell.initFromNib()
                cell.verticalInset = -5
                cell.horizontalInset = 10
                cell.text = self.posts[section].content
                return cell
            case 3:
                let cell = NTActionCell.initFromNib()
                cell.setDefaults()
                cell.cornersRounded = [.bottomLeft, .bottomRight]
                cell.leftButton.setImage(Icon.Apple.likeFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
                let likes = self.posts[section].likes
                let likeCount = likes?.count ?? 0
                cell.leftButton.setTitle(" \(likeCount)", for: .normal)
                cell.leftButton.tag = section
                cell.leftButton.addTarget(self, action: #selector(toggleLike(sender:)), for: .touchUpInside)
                cell.centerButton.setImage(Icon.Apple.commentFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
                let comments = self.posts[section].comments
                let commentsCount = comments?.count ?? 0
                cell.centerButton.setTitle(" \(commentsCount)", for: .normal)
                cell.centerButton.tag = section
                let createdAt = self.posts[section].createdAt
                cell.rightButton.setTitle(String.mediumDateNoTime(date: createdAt ?? Date()), for: .normal)
                cell.rightButton.setTitleColor(UIColor.black, for: .normal)
                cell.rightButton.isEnabled = false
                return cell
            default:
                return NTTableViewCell()
            }
        }
    }
    
    func imageForStretchyView(in tableView: NTTableView) -> UIImage? {
        return #imageLiteral(resourceName: "header")
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
    
    // MARK: Data Connecter
    
    func queryForPosts() {
        guard let engagement = Engagement.current() else {
            return
        }
        let postQuery = PFQuery(className: engagement.queryName! + PF_POST_CLASSNAME)
        postQuery.includeKey(PF_POST_USER)
        postQuery.addDescendingOrder(PF_POST_CREATED_AT)
        postQuery.whereKey(PF_POST_USER, equalTo: self.user.object)
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
            self.tableView.refreshControl?.endRefreshing()
        }
    }
}
