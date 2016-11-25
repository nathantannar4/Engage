//
//  PublicProfileViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import MessageUI
import BRYXBanner
import Material

class PublicProfileViewController: FormViewController, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    var user: PFObject?
    var button = UIButton()
    var editorViewable = false
    var querySkip = 0
    var rowCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.cm.close, style: .plain, target: self, action: #selector(closeButtonPressed))
        if user?.objectId! != PFUser.current()!.objectId! {
            let infoButton = UIBarButtonItem(image: UIImage(named: "Info")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(infoButtonPressed))
            infoButton.tintColor = UIColor.white
            let messageButton = UIBarButtonItem(image: UIImage(named: "Compose")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(messageButtonPressed))
            messageButton.tintColor = UIColor.white
            navigationItem.rightBarButtonItems = [messageButton, infoButton]
        }
    
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        self.prepareButton()
        configure()
    }
    
    @objc private func messageButtonPressed() {
        let user1 = PFUser.current()!
        let user2 = user! as? PFUser
        
        let messageVC = ChatViewController()
        messageVC.groupId = Messages.startPrivateChat(user1: user1, user2: user2!)
        messageVC.groupName = user2!.value(forKey: PF_USER_FULLNAME) as! String
        
        self.navigationController?.pushViewController(messageVC, animated: true)
    }
    
    @objc private func closeButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func infoButtonPressed() {
        
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        let reportAction: UIAlertAction = UIAlertAction(title: "Report", style: .default) { action -> Void in
            // Report User
            let actionSheetController: UIAlertController = UIAlertController(title: "Report User As", message: nil, preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = MAIN_COLOR
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            let abusiveAction: UIAlertAction = UIAlertAction(title: "Abusive Messages", style: .default) { action -> Void in
                let flagObject = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Reported_Users")
                flagObject["user"] = self.user
                flagObject["reason"] = "Abusive Messages"
                flagObject["by_user"] = PFUser.current()!
                flagObject.saveInBackground(block: { (success: Bool, error: Error?) in
                    if error == nil {
                        SVProgressHUD.showSuccess(withStatus: "User Reported")
                    } else {
                        SVProgressHUD.showError(withStatus: "Network Error")
                    }
                })
            }
            actionSheetController.addAction(abusiveAction)
            
            let spamAction: UIAlertAction = UIAlertAction(title: "Spam", style: .default) { action -> Void in
                let flagObject = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Reported_Users")
                flagObject["user"] = self.user
                flagObject["reason"] = "Spam"
                flagObject["by_user"] = PFUser.current()!
                flagObject.saveInBackground(block: { (success: Bool, error: Error?) in
                    if error == nil {
                        SVProgressHUD.showSuccess(withStatus: "User Reported")
                    } else {
                        SVProgressHUD.showError(withStatus: "Network Error")
                    }
                })
            }
            actionSheetController.addAction(spamAction)
            
            let invalidAction: UIAlertAction = UIAlertAction(title: "Invalid Member", style: .default) { action -> Void in
                let flagObject = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Reported_Users")
                flagObject["user"] = self.user
                flagObject["reason"] = "Invalid Member"
                flagObject["by_user"] = PFUser.current()!
                flagObject.saveInBackground(block: { (success: Bool, error: Error?) in
                    if error == nil {
                        SVProgressHUD.showSuccess(withStatus: "User Reported")
                    } else {
                        SVProgressHUD.showError(withStatus: "Network Error")
                    }
                })
            }
            actionSheetController.addAction(invalidAction)
            actionSheetController.popoverPresentationController?.sourceView = self.view
            //Present the AlertController
            self.present(actionSheetController, animated: true, completion: nil)
        }
        actionSheetController.addAction(reportAction)
        
        if Profile.sharedInstance.blockedUsers.contains(self.user!.objectId!) {
            let blockAction: UIAlertAction = UIAlertAction(title: "Unblock", style: .default) { action -> Void in
                // Unblock User
                let index = Profile.sharedInstance.blockedUsers.index(of: self.user!.objectId!)
                Profile.sharedInstance.blockedUsers.remove(at: index!)
                let user = Profile.sharedInstance.user!
                user[PF_USER_BLOCKED] = Profile.sharedInstance.blockedUsers
                user.saveInBackground(block: { (succeeded: Bool, error: Error?) -> Void in
                    if error == nil {
                        SVProgressHUD.showSuccess(withStatus: "User Unblocked")
                    } else {
                        SVProgressHUD.showError(withStatus: "Network Error")
                    }
                })
            }
            actionSheetController.addAction(blockAction)
        } else {
            let blockAction: UIAlertAction = UIAlertAction(title: "Block", style: .default) { action -> Void in
                // Block User
                Profile.sharedInstance.blockedUsers.append(self.user!.objectId!)
                let user = Profile.sharedInstance.user!
                user[PF_USER_BLOCKED] = Profile.sharedInstance.blockedUsers
                user.saveInBackground(block: { (succeeded: Bool, error: Error?) -> Void in
                    if error == nil {
                        SVProgressHUD.showSuccess(withStatus: "User Blocked, their posts and messages will not appear")
                    } else {
                        SVProgressHUD.showError(withStatus: "Network Error")
                    }
                })
            }
            actionSheetController.addAction(blockAction)
        }
        
        
        if Engagement.sharedInstance.admins.contains(PFUser.current()!.objectId!) {
            let removeAction: UIAlertAction = UIAlertAction(title: "Remove from Group", style: .default) { action -> Void in
                // Remove User
                let alert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
                alert.view.tintColor = MAIN_COLOR
                //Create and add the Cancel action
                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                    //Do some stuff
                }
                alert.addAction(cancelAction)
                let leave: UIAlertAction = UIAlertAction(title: "Remove", style: .default) { action -> Void in
                    Engagement.sharedInstance.remove(oldUser: self.user! as! PFUser, completion: {
                        SVProgressHUD.showSuccess(withStatus: "User Removed")
                    }())
                }
                alert.addAction(leave)
                self.present(alert, animated: true, completion: nil)
            }
            actionSheetController.addAction(removeAction)
        }
        actionSheetController.popoverPresentationController?.sourceView = self.view
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    private lazy var zeroRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {_ in
            }.configure {
                $0.rowHeight = 0
        }
    }()
    
    
    private func configure() {
        let headerRow = CustomRowFormer<ProfileHeaderCell>(instantiateType: .Nib(nibName: "ProfileHeaderCell")) {
            $0.iconView.backgroundColor = MAIN_COLOR
            $0.backgroundLabel.backgroundColor = MAIN_COLOR
            $0.nameLabel.text = self.user![PF_USER_FULLNAME] as? String
            $0.schoolLabel.text = ""
            $0.titleLabel.text = ""
            $0.iconView.image = UIImage(named: "profile_blank")
            $0.iconView.file = self.user![PF_USER_PICTURE] as? PFFile
            $0.iconView.loadInBackground()
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected({ (cell: CustomRowFormer<ProfileHeaderCell>) in
                if cell.cell.iconView.image != nil {
                    let agrume = Agrume(image: cell.cell.iconView.image!)
                    agrume.showFrom(self)
                }
            })
        
        let phoneRow = CustomRowFormer<ProfileLabelCell>(instantiateType: .Nib(nibName: "ProfileLabelCell")) {
            $0.titleLabel.text = "Phone"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.displayLabel.text = self.user![PF_USER_PHONE] as? String
            }.onSelected { _ in
                self.former.deselect(animated: true)
                let phoneNumber = self.user![PF_USER_PHONE] as? String
                if phoneNumber != "" {
                    if let url = NSURL(string: "tel://\(phoneNumber!)") {
                        let actionSheetController: UIAlertController = UIAlertController(title: "Would you like to call", message: phoneNumber!, preferredStyle: .actionSheet)
                        actionSheetController.view.tintColor = MAIN_COLOR
                        
                        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                            //Just dismiss the action sheet
                        }
                        actionSheetController.addAction(cancelAction)
                        let single: UIAlertAction = UIAlertAction(title: "Yes", style: .default)
                        { action -> Void in
                            UIApplication.shared.open(url as URL)
                        }
                        actionSheetController.addAction(single)
                        actionSheetController.popoverPresentationController?.sourceView = self.view
                        //Present the AlertController
                        self.present(actionSheetController, animated: true, completion: nil)
                    }
                }
                
        }
        let emailRow = CustomRowFormer<ProfileLabelCell>(instantiateType: .Nib(nibName: "ProfileLabelCell")) {
            $0.titleLabel.text = "Email"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.displayLabel.text = self.user![PF_USER_EMAIL] as? String
            }.onSelected { _ in
                self.former.deselect(animated: true)
                let email = self.user![PF_USER_EMAIL] as? String
                if email != "" {
                    let mailComposeViewController = MFMailComposeViewController()
                    mailComposeViewController.navigationBar.tintColor = UIColor.white
                    mailComposeViewController.navigationBar.shadowImage = UIImage()
                    mailComposeViewController.navigationBar.setBackgroundImage(UIImage(), for: .default)
                    mailComposeViewController.mailComposeDelegate = self
                    mailComposeViewController.setToRecipients([email!])
                    mailComposeViewController.setMessageBody("", isHTML: false)
                    mailComposeViewController.navigationBar.barTintColor = MAIN_COLOR
                    if MFMailComposeViewController.canSendMail() {
                        self.present(mailComposeViewController, animated: true, completion: nil)
                    } else {
                        let banner = Banner(title: "Failed to send email", subtitle: "Please check your network settings", image: nil, backgroundColor: MAIN_COLOR!)
                        banner.dismissesOnTap = true
                        banner.show(duration: 2.0)
                    }
                }
        }
        
        var customRow = [CustomRowFormer<ProfileLabelCell>]()
        
        if Engagement.sharedInstance.engagement != nil {
            
            SVProgressHUD.show(withStatus: "Loading")
                // Query to find current data
            let customQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
            customQuery.whereKey("user", equalTo: self.user!)
            customQuery.includeKey("subgroup")
            customQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                SVProgressHUD.dismiss()
                if error == nil {
                    if let user = users!.first {
                        
                        let subgroup = user["subgroup"] as? PFObject
                        if subgroup != nil {
                            headerRow.cellUpdate({
                                $0.schoolLabel.text = subgroup![PF_SUBGROUP_NAME] as? String
                            })
                        }
                        
                        for field in Engagement.sharedInstance.profileFields {
                            customRow.append(CustomRowFormer<ProfileLabelCell>(instantiateType: .Nib(nibName: "ProfileLabelCell")) {
                                $0.titleLabel.text = field
                                $0.titleLabel.textColor = MAIN_COLOR
                                $0.displayLabel.text = user[field.lowercased()] as? String
                                $0.titleLabel.font = .boldSystemFont(ofSize: 15)
                                $0.selectionStyle = .none
                            })
                        }
                        self.former.insertUpdate(rowFormers: customRow, below: emailRow, rowAnimation: .fade)
                    }
                }
            })
        }

        
        // Add profile info rows to table
        let zeroSection = SectionFormer(rowFormer: zeroRow).set(headerViewFormer: TableFunctions.createHeader(text: "Posts to \(user?[PF_USER_FULLNAME] as! String)"))
        
        self.former.append(sectionFormer: SectionFormer(rowFormer: headerRow, phoneRow, emailRow), zeroSection)
        self.former.reload()
        
        if PFUser.current()!.objectId! != user!.objectId! {
            self.loadPosts()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - User actions
    
    func logoutButtonPressed(sender: UIBarButtonItem) {
        PFUser.logOut()
        Profile.sharedInstance.clear()
        PushNotication.parsePushUserResign()
        Utilities.postNotification(NOTIFICATION_USER_LOGGED_OUT)
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Subgroup Posts
    
    private func loadPosts() {
        
        SVProgressHUD.show(withStatus: "Loading Posts")
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Posts")
        query.limit = 5
        query.skip = querySkip
        query.order(byDescending: "createdAt")
        query.includeKey(PF_POST_USER)
        query.whereKeyExists(PF_POST_TO_USER)
        query.includeKey(PF_POST_TO_USER)
        query.whereKey(PF_POST_TO_USER, equalTo: user!)
        query.findObjectsInBackground { (posts: [PFObject]?, error: Error?) in
            UIApplication.shared.endIgnoringInteractionEvents()
            SVProgressHUD.dismiss()
            if error == nil {
                for post in posts! {
                    if (post[PF_POST_HAS_IMAGE] as? Bool) == true {
                        self.former.insertUpdate(rowFormer: TableFunctions.createFeedCellPhoto(user: post[PF_POST_USER] as! PFUser, post: post, target: self.navigationController!), toIndexPath: IndexPath(row: self.rowCounter, section: 1), rowAnimation: .fade)
                        self.rowCounter += 1
                    } else {
                        self.former.insertUpdate(rowFormer: TableFunctions.createFeedCell(user: post[PF_POST_USER] as! PFUser, post: post, target: self.navigationController!), toIndexPath: IndexPath(row: self.rowCounter, section: 1), rowAnimation: .fade)
                        self.rowCounter += 1
                    }
                }
                if self.querySkip == 0 && (posts?.count)! > 0 {
                    self.former.insertUpdate(sectionFormer: self.loadMoreSection, toSection: 2)
                } else {
                    self.tableView.scrollToRow(at: IndexPath(row: self.querySkip, section: 1), at: UITableViewScrollPosition.bottom, animated: false)
                }
            } else {
                print(error.debugDescription)
                SVProgressHUD.showError(withStatus: "Network Error")
            }
        }
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
            imageRow.cellUpdate {
                $0.iconView.image = image
            }
        } else{
            print("Something went wrong")
            SVProgressHUD.showError(withStatus: "An Error Occurred")
        }
    }
    
    // MARK: - Subgroup Post Functions
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    func refresh(sender:AnyObject)
    {
        // Updating your data here...
        UIApplication.shared.beginIgnoringInteractionEvents()
        while self.former.sectionFormers.count > 1 {
            self.former.remove(section: 1)
            self.former.reload()
        }
        rowCounter = 0
        querySkip = 0
        let zeroRow = LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")).configure {
            $0.rowHeight = 0
        }
        
        let zeroSection = SectionFormer(rowFormer: zeroRow).set(headerViewFormer: TableFunctions.createHeader(text: "Posts to \(user?[PF_USER_FULLNAME] as! String)"))
        self.former.append(sectionFormer: zeroSection)
        self.former.reload()
        loadPosts()
        Post.new.clear()
        imageRow.cellUpdate {
            $0.iconView.image = nil
        }
    }
    
    func prepareButton() {
        button.frame = CGRect(x: self.view.frame.width - 75, y: self.view.frame.height - 150, width: 50, height: 50)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.backgroundColor = MAIN_COLOR
        button.addTarget(self, action: #selector(switchButton), for: .touchUpInside)
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOpacity = 1.0
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 4
        button.setImage(Icon.cm.add, for: .normal)
        button.tintColor = UIColor.white
        self.view.addSubview(button)
    }
    
    func switchButton() {
        if editorViewable {
            cancelButtonPressed()
            editorViewable = false
            button.setImage(Icon.cm.add, for: .normal)
        } else {
            postButtonPressed()
            editorViewable = true
            button.setImage(Icon.cm.close, for: .normal)
        }
    }
    
    func postButtonPressed() {
        if !editorViewable {
            Post.new.clear()
            let infoRow = TextViewRowFormer<FormTextViewCell>() { [weak self] in
                $0.textView.textColor = .formerSubColor()
                $0.textView.font = .systemFont(ofSize: 15)
                $0.textView.inputAccessoryView = self?.formerInputAccessoryView
                }.configure {
                    $0.placeholder = "What's new?"
                    $0.text = Post.new.info
                }.onTextChanged {
                    Post.new.info = $0
            }
            
            let newPostSection = SectionFormer(rowFormer: infoRow, imageRow).set(headerViewFormer: TableFunctions.createHeader(text: "New post to \(user?[PF_USER_FULLNAME] as! String)"))
            
            self.former.insert(sectionFormer: newPostSection, toSection: 1)
                .onCellSelected { [weak self] _ in
                    self?.formerInputAccessoryView.update()
            }
            self.former.reload()
            
        } else if Post.new.info != ""{
            Post.new.createPost(object: user!, completion: {
                self.imageRow.cellUpdate {
                    $0.iconView.image = nil
                }
                self.refresh(sender: self)
            })
        }
    }
    
    func cancelButtonPressed() {
        Post.new.clear()
        self.former.remove(section: 1)
        self.former.reload()
        
        imageRow.cellUpdate {
            $0.iconView.image = nil
        }
    }
    
    private lazy var loadMoreSection: SectionFormer = {
        let loadMoreRow = CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.text = "Load More"
            $0.titleLabel.textAlignment = .center
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                self!.querySkip += 5
                self!.loadPosts()
        }
        return SectionFormer(rowFormer: loadMoreRow)
    }()
    
    private lazy var imageRow: LabelRowFormer<ProfileImageCell> = {
        LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
            $0.iconView.image = Post.new.image
            }.configure {
                $0.text = "Add image to post"
                $0.rowHeight = 60
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                self?.presentImagePicker()
        }
    }()
}
