//
//  SubGroupDetailViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-19.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import MessageUI
import JSQWebViewController
import BRYXBanner
import Material

class SubGroupDetailViewController: FormViewController, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    var firstLoad = true
    var positionIDs = [String]()
    let memberQuery = PFUser.query()
    var editorViewable = false
    var querySkip = 0
    var rowCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI and Table Properties
        tableView.contentInset.bottom = 120
        appMenuController.menu.views.first?.isHidden = false
        getPositions()
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        prepareToolbar()
        if !firstLoad {
            updateRows()
            getPositions()
            self.former.reload()
        } else {
            firstLoad = false
        }
    }
    
    private func prepareToolbar() {
        guard let tc = toolbarController else {
            return
        }
        tc.toolbar.title = EngagementSubGroup.sharedInstance.name!
        tc.toolbar.detail = ""
        tc.toolbar.backgroundColor = MAIN_COLOR
        let backButton = IconButton(image: Icon.cm.arrowBack)
        backButton.tintColor = UIColor.white
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        let moreButton = IconButton(image: Icon.cm.moreVertical)
        moreButton.tintColor = UIColor.white
        moreButton.addTarget(self, action: #selector(settingsButtonPressed), for: .touchUpInside)
        tc.toolbar.leftViews = [backButton]
        tc.toolbar.rightViews = [moreButton]
    }
    
    @objc private func handleBackButton() {
        appToolbarController.pull(from: self)
    }
    
    private func configure() {
        let membersRow = createMenu("\(EngagementSubGroup.sharedInstance.members.count) Members") { [weak self] in
            self?.former.deselect(animated: true)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "members") as! UserListViewController
            vc.positionIDs = (self?.positionIDs)!
            vc.searchMembers = EngagementSubGroup.sharedInstance.members
            vc.adminMembers = EngagementSubGroup.sharedInstance.admins
            vc.isSub = true
            appToolbarController.push(from: self!, to: vc)
        }
        let zeroRow = LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")).configure {
            $0.rowHeight = 0
        }
        let zeroSection = SectionFormer(rowFormer: zeroRow).set(headerViewFormer: TableFunctions.createHeader(text: "Posts to \(EngagementSubGroup.sharedInstance.name!)"))
        self.former.append(sectionFormer: SectionFormer(rowFormer: onlyImageRow, infoRow, phoneRow, addressRow, urlRow, emailRow, membersRow), zeroSection)
        loadPosts()
    }
    
    private func getPositions() {
        positionIDs.removeAll()
        for position in EngagementSubGroup.sharedInstance.positions {
            if EngagementSubGroup.sharedInstance.subgroup![position.lowercased().replacingOccurrences(of: " ", with: "")] != nil {
                positionIDs.append(EngagementSubGroup.sharedInstance.subgroup![position.lowercased().replacingOccurrences(of: " ", with: "")] as! String)
            } else {
                positionIDs.append("")
            }
        }
    }
    
    // MARK: - Table Rows
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.file = EngagementSubGroup.sharedInstance.subgroup![PF_SUBGROUP_COVER_PHOTO] as? PFFile
            $0.displayImage.loadInBackground()
            $0.displayImage.contentMode = UIViewContentMode.scaleAspectFill
            }.configure {
                $0.rowHeight = 200
            }.onSelected({ _ in
                if EngagementSubGroup.sharedInstance.coverPhoto != nil {
                    let agrume = Agrume(image: EngagementSubGroup.sharedInstance.coverPhoto!)
                    agrume.showFrom(self)
                }
            })
    }()
    
    private lazy var infoRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Info"
            $0.body = EngagementSubGroup.sharedInstance.info!
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = .systemFont(ofSize: 15)
            $0.date = ""
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
    }()
    
    private lazy var phoneRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Phone"
            $0.body = EngagementSubGroup.sharedInstance.phone
            $0.date = ""
            $0.bodyColor = UIColor.black
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { _ in
                if EngagementSubGroup.sharedInstance.phone != "" {
                    if let url = URL(string: "tel://\(EngagementSubGroup.sharedInstance.phone!)") {
                        let actionSheetController: UIAlertController = UIAlertController(title: "Would you like to call", message: EngagementSubGroup.sharedInstance.phone!, preferredStyle: .actionSheet)
                        actionSheetController.view.tintColor = MAIN_COLOR
                        
                        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                            //Just dismiss the action sheet
                        }
                        actionSheetController.addAction(cancelAction)
                        let single: UIAlertAction = UIAlertAction(title: "Yes", style: .default)
                        { action -> Void in
                            //UIApplication.shared.openURL(url as URL)
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                        actionSheetController.addAction(single)
                        actionSheetController.popoverPresentationController?.sourceView = self.view
                        //Present the AlertController
                        self.present(actionSheetController, animated: true, completion: nil)
                    }
                }
        }
    }()
    
    private lazy var addressRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Address"
            $0.body = EngagementSubGroup.sharedInstance.address
            $0.date = ""
            $0.bodyColor = UIColor.black
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
    }()
    
    private lazy var urlRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Website"
            $0.body = EngagementSubGroup.sharedInstance.url
            $0.date = ""
            $0.bodyColor = UIColor.black
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { _ in
                if EngagementSubGroup.sharedInstance.url != "" {
                    let controller = WebViewController(url: NSURL(string: "http://\(EngagementSubGroup.sharedInstance.url!)")! as URL)
                    let nav = UINavigationController(rootViewController: controller)
                    nav.navigationBar.barTintColor = MAIN_COLOR
                    self.present(nav, animated: true, completion: nil)
                }
        }
    }()
    
    private lazy var emailRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Email"
            $0.body = EngagementSubGroup.sharedInstance.email
            $0.date = ""
            $0.bodyColor = UIColor.black
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { _ in
                if EngagementSubGroup.sharedInstance.email != "" {
                    let mailComposeViewController = MFMailComposeViewController()
                    mailComposeViewController.navigationBar.tintColor = UIColor.white
                    mailComposeViewController.navigationBar.shadowImage = UIImage()
                    mailComposeViewController.navigationBar.setBackgroundImage(UIImage(), for: .default)
                    mailComposeViewController.mailComposeDelegate = self
                    mailComposeViewController.setToRecipients([EngagementSubGroup.sharedInstance.email!])
                    mailComposeViewController.setMessageBody("", isHTML: false)
                    mailComposeViewController.view.tintColor = MAIN_COLOR
                    mailComposeViewController.navigationBar.barTintColor = MAIN_COLOR
                    if MFMailComposeViewController.canSendMail() {
                        self.present(mailComposeViewController, animated: true, completion: { UIApplication.shared.statusBarStyle = .lightContent })
                    } else {
                        SVProgressHUD.showError(withStatus: "Send Error")
                    }
                }
        }
    }()
    
    // MARK: - User actions
    
    func settingsButtonPressed() {
        
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        
        var isAdmin = false
        for admin in EngagementSubGroup.sharedInstance.admins {
            if admin == PFUser.current()?.objectId! {
                let editAction: UIAlertAction = UIAlertAction(title: "Edit", style: .default) { action -> Void in
                    // Edit group if admin
                    appToolbarController.push(from: self, to: EditSubGroupViewController())
                }
                actionSheetController.addAction(editAction)
                isAdmin = true
                break
            }
        }
        if !isAdmin {
            var isMember = false
            for member in EngagementSubGroup.sharedInstance.members {
                if member == PFUser.current()?.objectId! {
                    let leaveAction: UIAlertAction = UIAlertAction(title: "Leave", style: .default) { action -> Void in
                        // leave group
                        UIApplication.shared.beginIgnoringInteractionEvents()
                        SVProgressHUD.show(withStatus: "Leaving")
                            // Leave old group
                        let subGroupQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                            subGroupQuery.whereKey("user", equalTo: PFUser.current()!)
                            subGroupQuery.includeKey("subgroup")
                            subGroupQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                                UIApplication.shared.endIgnoringInteractionEvents()
                                if error == nil {
                                    if let user = users!.first {
                                        let oldSubgroup = user["subgroup"] as? PFObject
                                        if oldSubgroup != nil {
                                            var oldMembers = oldSubgroup![PF_SUBGROUP_MEMBERS] as? [String]
                                            let removeMemberIndex = oldMembers!.index(of: PFUser.current()!.objectId!)
                                            if removeMemberIndex != nil {
                                                oldMembers?.remove(at: removeMemberIndex!)
                                                oldSubgroup![PF_SUBGROUP_MEMBERS] = oldMembers
                                                EngagementSubGroup.sharedInstance.members = oldMembers!
                                            }
                                            
                                            var oldAdmins = oldSubgroup![PF_SUBGROUP_ADMINS] as? [String]
                                            let removeAdminIndex = oldAdmins!.index(of: PFUser.current()!.objectId!)
                                            if removeAdminIndex != nil {
                                                oldAdmins?.remove(at: removeAdminIndex!)
                                                oldSubgroup![PF_SUBGROUP_ADMINS] = oldAdmins
                                                EngagementSubGroup.sharedInstance.admins = oldAdmins!
                                            }
                                            
                                            UIApplication.shared.beginIgnoringInteractionEvents()
                                                oldSubgroup!.saveInBackground(block: { (success: Bool, error: Error?) in
                                                    if success {
                                                        user.remove(forKey: "subgroup")
                                                        user.saveInBackground(block: { (success: Bool, error: Error?) in
                                                            if error == nil {
                                                                UIApplication.shared
                                                                    .endIgnoringInteractionEvents()
                                                                SVProgressHUD.showSuccess(withStatus: "Lefft Group")
                                                            } else {
                                                                SVProgressHUD.showError(withStatus: "Network Error")
                                                                UIApplication.shared.endIgnoringInteractionEvents()
                                                            }
                                                        })
                                                    } else {
                                                        SVProgressHUD.showError(withStatus: "Network Error")
                                                        UIApplication.shared.endIgnoringInteractionEvents()
                                                    }
                                                })
                                        } else {
                                            print("Old sub group was nil")
                                        }
                                    }
                                }
                            })
                    }
                    actionSheetController.addAction(leaveAction)

                    isMember = true
                    break
                }
            }
            if !isMember {
                let joinAction: UIAlertAction = UIAlertAction(title: "Join", style: .default) { action -> Void in
                    // Join group if not a member
                    self.joinButtonPressed()
                }
                actionSheetController.addAction(joinAction)
            }
        } else {
            let resignAction: UIAlertAction = UIAlertAction(title: "Resign as Admin", style: .default) { action -> Void in
                // leave group
                if EngagementSubGroup.sharedInstance.admins.count > 1 {
                    UIApplication.shared.beginIgnoringInteractionEvents()
                    SVProgressHUD.show(withStatus: "Resigning")
                        // Leave old group
                    let subGroupQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                        subGroupQuery.whereKey("user", equalTo: PFUser.current()!)
                        subGroupQuery.includeKey("subgroup")
                        subGroupQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                            UIApplication.shared.endIgnoringInteractionEvents()
                            if error == nil {
                                if let user = users!.first {
                                    let oldSubgroup = user["subgroup"] as? PFObject
                                    if oldSubgroup != nil {
                                        
                                        var oldAdmins = oldSubgroup![PF_SUBGROUP_ADMINS] as? [String]
                                        let removeAdminIndex = oldAdmins!.index(of: PFUser.current()!.objectId!)
                                        if removeAdminIndex != nil {
                                            oldAdmins?.remove(at: removeAdminIndex!)
                                            oldSubgroup![PF_SUBGROUP_ADMINS] = oldAdmins
                                            EngagementSubGroup.sharedInstance.admins = oldAdmins!
                                        }
                                        
                                        oldSubgroup!.saveInBackground()
                                    } else {
                                        print("Old sub group was nil")
                                    }
                                    
                                    user["subgroup"] = EngagementSubGroup.sharedInstance.subgroup
                                    user.saveInBackground(block: { (success: Bool, error: Error?) in
                                        if error == nil {
                                            // Refresh view
                                            self.former.removeAll()
                                            self.former.reload()
                                            self.configure()
                                            SVProgressHUD.showSuccess(withStatus: "Resigned")
                                        } else {
                                            SVProgressHUD.showError(withStatus: "Network Error")
                                        }
                                    })
                                    
                                } else {
                                    SVProgressHUD.showError(withStatus: "Network Error")
                                }
                            } else {
                                SVProgressHUD.showError(withStatus: "Network Error")
                            }
                        })
                } else {
                    let banner = Banner(title: "Cannot Resign", subtitle: "You are the only admin.", image: nil, backgroundColor: MAIN_COLOR!)
                    banner.dismissesOnTap = true
                    banner.show(duration: 1.0)
                    SVProgressHUD.showError(withStatus: "Error")
                }
            }
            actionSheetController.addAction(resignAction)
        }
        actionSheetController.popoverPresentationController?.sourceView = self.view
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func joinButtonPressed() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Join Sub Group?", message: "You will leave your old sub group", preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        let advanced: UIAlertAction = UIAlertAction(title: "Join", style: .default) { action -> Void in
            
            UIApplication.shared.beginIgnoringInteractionEvents()
            SVProgressHUD.show(withStatus: "Joining")
                // Leave old group
            let subGroupQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
            subGroupQuery.whereKey("user", equalTo: PFUser.current()!)
            subGroupQuery.includeKey("subgroup")
            subGroupQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                if error == nil {
                    if let user = users!.first {
                        let oldSubgroup = user["subgroup"] as? PFObject
                        if oldSubgroup != nil {
                            
                            var oldAdmins = oldSubgroup![PF_SUBGROUP_ADMINS] as? [String]
                            if (oldAdmins?.count)! > 1 {
                                let removeAdminIndex = oldAdmins!.index(of: PFUser.current()!.objectId!)
                                if removeAdminIndex != nil {
                                    oldAdmins?.remove(at: removeAdminIndex!)
                                    oldSubgroup![PF_SUBGROUP_ADMINS] = oldAdmins
                                } else {
                                    print("Admin index nil")
                                }
                                
                                var oldMembers = oldSubgroup![PF_SUBGROUP_MEMBERS] as? [String]
                                let removeMemberIndex = oldMembers!.index(of: PFUser.current()!.objectId!)
                                if removeMemberIndex != nil {
                                    oldMembers?.remove(at: removeMemberIndex!)
                                    oldSubgroup![PF_SUBGROUP_MEMBERS] = oldMembers
                                } else {
                                    print("Member index nil")
                                }
                                oldSubgroup!.saveInBackground()
                                
                                // Join new group
                                EngagementSubGroup.sharedInstance.join(newUser: PFUser.current()!, completion: {
                                    // Refresh view
                                    user["subgroup"] = EngagementSubGroup.sharedInstance.subgroup
                                    user.saveInBackground()
                                    self.former.removeAll()
                                    self.former.reload()
                                    self.configure()
                                    SVProgressHUD.showSuccess(withStatus: "Joined")
                                })
                                
                                user["subgroup"] = EngagementSubGroup.sharedInstance.subgroup
                                user.saveInBackground()
                                
                            } else {
                                let banner = Banner(title: "Cannot Resign", subtitle: "You are the only admin of your current sub group.", image: nil, backgroundColor: MAIN_COLOR!)
                                banner.dismissesOnTap = true
                                banner.show(duration: 1.0)
                                SVProgressHUD.showError(withStatus: "Error")
                            }
                            UIApplication.shared.endIgnoringInteractionEvents()
                            
                        } else {
                            print("Old sub group was nil")
                            EngagementSubGroup.sharedInstance.join(newUser: PFUser.current()!, completion: {
                                // Refresh view
                                user["subgroup"] = EngagementSubGroup.sharedInstance.subgroup
                                user.saveInBackground()
                                self.former.removeAll()
                                self.former.reload()
                                self.configure()
                                UIApplication.shared.endIgnoringInteractionEvents()
                                SVProgressHUD.showSuccess(withStatus: "Joined")
                            })
                        }
                    }
                } else {
                    UIApplication.shared.endIgnoringInteractionEvents()
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            })

            }
        actionSheetController.addAction(advanced)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    // Update Rows after editing
    
    func updateRows() {
        EngagementSubGroup.sharedInstance.unpack()
        infoRow.cellUpdate {
            $0.bodyLabel.text = EngagementSubGroup.sharedInstance.info
        }
        urlRow.cellUpdate {
            $0.bodyLabel.text = EngagementSubGroup.sharedInstance.url
        }
        phoneRow.cellUpdate {
            $0.bodyLabel.text = EngagementSubGroup.sharedInstance.phone
        }
        addressRow.cellUpdate {
            $0.bodyLabel.text = EngagementSubGroup.sharedInstance.address
        }
        emailRow.cellUpdate {
            $0.bodyLabel.text = EngagementSubGroup.sharedInstance.email
        }
        onlyImageRow.cellUpdate {
            $0.displayImage.image = EngagementSubGroup.sharedInstance.coverPhoto
            $0.displayImage.contentMode = UIViewContentMode.scaleAspectFill
        }
        self.former.reload()
    }
    
    let createMenu: ((String, (() -> Void)?) -> RowFormer) = { text, onSelected in
        return LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 16)
            $0.accessoryType = .disclosureIndicator
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
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
        query.whereKeyExists(PF_POST_TO_OBJECT)
        query.includeKey(PF_POST_TO_OBJECT)
        query.whereKey(PF_POST_TO_OBJECT, equalTo: EngagementSubGroup.sharedInstance.subgroup!)
        query.findObjectsInBackground { (posts: [PFObject]?, error: Error?) in
            UIApplication.shared.endIgnoringInteractionEvents()
            SVProgressHUD.dismiss()
            if error == nil {
                for post in posts! {
                    if (post[PF_POST_HAS_IMAGE] as? Bool) == true {
                        self.former.insertUpdate(rowFormer: TableFunctions.createFeedCellPhoto(user: post[PF_POST_USER] as! PFUser, post: post, view: self), toIndexPath: IndexPath(row: self.rowCounter, section: 1), rowAnimation: .fade)
                        self.rowCounter += 1
                    } else {
                        self.former.insertUpdate(rowFormer: TableFunctions.createFeedCell(user: post[PF_POST_USER] as! PFUser, post: post, view: self), toIndexPath: IndexPath(row: self.rowCounter, section: 1), rowAnimation: .fade)
                        self.rowCounter += 1
                    }
                }
                if self.querySkip == 0 && (posts?.count)! > 0 {
                    self.former.insertUpdate(sectionFormer: self.loadMoreSection, toSection: 2)
                } else if (posts?.count)! != 0 {
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
        
        let zeroSection = SectionFormer(rowFormer: zeroRow).set(headerViewFormer: TableFunctions.createHeader(text: "Posts to \(EngagementSubGroup.sharedInstance.name!)"))
        self.former.append(sectionFormer: zeroSection)
        self.former.reload()
        loadPosts()
        Post.new.clear()
        imageRow.cellUpdate {
            $0.iconView.image = nil
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
            
            let newPostSection = SectionFormer(rowFormer: infoRow, imageRow).set(headerViewFormer: TableFunctions.createHeader(text: "New post to \(EngagementSubGroup.sharedInstance.name!)"))
            
            self.former.insert(sectionFormer: newPostSection, toSection: 1)
                .onCellSelected { [weak self] _ in
                    self?.formerInputAccessoryView.update()
            }
            self.former.reload()
            
        } else if Post.new.info != ""{
            Post.new.createPost(object: EngagementSubGroup.sharedInstance.subgroup!, completion: {
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

