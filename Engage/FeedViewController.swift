//
//  FeedViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-19.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Material
import DZNEmptyDataSet
import SVProgressHUD
import Parse
import ParseUI

class FeedViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MenuDelegate, UITextFieldDelegate {
    
    internal var querySkip = 0
    internal var addButton: FabButton!
    internal var posts = [PFObject]()
    internal var postImages = [String: UIImage]()
    internal var menuOpen = false
    internal var newPostView = UIView()
    internal var textField = UITextField()
    internal var postImageView = UIImageView()
    internal var addImageButton = UIButton()
    
    // Comments
    internal var commentIndex = 0
    internal var commentObjects = [commentObject()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.dismiss()
        
        tableView.emptyDataSetSource = self;
        tableView.emptyDataSetDelegate = self
        tableView.backgroundColor = Color.grey.lighten3
        tableView.separatorStyle = .none
        tableView.contentInset.bottom = 100
        tableView.estimatedRowHeight = 180
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = MAIN_COLOR
        refreshControl?.addTarget(self, action: #selector(FeedViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(self.refreshControl!)
        loadPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appMenuController.menu.views.first?.isHidden = false
        prepareToolbar()
        
        if !menuOpen {
            prepareAddButton()
            prepareMenuController()
        }
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        querySkip = 0
        loadPosts()
        refreshControl.endRefreshing()
    }
    
    private func prepareToolbar() {
        guard let tc = toolbarController else {
            return
        }
        tc.toolbar.title = "Activity Feed"
        tc.toolbar.titleLabel.textColor = UIColor.white
        tc.toolbar.detail = "All Posts"
        tc.toolbar.detailLabel.textColor = UIColor.white
        tc.toolbar.backgroundColor = MAIN_COLOR
        tc.toolbar.tintColor = UIColor.white
        appToolbarController.prepareToolbarMenu(right: [])
        appToolbarController.prepareBellButton()
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: Engagement.sharedInstance.name!)
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return Color.grey.lighten3
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if menuOpen {
            return 150
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        newPostView.isHidden = false
        return newPostView
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let content = self.posts[indexPath.row].value(forKey: PF_POST_INFO) as! String
        let contentCount = content.characters.count
        var height: CGFloat = 180
        if tableView.isEditing {
            return height
        }
        if (self.posts[indexPath.row].value(forKey: PF_POST_HAS_IMAGE) as! Bool) {
            height += 210
        }
        if UIDevice.current.modelName == "iPhone 6 Plus" || UIDevice.current.modelName == "iPhone 6s Plus" || UIDevice.current.modelName == "iPhone 7 Plus" {
            // 5.5 Inch Screen
            var count = 50
            while count < contentCount {
                height += 20
                count += 50
            }
            return height
        } else if UIDevice.current.modelName == "iPhone 6" || UIDevice.current.modelName == "iPhone 6s" || UIDevice.current.modelName == "iPhone 7" || UIDevice.current.modelName == "Simulator" {
            // 4.7 Inch Screen & Simulator
            var count = 45
            while count < contentCount {
                height += 20
                count += 45
            }
            return height
        } else {
            // 4 Inch Screen
            var count = 35
            while count < contentCount {
                height += 20
                count += 35
            }
            return height
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        if(y > h) {
            if self.posts.count >= (10 + querySkip) {
                print("load more rows")
                querySkip += 10
                loadPosts()
            }
        }
    }
    
    private func loadPosts() {
        print("loadingData")
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Posts")
        query.limit = 10
        query.skip = self.querySkip
        query.order(byDescending: "createdAt")
        query.includeKey(PF_POST_USER)
        query.includeKey(PF_POST_TO_OBJECT)
        query.includeKey(PF_POST_TO_USER)
        query.findObjectsInBackground { (loadedPosts: [PFObject]?, error: Error?) in
            print("finishedLoadingData")
            if error == nil {
                if self.querySkip == 0 {
                    self.posts.removeAll()
                }
                if loadedPosts != nil && (loadedPosts?.count)! > 0 {
                    for post in loadedPosts! {
                        self.posts.append(post)
                    }
                    if loadedPosts!.count != 10 {
                        self.querySkip -= (10 - loadedPosts!.count)
                    }
                    self.tableView.reloadData()
                }
            } else {
                print(error.debugDescription)
                SVProgressHUD.showError(withStatus: "Network Error")
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //closeMenu()
        let vc = PostDetailViewController()
        vc.post = self.posts[indexPath.row]
        appToolbarController.push(from: self, to: vc)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if tableView.isEditing {
            let card = Card()
            
            // Content
            //***********
            let contentView = UILabel()
            contentView.numberOfLines = 0
            contentView.text = self.commentObjects[commentIndex].getComment()
            contentView.font = RobotoFont.regular(with: 15)
            
            // Toolbar Bar
            //***********
            let dateLabel = UILabel()
            dateLabel.font = RobotoFont.regular(with: 13)
            dateLabel.textColor = Color.gray
            dateLabel.text = self.commentObjects[commentIndex].getDateString()
            dateLabel.textAlignment = .right
            
            let usernameLabel = UILabel()
            usernameLabel.font = RobotoFont.regular(with: 15)
            usernameLabel.textColor = MAIN_COLOR
            usernameLabel.text = self.commentObjects[commentIndex].getUsername()
            usernameLabel.textAlignment = .left
            
            let toolbar = Toolbar()
            toolbar.rightViews = [dateLabel]
            toolbar.leftViews = [usernameLabel]
            
            // Configure Card
            card.contentView = contentView
            card.contentViewEdgeInsetsPreset = .wideRectangle2
            card.toolbar = toolbar
            card.toolbarEdgeInsetsPreset = .wideRectangle2
            cell.contentView.layout(card).horizontally(left: 10, right: 10).center()
            
            commentIndex += 1
        } else {
            let card = PresenterCard()
            let postObject = self.posts[indexPath.row]
            let user = postObject.value(forKey: PF_POST_USER) as! PFUser
            
            // Toolbar
            //***********
            let userImageView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            let userImage = PFImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            userImage.image = UIImage(named: "profile_blank")
            userImage.file = user[PF_USER_PICTURE] as? PFFile
            userImage.loadInBackground()
            userImage.layer.borderWidth = 1
            userImage.layer.masksToBounds = true
            userImage.layer.borderColor = MAIN_COLOR?.cgColor
            userImage.layer.cornerRadius = userImage.frame.height/2
            userImageView.addSubview(userImage)
            
            // More Button
            let moreButton = IconButtonWithObject(image: Icon.cm.moreVertical, tintColor: Color.gray)
            moreButton.object = postObject
            moreButton.addTarget(self, action: #selector(handleMore(sender:)), for: .touchUpInside)
            
            let toolbar = Toolbar(leftViews: [userImageView, UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 0))], rightViews: [moreButton], centerViews: [])
            
            // User Label
            toolbar.title = user.value(forKey: PF_USER_FULLNAME) as? String
            toolbar.titleLabel.textAlignment = .left
            toolbar.detail = "..."
            let customQuery = PFQuery(className: "WESST_User")
            customQuery.whereKey("user", equalTo: user)
            customQuery.includeKey("subgroup")
            customQuery.cachePolicy = .cacheElseNetwork
            customQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                if error == nil {
                    if let user = users!.first {
                        let subgroup = user["subgroup"] as? PFObject
                        if subgroup != nil {
                            toolbar.detail = subgroup!.value(forKey: PF_SUBGROUP_NAME) as? String
                        } else {
                            toolbar.detail = ""
                        }
                    }
                }
            })
            toolbar.detailLabel.textAlignment = .left
            toolbar.detailLabel.textColor = Color.gray
            
            // Content
            //***********
            let contentView = UILabel()
            contentView.numberOfLines = 0
            contentView.text = postObject.value(forKey: PF_POST_INFO) as? String
            contentView.font = RobotoFont.regular(with: 15)
            
            // Bottom Bar
            //***********
            // Date Label
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            let dateLabel = UILabel()
            dateLabel.font = RobotoFont.regular(with: 13)
            dateLabel.textColor = Color.gray
            dateLabel.text = dateFormatter.string(from: self.posts[indexPath.row].createdAt!)
            dateLabel.textAlignment = .right
            
            // Like Button
            let likeButton = IconButtonWithObject(image: UIImage(named: "like")?.resize(toWidth: 25.0)?.withRenderingMode(.alwaysTemplate), tintColor: Color.gray)
            likeButton.object = self.posts[indexPath.row]
            if self.posts[indexPath.row].value(forKey: PF_POST_LIKES) != nil {
                if ((self.posts[indexPath.row].value(forKey: PF_POST_LIKES) as! [String]).contains(PFUser.current()!.objectId!)) {
                    likeButton.tintColor = MAIN_COLOR
                }
            } else {
                likeButton.tintColor = Color.gray
            }
            likeButton.titleColor = Color.gray
            let likes = (postObject.value(forKey: PF_POST_LIKES) as? [String])?.count
            if likes != nil {
                likeButton.setTitle(" \(likes!)", for: .normal)
            }
            likeButton.addTarget(self, action: #selector(handleLike(sender:)), for: .touchUpInside)
            
            // Comment Button
            let commentButton = IconButtonWithObject(image: UIImage(named: "comment")?.resize(toWidth: 25.0)?.withRenderingMode(.alwaysTemplate), tintColor: Color.gray)
            commentButton.titleColor = Color.gray
            commentButton.object = self.posts[indexPath.row]
            commentButton.isEnabled = false
            commentButton.setTitle(" \(postObject.value(forKey: PF_POST_REPLIES) as! Int)", for: .normal)
            commentButton.addTarget(self, action: #selector(handleComment(sender:)), for: .touchUpInside)
            
            // Bottom Bar
            let bottomBar = Bar()
            bottomBar.leftViews = [likeButton, commentButton]
            bottomBar.rightViews = [dateLabel]
            
            // Image View
            if (postObject.value(forKey: PF_POST_HAS_IMAGE) as! Bool) {
                if self.postImages[postObject.objectId!] == nil {
                    let imageFile = self.posts[indexPath.row].value(forKey: PF_POST_IMAGE) as! PFFile
                    imageFile.getDataInBackground(block: { (data: Data?, error: Error?) in
                        if error == nil {
                            let presenterView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                            var image = UIImage(data: data!)
                            self.postImages[postObject.objectId!] = image
                            image = image?.resize(toHeight: 300)
                            presenterView.image = image
                            presenterView.contentMode = .scaleAspectFit
                            presenterView.layer.masksToBounds = true
                            card.presenterView = presenterView
                            card.presenterViewEdgeInsetsPreset = .wideRectangle3
                        }
                    })
                } else {
                    let presenterView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                    var image = self.postImages[postObject.objectId!]
                    image = image?.resize(toHeight: 300)
                    presenterView.image = image
                    presenterView.contentMode = .scaleAspectFit
                    presenterView.layer.masksToBounds = true
                    card.presenterView = presenterView
                    card.presenterViewEdgeInsetsPreset = .wideRectangle3
                }
            }
            
            // Configure Card
            card.toolbar = toolbar
            card.toolbarEdgeInsetsPreset = .square3
            card.toolbarEdgeInsets.bottom = 0
            card.toolbarEdgeInsets.right = 8
            card.contentView = contentView
            card.contentViewEdgeInsetsPreset = .wideRectangle3
            card.bottomBar = bottomBar
            card.bottomBarEdgeInsetsPreset = .wideRectangle3
            card.bottomBarEdgeInsets.left = 0
            cell.contentView.layout(card).horizontally(left: 10, right: 10).center()
        }
        // Configure Cell
        cell.selectionStyle = .none
        cell.backgroundColor = Color.grey.lighten3
        return cell
    }
    
    func handleMore(sender: IconButtonWithObject) {
        let post = sender.object!
        let postUser = post.object(forKey: "user") as! PFUser
        if postUser.objectId! != PFUser.current()!.objectId! {
            Post.flagPost(target: self, object: post)
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = MAIN_COLOR
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            let editAction: UIAlertAction = UIAlertAction(title: "Edit", style: .default) { action -> Void in
                let vc = EditPostViewController()
                vc.post = sender.object!
                vc.image = self.postImages[sender.object!.objectId!]
                let navVC = UINavigationController(rootViewController: vc)
                navVC.navigationBar.barTintColor = MAIN_COLOR!
                appToolbarController.show(navVC, sender: self)
            }
            actionSheetController.addAction(editAction)
            
            let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { action -> Void in
                let alert = UIAlertController(title: "Are you sure?", message: "This cannot be undone.", preferredStyle: UIAlertControllerStyle.alert)
                alert.view.tintColor = MAIN_COLOR
                //Create and add the Cancel action
                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                    //Do some stuff
                }
                
                alert.addAction(cancelAction)
                let delete: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { action -> Void in
                    sender.object!.deleteInBackground(block: { (success: Bool, error: Error?) in
                        if success {
                            SVProgressHUD.showSuccess(withStatus: "Post Deleted")
                            let index = self.posts.index(of: sender.object!)
                            if index != nil {
                                self.posts.remove(at: index!)
                                self.tableView.reloadData()
                            } else {
                                print("Index Nil")
                            }
                        } else {
                            SVProgressHUD.showError(withStatus: "Network Error")
                        }
                    })
                }
                alert.addAction(delete)
                self.present(alert, animated: true, completion: nil)
            }
            actionSheetController.addAction(deleteAction)
            
            actionSheetController.popoverPresentationController?.sourceView = self.view
            //Present the AlertController
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
    
    func handleComment(sender: IconButtonWithObject) {
        commentIndex = 0
        var comments = sender.object.value(forKey: "comments") as? [String]
        let commentsUser = sender.object.value(forKey: "commentsUser") as? [PFUser]
        var commentsDate = sender.object.value (forKey: "commentsDate") as? [Date]
        
        if (comments!.count) > 0 {
            var index = 0
            var userIds = [String]()
            for user in commentsUser! {
                userIds.append(user.objectId!)
            }
            let userQuery = PFUser.query()
            userQuery?.whereKey(PF_USER_OBJECTID, containedIn: userIds)
            userQuery?.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                if error == nil {
                    if let users = users {
                        self.commentObjects.removeAll()
                        for user in users {
                            let downloadedComment = commentObject()
                            print(user)
                            downloadedComment.initialize(commentString: comments![index], usernnameString: user.value(forKey: PF_USER_FULLNAME) as! String, userIdString: user.objectId!, commentDate: commentsDate![index])
                            self.commentObjects.append(downloadedComment)
                            index += 1
                        }
                        // Reload Table
                        //self.tableView.beginUpdates()
                        self.tableView.reloadData()
                        //self.tableView.endUpdates()
                    }
                } else {
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            })
        }
    }
    
    func handleLike(sender: IconButtonWithObject) {
        var likes = sender.object.value(forKey: PF_POST_LIKES) as? [String]
        if likes == nil {
            likes = [String]()
        }
        if likes!.contains(PFUser.current()!.objectId!) {
            print("unlike \(sender.object.objectId!)")
            let index = likes?.index(of: PFUser.current()!.objectId!)
            if index != nil {
                likes?.remove(at: index!)
                sender.object[PF_POST_LIKES] = likes
                sender.object.saveInBackground()
                sender.tintColor = Color.gray
            }
        } else {
            print("like \(sender.object.objectId!)")
            likes?.append(PFUser.current()!.objectId!)
            sender.object[PF_POST_LIKES] = likes
            sender.object.saveInBackground(block: { (success: Bool, error: Error?) in
                if success {
                    let user = sender.object.value(forKey: "user") as! PFUser
                    PushNotication.sendPushNotificationMessage(user.objectId!, text: "\(Profile.sharedInstance.name!) liked your post")
                } else {
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            })
            sender.tintColor = MAIN_COLOR
        }
        sender.setTitle(" \(likes!.count)", for: .normal)
    }
    
    // MARK: - UIImagePickerDelegate
    
    @objc private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.navigationBar.barTintColor = MAIN_COLOR
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            Post.new.image = image
            Post.new.hasImage = true
            postImageView.image = image
        } else{
            print("Something went wrong")
            SVProgressHUD.showError(withStatus: "An Error Occurred")
        }
    }
    
    // Menu Controller
    // Handle the menu toggle event.
    private func closeMenu() {
        guard let mc = menuController as? AppMenuController else {
            return
        }
        menuOpen = false
        mc.menu.views.first?.animate(animation: Motion.rotate(angle: 0))
        mc.menu.views.first?.backgroundColor = MAIN_COLOR
        tableView.reloadData()
    }
    
    private func openMenu() {
        guard let mc = menuController as? AppMenuController else {
            return
        }
        menuOpen = true
        mc.menu.views.first?.animate(animation: Motion.rotate(angle: 45))
        mc.menu.views.first?.backgroundColor = UIColor.flatRed()
        mc.menu.open()
        Post.new.clear()
        prepareNewPostRow()
        tableView.reloadData()
    }
    
    @objc private func handleToggleMenu(button: Button) {
        if menuOpen {
            closeMenu()
            
        } else {
            openMenu()
        }
    }
    
    @objc private func handleSendButton() {
        if textField.text!.isNotEmpty {
            view.endEditing(true)
            Post.new.info = textField.text
            Post.new.createPost(object: nil, completion: {
                self.closeMenu()
                self.handleRefresh(self.refreshControl!)
            })
        }
    }
    
    private func prepareNewPostRow() {
        newPostView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 130)
        newPostView.backgroundColor = UIColor.white
        
        textField.frame = CGRect(x: 10, y: 0, width: self.view.frame.width - 10, height: 60)
        textField.placeholder = "What's new \(Profile.sharedInstance.name!)?"
        textField.font = RobotoFont.regular(with: 15.0)
        textField.text = ""
        addToolBar(textField: textField)
        newPostView.addSubview(textField)
        
        postImageView.frame = CGRect(x: 10, y: 65, width: 60, height: 60)
        postImageView.image = UIImage()
        postImageView.layer.borderWidth = 1
        postImageView.layer.masksToBounds = true
        postImageView.backgroundColor = MAIN_COLOR
        postImageView.layer.borderColor = MAIN_COLOR?.cgColor
        postImageView.layer.cornerRadius = postImageView.frame.height/2
        newPostView.addSubview(postImageView)
        
        addImageButton.frame = CGRect(x: 70, y: 65, width: 180, height: 60)
        let buttonTitle = NSAttributedString(string: "Add Image to Post", attributes: [NSForegroundColorAttributeName : MAIN_COLOR! as UIColor, NSFontAttributeName: RobotoFont.medium(with: 15)])
        addImageButton.setAttributedTitle(buttonTitle, for: UIControlState.normal)
        addImageButton.setTitleColor(MAIN_COLOR, for: UIControlState.normal)
        addImageButton.addTarget(self, action: #selector(presentImagePicker), for: .touchUpInside)
        newPostView.addSubview(addImageButton)
        
        let divider = UILabel(frame: CGRect(x: 0, y: 145, width: self.view.frame.width, height: 5))
        divider.backgroundColor = MAIN_COLOR
        newPostView.addSubview(divider)
    }
    
    private func prepareAddButton() {
        addButton = FabButton(image: Icon.cm.add)
        addButton.tintColor = UIColor.white
        addButton.backgroundColor = MAIN_COLOR
        addButton.addTarget(self, action: #selector(handleToggleMenu), for: .touchUpInside)
    }
    
    private func prepareMenuController() {
        guard let mc = menuController as? AppMenuController else {
            return
        }
        
        mc.menu.delegate = self
        mc.menu.views = [addButton]
    }
    
    func addToolBar(textField: UITextField){
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = MAIN_COLOR
        let doneButton = UIBarButtonItem(title: "Post", style: UIBarButtonItemStyle.done, target: self, action: #selector(handleSendButton))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancelPressed))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        toolBar.sizeToFit()
        
        textField.delegate = self
        textField.inputAccessoryView = toolBar
    }
    
    func cancelPressed(){
        view.endEditing(true)
    }
}

class IconButtonWithObject: IconButton {
    var object: PFObject!
}

class commentObject {
    private var comment: String!
    private var username: String!
    private var userId: String!
    private var date: Date!
    
    func initialize(commentString: String, usernnameString: String, userIdString: String, commentDate: Date) {
        comment = commentString
        username = usernnameString
        userId = userIdString
        date = commentDate
    }
    
    func getComment() -> String {
        return comment
    }
    
    func getUsername() -> String {
        return username
    }
    
    func getUserId() -> String {
        return userId
    }
    
    func getDateString() -> String {
        return Utilities.dateToString(time: date as NSDate)
    }
}
