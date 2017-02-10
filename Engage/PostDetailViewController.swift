//
//  PostDetailViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/29/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import Agrume
import ALTextInputBar

class PostDetailViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate, ALTextInputBarDelegate, PostModificationDelegate {

    private var post: Post!
    let textInputBar = ALTextInputBar()
    let keyboardObserver = ALKeyboardObservingView()
    
    // MARK: - Initializers
    public convenience init(post: Post) {
        self.init()
        self.post = post
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        self.prepareTableView()
        self.prepareTextInputBar()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.dismissToolbar()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.textInputBar.frame.size.width = self.view.bounds.size.width
    }
    
    func pullToRefresh(sender: UIRefreshControl) {
        self.tableView.refreshControl?.beginRefreshing()
        self.dismissToolbar()
        self.updatePost()
    }
    
    // MARK: Preperation Functions
    
    private func prepareTableView() {
        self.tableView.contentInset.bottom = 60
        self.tableView.emptyHeaderHeight = 10
        self.tableView.emptyFooterHeight = 10
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    func prepareTextInputBar() {
        let leftButton  = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        
        leftButton.setImage(Icon.Google.close, for: .normal)
        rightButton.setTitle("Comment", for: .normal)
        
        leftButton.addTarget(self, action: #selector(dismissToolbar), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(sendComment), for: .touchUpInside)
        
        self.keyboardObserver.isUserInteractionEnabled = false
        self.tableView.keyboardDismissMode = .interactive
        self.textInputBar.showTextViewBorder = true
        self.textInputBar.leftView = leftButton
        self.textInputBar.rightView = rightButton
        self.textInputBar.frame = CGRect(x: 0, y: view.frame.size.height - textInputBar.defaultHeight, width: view.frame.size.width, height: textInputBar.defaultHeight)
        self.textInputBar.keyboardObserver = keyboardObserver
        self.textInputBar.textView.placeholder = "Add a comment..."
        self.textInputBar.delegate = self
        
        self.view.addSubview(self.textInputBar)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameChanged(notification:)), name: NSNotification.Name(rawValue: ALKeyboardFrameDidChangeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // MARK: User Actions
    
    func toggleLike(sender: UIButton) {
        guard let likes = self.post.likes else {
            return
        }
        if likes.contains(User.current().id) {
            sender.setTitle(" \(likes.count - 1)", for: .normal)
            sender.setImage(Icon.Apple.like, for: .normal)
            self.post.unliked(byUser: User.current()) { (success) in
                if !success {
                    // Reset if save failed
                    let likes = self.post.likes
                    let likeCount = likes?.count ?? 0
                    sender.setTitle(" \(likeCount)", for: .normal)
                    sender.setImage(Icon.Apple.likeFilled, for: .normal)
                }
            }
        } else {
            sender.setTitle(" \(likes.count + 1)", for: .normal)
            sender.setImage(Icon.Apple.likeFilled, for: .normal)
            self.post.liked(byUser: User.current()) { (success) in
                if !success {
                    // Reset if save failed
                    let likes = self.post.likes
                    let likeCount = likes?.count ?? 0
                    sender.setTitle(" \(likeCount)", for: .normal)
                    sender.setImage(Icon.Apple.like, for: .normal)
                }
            }
        }
    }
    
    func addComment(sender: UIButton) {
        self.textInputBar.textView.becomeFirstResponder()
    }
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func sendComment() {
        let newComment = Comment(user: User.current(), text: self.textInputBar.text, date: Date())
        self.post.addComment(newComment) { (success) in
            if success {
                self.textInputBar.text = String()
                self.dismissToolbar()
                self.reloadData()
            }
        }
    }
    
    func handleMore(sender: UIButton) {
        if self.post.user.id == User.current().id {
            self.post.handleByOwner(target: self, delegate: self, sender: sender)
        } else {
            self.post.handle(target: self, sender: sender)
        }
    }
    
    // MARK: PostModificationDelegate
    
    func didUpdatePost() {
        self.post = Cache.retrievePost(self.post.object)
        self.reloadData()
    }
    
    func didDeletePost() {
        self.getNTNavigationContainer?.setCenterView(newView: ActivityFeedViewController())
    }
    
    // MARK: NTTableViewDataSource
    
    func tableView(_ tableView: NTTableView, cellForHeaderInSection section: Int) -> NTHeaderCell? {
        if section == 0 {
            return NTHeaderCell()
        }
        if section == 1 {
            let header = NTHeaderCell.initFromNib()
            header.title = "Comments"
            return header
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: NTTableView, cellForFooterInSection section: Int) -> NTFooterCell? {
        return NTFooterCell()
    }
    
    func numberOfSections(in tableView: NTTableView) -> Int {
        return 1 + self.post.comments.count
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        } else {
            return 3
        }
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if indexPath.section == 0 {
            // Post
            switch indexPath.row {
            case 0:
                let cell = NTProfileCell.initFromNib()
                cell.setDefaults()
                cell.setImageViewDefaults()
                cell.imageView.layer.borderWidth = 1
                cell.imageView.layer.borderColor = Color.defaultButtonTint.cgColor
                cell.cornersRounded = [.topLeft, .topRight]
                cell.title = self.post.user.fullname
                cell.image = self.post.user.image
                
                cell.accessoryButton.setImage(Icon.Apple.moreVerticalFilled, for: .normal)
                cell.accessoryButton.addTarget(self, action: #selector(handleMore(sender:)), for: .touchUpInside)
                return cell
            case 1:
                let cell = NTImageCell.initFromNib()
                cell.horizontalInset = 10
                cell.contentImageView.layer.borderWidth = 2
                cell.contentImageView.layer.borderColor = UIColor.white.cgColor
                cell.contentImageView.layer.cornerRadius = 5
                cell.image = self.post.image
                
                if cell.image == nil {
                    cell.contentImageView.removeFromSuperview()
                    cell.bounds = CGRect.zero
                }
                return cell
            case 2:
                let cell = NTDynamicHeightTextCell.initFromNib()
                cell.verticalInset = -5
                cell.horizontalInset = 10
                cell.text = self.post.content
                return cell
            case 3:
                let cell = NTActionCell.initFromNib()
                cell.setDefaults()
                cell.cornersRounded = [.bottomLeft, .bottomRight]
                let likes = self.post.likes ?? [String]()
                if likes.contains(User.current().id) {
                    cell.leftButton.setImage(Icon.Apple.likeFilled, for: .normal)
                } else {
                    cell.leftButton.setImage(Icon.Apple.like, for: .normal)
                }
                cell.leftButton.setTitle(" \(likes.count)", for: .normal)
                cell.leftButton.tag = indexPath.section
                cell.leftButton.addTarget(self, action: #selector(toggleLike(sender:)), for: .touchUpInside)
                let comments = self.post.comments
                let commentsCount = comments.count
                if commentsCount > 0 {
                    cell.centerButton.setImage(Icon.Apple.commentFilled, for: .normal)
                } else {
                    cell.centerButton.setImage(Icon.Apple.comment, for: .normal)
                }
                cell.centerButton.setTitle(" \(commentsCount)", for: .normal)
                cell.centerButton.tag = indexPath.section
                cell.centerButton.addTarget(self, action: #selector(addComment(sender:)), for: .touchUpInside)
                let createdAt = self.post.createdAt
                cell.rightButton.setTitle(String.mediumDateNoTime(date: createdAt ?? Date()), for: .normal)
                cell.rightButton.setTitleColor(UIColor.black, for: .normal)
                cell.rightButton.isEnabled = false
                return cell
            default:
                return NTTableViewCell()
            }
        } else {
            // Comment Row
            switch indexPath.row {
            case 0:
                let cell = NTDynamicHeightTextCell.initFromNib()
                cell.verticalInset = -5
                cell.horizontalInset = 10
                cell.cornersRounded = [.topLeft, .topRight]
                cell.text = self.post.comments[indexPath.section - 1].user.fullname
                cell.contentLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightMedium)
                return cell
            case 1:
                let cell = NTDynamicHeightTextCell.initFromNib()
                cell.verticalInset = -5
                cell.horizontalInset = 10
                cell.text = self.post.comments[indexPath.section - 1].text
                cell.contentLabel.font = UIFont.systemFont(ofSize: 12)
                return cell
            case 2:
                let cell = NTDynamicHeightTextCell.initFromNib()
                cell.verticalInset = -5
                cell.horizontalInset = 10
                cell.cornersRounded = [.bottomLeft, .bottomRight]
                cell.text = String.timeElapsedSince(self.post.comments[indexPath.section - 1].date)
                cell.contentLabel.font = UIFont.systemFont(ofSize: 9)
                cell.contentLabel.textAlignment = .right
                return cell
            default:
                return NTTextViewCell()
            }
        }
    }
    
    // MARK: NTTableViewDelegate
    
    func tableView(_ tableView: NTTableView, didSelectRowAt indexPath: IndexPath) {
        if self.textInputBar.textView.isFirstResponder {
            self.dismissToolbar()
            return
        }
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let profileVC = ProfileViewController(user: self.post.user)
                self.present(UINavigationController(rootViewController: profileVC), animated: true, completion: nil)
            } else if indexPath.row == 1 {
                guard let image = self.post.image else {
                    return
                }
                let agrume = Agrume(image: image)
                agrume.showFrom(self)
            }
        } else {
            let profileVC = ProfileViewController(user: self.post.comments[indexPath.section - 1].user)
            self.present(UINavigationController(rootViewController: profileVC), animated: true, completion: nil)
        }
    }
    
    
    // MARK: Data Connecter
    
    func updatePost() {
        self.post.object.fetchInBackground { (object, error) in
            guard let updatedPost = object else {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: "Could not fetch updated", button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 1.0)
                return
            }
            self.post = Cache.retrievePost(updatedPost)
            self.tableView.refreshControl?.endRefreshing()
            self.reloadData()
        }
    }
    
    // MARK: ALTextInputBar
    
    override var inputAccessoryView: UIView? {
        get {
            return self.keyboardObserver
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func dismissToolbar() {
        self.textInputBar.textView.resignFirstResponder()
    }
    
    func keyboardFrameChanged(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let frame = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
            if self.view.frame.width > self.view.frame.height {
                self.textInputBar.frame.origin.y = frame.origin.y - self.textInputBar.defaultHeight
            } else {
                self.textInputBar.frame.origin.y = frame.origin.y - 60
            }
            
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let frame = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
            if self.view.frame.width > self.view.frame.height {
                self.textInputBar.frame.origin.y = frame.origin.y - self.textInputBar.defaultHeight
            } else {
                self.textInputBar.frame.origin.y = frame.origin.y - 60
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let frame = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
            if self.view.frame.width > self.view.frame.height {
                self.textInputBar.frame.origin.y = frame.origin.y - self.textInputBar.defaultHeight
            } else {
                self.textInputBar.frame.origin.y = frame.origin.y - 60
            }
        }
    }
}
