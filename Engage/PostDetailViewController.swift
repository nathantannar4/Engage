//
//  PostDetailViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-19.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import Material

class PostDetailViewController: FormViewController, UITextFieldDelegate {
    
    var post: PFObject?
    var comments: [String]?
    var commentsDate: [NSDate]?
    var commentsUser: [PFUser]?
    var postUser: PFUser?
    var commentsUsernames = [String]()
    var commentsDates = [String]()
    var commentStrings = [String]()
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareToolbar()
        appMenuController.menu.views.first?.isHidden = true
        tableView.contentInset.bottom = 100
        
        postUser = post?.object(forKey: "user") as? PFUser
        
        comments = post?.object(forKey: "comments") as? [String]
        commentsUser = post?.object(forKey: "commentsUser") as? [PFUser]
        commentsDate = post?.object (forKey: "commentsDate") as? [NSDate]
        
        if (comments?.count)! > 0 {
            for user in commentsUser! {
                let userQuery = PFUser.query()
                userQuery?.whereKey("objectId", equalTo: user.objectId!)
                do {
                    let userFound = try userQuery?.findObjects().first
                    commentsUsernames.append((userFound?.value(forKey: "fullname") as? String)!)
                    
                } catch _ {
                    print("Error in finding User")
                }
                
            }
            for date in commentsDate! {
                commentsDates.append(Utilities.dateToString(time: date))
            }
            for comment in self.comments! {
                commentStrings.append(comment)
            }
        }
        
