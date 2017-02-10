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

class ProfileViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate, PostModificationDelegate {
    
    private var user: User!
    private var posts: [Post] = [Post]()
    private var isQuerying: Bool = false
    
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
        self.tableView.emptyFooterHeight = 10
        if self.getNTNavigationContainer == nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Google.close, style: .plain, target: self, action: #selector(dismiss(sender:)))
        }
        self.prepareTableView()
        self.queryForPosts()
    }
    
    func pullToRefresh(sender: UIRefreshControl) {
        self.tableView.refreshControl?.beginRefreshing()
        self.updateUser()
    }
    
    // MARK: Preperation Functions 
    
    private func prepareTableView() {
        self.tableView.contentInset.top = 190
        self.tableView.contentInset.bottom = 100
        self.tableView.emptyHeaderHeight = 10
        self.fadeInNavBarOnScroll = true
        let refreshControl = UIRefreshControl()
        if self.user.coverImage != nil {
            refreshControl.tintColor = UIColor.white
            refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh", attributes: [NSForegroundColorAttributeName : UIColor.white])
        } else {
            refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        }
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    // MARK: User Action
    
    func logout(sender: UIButton) {
        User.current().logout(self)
    }
    
    func editProfile(sender: UIButton) {
        let navVC = UINavigationController(rootViewController: EditProfileViewController())
        self.present(navVC, animated: true, completion: nil)
    }
    
    func createNewPost(sender: UIButton) {
        let navVC = UINavigationController(rootViewController: EditPostViewController())
        self.present(navVC, animated: true, completion: nil)
    }
    
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
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(detailVC, animated: true)
        self.hidesBottomBarWhenPushed = false
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
    
    func didDeletePost() {
        self.pullToRefresh(sender: self.tableView.refreshControl!)
    }
    
    func didUpdatePost() {
        self.pullToRefresh(sender: self.tableView.refreshControl!)
    }
    
    func viewProfilePhoto() {
        guard let image = self.user.image else {
            return
        }
        let agrume = Agrume(image: image)
        agrume.showFrom(self)
    }
    
    func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: NTTableViewDataSource
    
    func tableView(_ tableView: NTTableView, cellForHeaderInSection section: Int) -> NTHeaderCell? {
        if section == 0 {
            return NTHeaderCell()
        } else if section == 3 {
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
        return 3 + self.posts.count
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            guard let userExt = User.current().userExtension else {
                return 0
            }
            return userExt.bio != nil ? 1 : 0
        } else if section == 2 {
            return (Engagement.current().profileFields?.count ?? 0) + 2
        } else {
            return 4
        }
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if indexPath.section == 0 {
            // User Header
            let cell = NTProfileHeaderCell.initFromNib()
            cell.setDefaults()
            cell.image = self.user.image
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewProfilePhoto))
            cell.imageView.addGestureRecognizer(tapGesture)
            cell.name = self.user.fullname
            cell.title = self.user.userExtension?.team?.name
            cell.subtitle = self.user.userExtension?.team?.position(forUser: self.user)
            if self.user.id == User.current().id {
                cell.leftButton.setTitle("Logout", for: .normal)
                cell.leftButton.addTarget(self, action: #selector(logout(sender:)), for: .touchUpInside)
                cell.rightButton.setImage(Icon.Apple.editFilled, for: .normal)
                cell.rightButton.addTarget(self, action: #selector(editProfile(sender:)), for: .touchUpInside)
            }
            return cell
        } else if indexPath.section == 1 {
            // Bio
            let cell = NTDynamicHeightTextCell.initFromNib()
            cell.setDefaults()
            cell.verticalInset = -10
            cell.contentLabel.textAlignment = .center
            cell.text = User.current().userExtension?.bio
            return cell
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                // Basic Contact Info
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.cornerRadius = 5
                let rows = self.tableView(self.tableView, numberOfRowsInSection: indexPath.section)
                if indexPath.row == 0 {
                    cell.cornersRounded = [.topLeft, .topRight]
                } else if indexPath.row == (rows - 1) {
                    cell.cornersRounded = [.bottomLeft, .bottomRight]
                }
                cell.title = "Email"
                cell.text = self.user.email
                return cell
            } else if indexPath.row == 1 {
                // Basic Contact Info
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.cornerRadius = 5
                let rows = self.tableView(self.tableView, numberOfRowsInSection: indexPath.section)
                if indexPath.row == (rows - 1) {
                    cell.cornersRounded = [.bottomLeft, .bottomRight]
                }
                cell.title = "Phone"
                cell.text = self.user.phone
                return cell
            } else {
                // User Extension Fields
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.cornerRadius = 5
                let rows = self.tableView(self.tableView, numberOfRowsInSection: indexPath.section)
                if indexPath.row == 0 {
                    cell.cornersRounded = [.topLeft, .topRight]
                } else if indexPath.row == (rows - 1) {
                    cell.cornersRounded = [.bottomLeft, .bottomRight]
                }
                cell.title = Engagement.current().profileFields?[indexPath.row - 2]
                cell.text = self.user.userExtension?.field(forIndex: indexPath.row - 2)
                return cell
            }
        } else {
            // User Posts
            let section = indexPath.section - 3
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
                cell.accessoryButton.tag = section
                cell.accessoryButton.setImage(Icon.Apple.moreVerticalFilled, for: .normal)
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
                let likes = self.posts[section].likes ?? [String]()
                if likes.contains(User.current().id) {
                    cell.leftButton.setImage(Icon.Apple.likeFilled, for: .normal)
                } else {
                    cell.leftButton.setImage(Icon.Apple.like, for: .normal)
                }
                cell.leftButton.setTitle(" \(likes.count)", for: .normal)
                cell.leftButton.tag = section
                cell.leftButton.addTarget(self, action: #selector(toggleLike(sender:)), for: .touchUpInside)
                let comments = self.posts[section].comments
                let commentsCount = comments.count
                if commentsCount > 0 {
                    cell.centerButton.setImage(Icon.Apple.commentFilled, for: .normal)
                } else {
                    cell.centerButton.setImage(Icon.Apple.comment, for: .normal)
                }
                cell.centerButton.setTitle(" \(commentsCount)", for: .normal)
                cell.centerButton.tag = section
                cell.centerButton.addTarget(self, action: #selector(addComment(sender:)), for: .touchUpInside)
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
        guard let image = self.user.coverImage else {
            self.fadeInNavBarOnScroll = false
            return nil
        }
        self.fadeInNavBarOnScroll = true
        self.tableView.refreshControl?.tintColor = UIColor.white
        self.tableView.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to Refresh", attributes: [NSForegroundColorAttributeName : UIColor.white])
        return image
    }
    
    // MARK: NTTableViewDelegate
    
    func tableView(_ tableView: NTTableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section >= 3 {
            if (indexPath.section - 3) <= (self.posts.count - 1) {
                let detailVC = PostDetailViewController(post: self.posts[indexPath.section - 3])
                self.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(detailVC, animated: true)
                self.hidesBottomBarWhenPushed = false
            }
        }
    }
    
    // MARK: Data Connecter
    
    func updateUser() {
        self.user.object.fetchInBackground { (object, error) in
            guard let updatedUser = object as? PFUser else {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: "Could not fetch update", button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 1.0)
                return
            }
            self.user = Cache.retrieveUser(updatedUser)
            self.reloadData()
            self.queryForPosts()
        }
    }
    
    func queryForPosts() {
        if self.isQuerying {
            return
        } else {
            self.isQuerying = true
        }
        self.posts.removeAll()
        let postQuery = PFQuery(className: Engagement.current().queryName! + PF_POST_CLASSNAME)
        postQuery.skip = self.posts.count
        postQuery.limit = 10
        postQuery.whereKey(PF_POST_USER, equalTo: self.user.object)
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
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
            self.isQuerying = false
        }
    }
}
