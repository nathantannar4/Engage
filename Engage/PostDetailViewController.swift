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

class PostDetailViewController: FormViewController {
    
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
        
        // Configure UI
        title = ""
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 50
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post Comment", style: .plain, target: self, action: #selector(addComment))
        
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
    
    func addComment(sender: AnyObject?) {
        
        if (Comment.new.comment != "" && Comment.new.comment != nil) {
            post?.add(Comment.new.comment!, forKey: "comments")
            post?.add(NSDate(), forKey: "commentsDate")
            post?.add(PFUser.current()!, forKey: "commentsUser")
            post?.incrementKey("replies")
            post?.saveInBackground(block: { (success: Bool, error: Error?) in
                if error == nil {
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
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
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
            $0.info.font = .systemFont(ofSize: 16)
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
                    self.navigationController?.pushViewController(editVC, animated: true)
                } else {
                    let profileVC = PublicProfileViewController()
                    profileVC.user = self.postUser
                    self.navigationController?.pushViewController(profileVC, animated: true)
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
        
        let postSection = SectionFormer(rowFormer: detailPostRow)
        self.former.append(sectionFormer: postSection)
        
        if  self.post!["hasImage"] as? Bool == true {
            let imageToBeLoaded = self.post!["image"] as? PFFile
            if imageToBeLoaded != nil {
                imageToBeLoaded!.getDataInBackground {(imageData: Data?, error: Error?) -> Void in
                    if error == nil {
                        if let imageData = imageData {
                            editVC.image = UIImage(data: imageData)
                            var postImageRow = [LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
                                $0.displayImage.image = UIImage(data:imageData)!
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

        self.former.reload()
        
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
        
        let commentRow = TextViewRowFormer<FormTextViewCell>() { [weak self] in
            Comment.new.post = self!.post
            $0.textView.textColor = .formerSubColor()
            $0.textView.font = .systemFont(ofSize: 15)
            $0.textView.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Add a comment"
                $0.rowHeight = 75
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
}