        configure()
    }
    
    private func prepareToolbar() {
        guard let tc = toolbarController else {
            return
        }
        tc.toolbar.title = ""
        tc.toolbar.detail = ""
        tc.toolbar.backgroundColor = MAIN_COLOR
        let backButton = IconButton(image: Icon.cm.arrowBack)
        backButton.tintColor = UIColor.white
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        appToolbarController.prepareToolbarCustom(left: [backButton], right: [])
    }
    
    @objc private func handleBackButton() {
        appToolbarController.pull(from: self)
    }
    
    let createMenu: ((String, (() -> Void)?) -> RowFormer) = { text, onSelected in
        return LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .systemFont(ofSize: 15)
            $0.accessoryType = .disclosureIndicator
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
    }
    
    @objc private func addComment() {
        
        if (Comment.new.comment != "" && Comment.new.comment != nil) {
            view.endEditing(true)
            post?.add(Comment.new.comment!, forKey: "comments")
            post?.add(NSDate(), forKey: "commentsDate")
            post?.add(PFUser.current()!, forKey: "commentsUser")
            post?.incrementKey("replies")
            post?.saveInBackground(block: { (success: Bool, error: Error?) in
                if error == nil {
                    PushNotication.sendPushNotificationMessage(self.postUser!.objectId!, text: "\(Profile.sharedInstance.name!) commented on your post")
                    for user in self.commentsUser! {
                        PushNotication.sendPushNotificationMessage(user.objectId!, text: "\(Profile.sharedInstance.name!) also commented on a post you replied to")
                    }
                    self.commentStrings.append(Comment.new.comment!)
                    self.commentsDates.append("Now")
                    self.commentsUsernames.append((PFUser.current()?.value(forKey: "fullname") as? String)!)
                    self.former.removeAll()
                    Comment.new.clear()
                    self.configure()
                    self.former.reload()
                }
            })
        }
    }
    
    // MARK: Private
    
    private lazy var zeroRow: LabelRowFormer<ImageCell> = {
        
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {_ in
            }.configure {
                $0.rowHeight = 0
        }
    }()
    
    private func configure() {
        
        let editVC = EditPostViewController()
        editVC.post = self.post
        
        let detailPostRow = CustomRowFormer<DetailPostCell>(instantiateType: .Nib(nibName: "DetailPostCell")) {
            if self.post![PF_POST_TO_OBJECT] != nil {
                $0.username.text = "\(self.postUser![PF_USER_FULLNAME] as! String) >> \((self.post![PF_POST_TO_OBJECT] as! PFObject).value(forKey: PF_SUBGROUP_NAME) as! String)"
            } else if self.post![PF_POST_TO_USER] != nil {
                $0.username.text = "\(self.postUser![PF_USER_FULLNAME] as! String) >> \((self.post![PF_POST_TO_USER] as! PFUser).value(forKey: PF_USER_FULLNAME) as! String)"
            } else {
                $0.username.text = self.postUser![PF_USER_FULLNAME] as? String
            }
            $0.info.font = RobotoFont.regular(with: 15.0)
            $0.info.text = self.post![PF_POST_INFO] as? String
            $0.school.text =  ""
            $0.school.textColor = MAIN_COLOR
            $0.iconView.layer.borderWidth = 1
            $0.iconView.layer.masksToBounds = false
            $0.iconView.layer.borderColor = UIColor.white.cgColor
            $0.iconView.clipsToBounds = true
            $0.iconView.layer.borderWidth = 2
            $0.iconView.layer.borderColor = MAIN_COLOR?.cgColor
            $0.iconView.backgroundColor = MAIN_COLOR
            $0.iconView.layer.cornerRadius = $0.iconView.frame.height/2
            $0.iconView.image = UIImage(named: "profile_blank")
            $0.date.text = Utilities.dateToString(time: self.post!.createdAt! as NSDate)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { (cell: CustomRowFormer<DetailPostCell>) in
                self.former.deselect(animated: true)
                if self.postUser?.objectId == PFUser.current()?.objectId {
                    let navVC = UINavigationController(rootViewController: editVC)
                    navVC.navigationBar.barTintColor = MAIN_COLOR!
                    appToolbarController.show(navVC, sender: self)
                } else {
                    let profileVC = PublicProfileViewController()
                    profileVC.user = self.postUser
                    let navVC = UINavigationController(rootViewController: profileVC)
                    navVC.navigationBar.barTintColor = MAIN_COLOR!
                    appToolbarController.show(navVC, sender: self)
                }
        }
        
        if Engagement.sharedInstance.engagement != nil {
            
            // Query to find current data
            let customQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
            customQuery.whereKey("user", equalTo: postUser!)
            customQuery.includeKey("subgroup")
            customQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                if error == nil {
                    if let user = users!.first {
                        let subgroup = user["subgroup"] as? PFObject
                        if subgroup != nil {
                            detailPostRow.cellUpdate({
                                $0.school.text = subgroup![PF_SUBGROUP_NAME] as? String
                            })
                        }
                    }
                }
            })
        }

    
        let imageToBeLoaded = postUser!["picture"] as? PFFile
        if imageToBeLoaded != nil {
            imageToBeLoaded!.getDataInBackground {(imageData: Data?, error: Error?) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        detailPostRow.cellUpdate {
                            $0.iconView.image = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
        
        if  self.post!["hasImage"] as? Bool == true {
            let imageToBeLoaded = self.post!["image"] as? PFFile
            if imageToBeLoaded != nil {
                imageToBeLoaded!.getDataInBackground {(imageData: Data?, error: Error?) -> Void in
                    if error == nil {
                        if let imageData = imageData {
                            editVC.image = UIImage(data: imageData)
                            var postImageRow = [LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
                                $0.displayImage.image = UIImage(data:imageData)!
                                $0.displayImage.contentMode = .scaleAspectFit
                                }.configure {
                                    $0.rowHeight = 200
                                }.onSelected({ (cell: LabelRowFormer<ImageCell>) in
                                    let agrume = Agrume(image: cell.cell.displayImage.image!)
                                    agrume.showFrom(self)
                                })]
                            self.image = UIImage(data: imageData)
                            self.former.insert(rowFormer: postImageRow[0], below: detailPostRow)
                            self.former.reload()
                            
                        }
                    }
                }
            }
        }
        
        let reportRow = LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = RobotoFont.regular(with: 10.0)
            }.configure {
                $0.rowHeight = 30
                $0.text = "Flag Post"
            }.onSelected { _ in
                self.former.deselect(animated: true)
                Post.flagPost(target: self, object: self.post!)
        }

        let postSection = SectionFormer(rowFormer: detailPostRow, reportRow)
        self.former.append(sectionFormer: postSection)
        
        if self.post![PF_POST_TO_OBJECT] != nil {
            self.former.insertUpdate(rowFormer: self.createMenu("View \((self.post![PF_POST_TO_OBJECT] as! PFObject).value(forKey: PF_SUBGROUP_NAME) as! String)") {
                self.former.deselect(animated: true)
                EngagementSubGroup.sharedInstance.subgroup = self.post![PF_POST_TO_OBJECT] as? PFObject
                EngagementSubGroup.sharedInstance.unpack()
                self.navigationController?.pushViewController(SubGroupDetailViewController(), animated: true)
            }, below: detailPostRow)
        } else if self.post![PF_POST_TO_USER] != nil {
            self.former.insertUpdate(rowFormer: self.createMenu("View \((self.post![PF_POST_TO_USER] as! PFUser).value(forKey: PF_USER_FULLNAME) as! String)") {
                self.former.deselect(animated: true)
                let vc = PublicProfileViewController()
                vc.user = self.post![PF_POST_TO_USER] as! PFUser
                self.navigationController?.pushViewController(vc, animated: true)
            }, below: detailPostRow)
        }
        
        
        var commentRows = [CustomRowFormer<DynamicHeightCell>]()
        var commentsExist = false
        
        for index in 0 ..< commentStrings.count {
            commentsExist = true
            commentRows.append(CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
                $0.title = self.commentsUsernames[index]
                $0.date = self.commentsDates[index]
                $0.body = self.commentStrings[index]
                $0.bodyLabel.font = RobotoFont.regular(with: 15.0)
                $0.titleColor = MAIN_COLOR
                }.configure {
                    $0.rowHeight = UITableViewAutomaticDimension
                }.onSelected({ (cell: CustomRowFormer<DynamicHeightCell>) in
                    self.former.deselect(animated: true)
                    
                    let profileVC = PublicProfileViewController()
                    
                    
                    // REWORK
                    let userQuery = PFUser.query()
                    userQuery?.whereKey("fullname", equalTo: cell.cell.title!)
                    do {
                        profileVC.user = try userQuery?.findObjects().first
                    } catch _ {}
                    self.navigationController?.pushViewController(profileVC, animated: true)
                }))
        }
        
        if commentsExist {
            self.former.append(sectionFormer: SectionFormer(rowFormers: commentRows).set(headerViewFormer: TableFunctions.createHeader(text: "Comments")))
            self.former.reload()
        }
        
        let commentRow = TextFieldRowFormer<FormTextFieldCell>() { [weak self] in
            Comment.new.post = self!.post
            $0.textField.textColor = .formerSubColor()
            $0.textField.font = RobotoFont.regular(with: 15.0)
            self?.addToolBar(textField: $0.textField)
            }.configure {
                $0.placeholder = "Add a comment"
                $0.rowHeight = 44
            }.onTextChanged {
                Comment.new.comment = $0
        }
        if commentsExist {
            self.former.append(sectionFormer: SectionFormer(rowFormer: commentRow))
            self.former.reload()
        } else {
            self.former.append(sectionFormer: SectionFormer(rowFormer: commentRow))
            self.former.reload()
        }
    }
    
    func addToolBar(textField: UITextField){
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = MAIN_COLOR
        let doneButton = UIBarButtonItem(title: "Comment", style: UIBarButtonItemStyle.done, target: self, action: #selector(addComment))
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

