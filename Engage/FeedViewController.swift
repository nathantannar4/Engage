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
import Former

class FeedViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MenuDelegate {
    
    internal var querySkip = 0
    internal var addButton: FabButton!
    internal var sendButtonItem: MenuItem!
    internal var posts = [PFObject]()
    internal var postImages = [String: UIImage]()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.emptyDataSetSource = self;
        self.tableView.emptyDataSetDelegate = self
        self.tableView.backgroundColor = Color.grey.lighten3
        self.tableView.separatorStyle = .none
        self.tableView.contentInset.top = 10
        self.tableView.contentInset.bottom = 100
        self.tableView.estimatedRowHeight = 180
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(FeedViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl!)

        loadPosts()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appMenuController.menu.views.first?.isHidden = true
        prepareToolbar()
        prepareAddButton()
        prepareSendButton()
        prepareMenuController()
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let content = self.posts[indexPath.row].value(forKey: PF_POST_INFO) as! String
        var height: CGFloat = 20.0
        if (self.posts[indexPath.row].value(forKey: PF_POST_HAS_IMAGE) as! Bool) {
            height += 453.0
        } else {
            height += 153.0
        }
        if content.characters.count > 45 {
            height += 20.0
            if content.characters.count > 90 {
                height += 20.0
                if content.characters.count > 135 {
                    height += 20.0
                }
            }
        }
        return height
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
        let vc = PostDetailViewController()
        vc.post = self.posts[indexPath.row]
        appToolbarController.push(from: self, to: vc)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
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
        let commentButton = IconButton(image: UIImage(named: "comment")?.resize(toWidth: 25.0)?.withRenderingMode(.alwaysTemplate), tintColor: Color.gray)
        commentButton.titleColor = Color.gray
        commentButton.setTitle(" \(postObject.value(forKey: PF_POST_REPLIES) as! Int)", for: .normal)
        
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
        
        // Configure Cell
        cell.contentView.layout(card).horizontally(left: 10, right: 10).center()
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
            sender.object.saveInBackground()
            sender.tintColor = MAIN_COLOR
        }
        sender.setTitle(" \(likes!.count)", for: .normal)
    }
    
    // MARK: - UIImagePickerDelegate
    
    private func presentImagePicker() {
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
            //imageRow.cellUpdate {
            //    $0.iconView.image = image
            //}
        } else{
            print("Something went wrong")
            SVProgressHUD.showError(withStatus: "An Error Occurred")
        }
    }
    
    // Menu Controller
    // Handle the menu toggle event.
    internal func handleToggleMenu(button: Button) {
        guard let mc = menuController as? AppMenuController else {
            return
        }
        
        if mc.menu.isOpened {
            print("closeMenu")
            addButton.backgroundColor = MAIN_COLOR
            addButton.tintColor = UIColor.white
            mc.closeMenu { (view) in
                (view as? MenuItem)?.hideTitleLabel()
            }
        } else {
            print("openMenu")
            addButton.backgroundColor = Color.red.base
            addButton.tintColor = UIColor.white
            mc.openMenu { (view) in
                (view as? MenuItem)?.hideTitleLabel()
            }
        }
    }
    
    private func prepareAddButton() {
        addButton = FabButton(image: Icon.cm.add)
        addButton.tintColor = UIColor.white
        addButton.backgroundColor = MAIN_COLOR
        addButton.addTarget(self, action: #selector(handleToggleMenu), for: .touchUpInside)
    }
    
    private func prepareSendButton() {
        sendButtonItem = MenuItem()
        sendButtonItem.tintColor = UIColor.white
        sendButtonItem.button.image = Icon.check
        sendButtonItem.button.backgroundColor = Color.green.base
        sendButtonItem.button.depthPreset = .depth1
    }
    
    private func prepareMenuController() {
        guard let mc = menuController as? AppMenuController else {
            return
        }
        
        mc.menu.delegate = self
        mc.menu.views = [addButton, sendButtonItem]
    }
    
    func menu(menu: Menu, tappedAt point: CGPoint, isOutside: Bool) {
        guard isOutside else {
            return
        }
        
        guard let mc = menuController as? AppMenuController else {
            print("isMc")
            return
        }
        
        mc.closeMenu { (view) in
            (view as? MenuItem)?.hideTitleLabel()
        }
    }
}

extension String {
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return boundingBox.height
    }
}

class IconButtonWithObject: IconButton {
    var object: PFObject!
}
