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

class PublicProfileViewController: FormViewController, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    var user: PFObject?
    var button = UIButton()
    var editorViewable = false
    var querySkip = 0
    var rowCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        if PFUser.current()!.objectId! != user!.objectId! {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Message", style: .plain, target: self, action: #selector(messageButtonPressed))
            addButton()
            buttonToImage()
        }
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        configure()
        
        let zeroSection = SectionFormer(rowFormer: zeroRow).set(headerViewFormer: TableFunctions.createHeader(text: "Posts to \(user?[PF_USER_FULLNAME] as! String)"))
        self.former.append(sectionFormer: zeroSection)
        self.former.reload()
    }
    
    func messageButtonPressed(sender: AnyObject) {
        let user1 = PFUser.current()!
        let user2 = user! as? PFUser
        let chatVC = ChatViewController()
        chatVC.groupId = Messages.startPrivateChat(user1: user1, user2: user2!)
        chatVC.outgoingColor = MAIN_COLOR
        
        self.navigationController?.pushViewController(chatVC, animated: true)
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
                    mailComposeViewController.view.tintColor = MAIN_COLOR
                    
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
        self.former.append(sectionFormer: SectionFormer(rowFormer: headerRow, phoneRow, emailRow))
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
    
    func editButtonPressed(sender: UIBarButtonItem) {
        self.navigationController?.pushViewController(EditProfileViewController(), animated: true)
    }
    
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
                        self.former.insertUpdate(rowFormer: TableFunctions.createFeedCellPhoto(user: post[PF_POST_USER] as! PFUser, post: post, nav: self.navigationController!), toIndexPath: IndexPath(row: self.rowCounter, section: 1), rowAnimation: .fade)
                        self.rowCounter += 1
                    } else {
                        self.former.insertUpdate(rowFormer: TableFunctions.createFeedCell(user: post[PF_POST_USER] as! PFUser, post: post, nav: self.navigationController!), toIndexPath: IndexPath(row: self.rowCounter, section: 1), rowAnimation: .fade)
                        self.rowCounter += 1
                    }
                }
                if self.querySkip == 0 && (posts?.count)! > 0 {
                    self.former.insertUpdate(sectionFormer: self.loadMoreSection, toSection: 2)
                } else {
                    self.tableView.scrollToRow(at: IndexPath(row: self.querySkip, section: 1), at: UITableViewScrollPosition.bottom, animated: false)
                }
            } else {
                print(error)
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
        buttonToImage()
        imageRow.cellUpdate {
            $0.iconView.image = nil
        }
    }
    
    func postButtonPressed() {
        if !editorViewable {
            Post.new.clear()
            buttonToText()
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
                self.buttonToImage()
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
        buttonToImage()
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
    
    func addButton() {
        button.frame = CGRect(x: self.view.frame.width - 100, y: self.view.frame.height - 175, width: 65, height: 65)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.backgroundColor = MAIN_COLOR
        buttonToImage()
        button.addTarget(self, action: #selector(postButtonPressed), for: .touchUpInside)
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOpacity = 1.0
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 4
        view.addSubview(button)
    }
    
    func buttonToImage() {
        editorViewable = false
        let tintedImage = Images.resizeImage(image: UIImage(named:"Plus-512.png")!, width: 60, height: 60)!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        button.tintColor = UIColor.white
        button.setImage(tintedImage, for: .normal)
        button.setTitle("", for: .normal)
        if PFUser.current()!.value(forKey: PF_USER_FULLNAME) as? String != user![PF_USER_FULLNAME] as? String {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Message", style: .plain, target: self, action: #selector(messageButtonPressed))
        }
    }
    
    func buttonToText() {
        editorViewable = true
        button.setImage(UIImage(), for: .normal)
        button.setTitle("Post", for: .normal)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonPressed))
    }
}
