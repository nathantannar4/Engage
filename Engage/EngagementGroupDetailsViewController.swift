//
//  EngagementGroupDetailsViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-13.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import JSQWebViewController
import MessageUI

class EngagementGroupDetailsViewController: FormViewController, MFMailComposeViewControllerDelegate  {
    
    var firstLoad = true
    var positionIDs = [String]()
    var querySkip = 0
    var rowCounter = 0
    var button = UIButton()
    var editorViewable = false
    var membersRow: RowFormer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI and Table Properties
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 60
        title = Engagement.sharedInstance.name!
        
        
        if Engagement.sharedInstance.members.contains((PFUser.current()?.objectId)!) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings"), style: .plain, target: self, action: #selector(settingsButtonPressed))
        }
        
        for position in Engagement.sharedInstance.positions {
            if Engagement.sharedInstance.engagement![position.lowercased().replacingOccurrences(of: " ", with: "")] != nil {
                positionIDs.append(Engagement.sharedInstance.engagement![position.lowercased().replacingOccurrences(of: " ", with: "")] as! String)
            } else {
                positionIDs.append("")
            }
        }
        
        configure()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.revealViewController().frontViewPosition.rawValue == 4 {
            self.revealViewController().revealToggle(self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !firstLoad {
            Engagement.sharedInstance.unpack()
            positionIDs.removeAll()
            for position in Engagement.sharedInstance.positions {
                if Engagement.sharedInstance.engagement![position.lowercased().replacingOccurrences(of: " ", with: "")] != nil {
                    positionIDs.append(Engagement.sharedInstance.engagement![position.lowercased().replacingOccurrences(of: " ", with: "")] as! String)
                } else {
                    positionIDs.append("")
                }
            }
            self.former.removeAll()
            configure()
        } else {
            firstLoad = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if revealViewController() != nil {
            let menuButton = UIBarButtonItem()
            menuButton.image = UIImage(named: "ic_menu_black_24dp")
            menuButton.target = revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.navigationItem.leftBarButtonItem = menuButton
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            tableView.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
    
    private func configure() {
        
        let infoRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Info"
            $0.body = Engagement.sharedInstance.info!
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = .systemFont(ofSize: 15)
            $0.date = ""
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
        
        let urlRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Website"
            $0.body = Engagement.sharedInstance.url
            $0.date = ""
            $0.bodyColor = UIColor.black
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected {_ in
                if Engagement.sharedInstance.url != "" {
                    let controller = WebViewController(url: NSURL(string: "http://\(Engagement.sharedInstance.url!)")! as URL)
                    let nav = UINavigationController(rootViewController: controller)
                    nav.navigationBar.barTintColor = MAIN_COLOR
                    self.present(nav, animated: true, completion: nil)
                }
        }
        
        let emailRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Email"
            $0.body = Engagement.sharedInstance.email
            $0.date = ""
            $0.bodyColor = UIColor.black
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { _ in
                if Engagement.sharedInstance.email != "" {
                    let mailComposeViewController = MFMailComposeViewController()
                    mailComposeViewController.navigationBar.tintColor = UIColor.white
                    mailComposeViewController.navigationBar.shadowImage = UIImage()
                    mailComposeViewController.navigationBar.setBackgroundImage(UIImage(), for: .default)
                    mailComposeViewController.mailComposeDelegate = self
                    mailComposeViewController.setToRecipients([Engagement.sharedInstance.email!])
                    mailComposeViewController.setMessageBody("", isHTML: false)
                    
                    if MFMailComposeViewController.canSendMail() {
                        mailComposeViewController.view.tintColor = MAIN_COLOR
                        self.present(mailComposeViewController, animated: true, completion: nil)
                    }
                }
        }
        
        membersRow = createMenu("\(Engagement.sharedInstance.members.count) Members") { [weak self] in
            self?.former.deselect(animated: true)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "members") as! UserListViewController
            vc.positionIDs = (self?.positionIDs)!
            vc.searchMembers = Engagement.sharedInstance.members
            vc.adminMembers = Engagement.sharedInstance.admins
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        self.former.append(sectionFormer: SectionFormer(rowFormer: onlyImageRow, infoRow, urlRow, emailRow, membersRow))
        self.former.reload()
    }
    
    // MARK: - Table Rows
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.file = Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_COVER_PHOTO] as? PFFile
            $0.displayImage.loadInBackground()
            $0.displayImage.contentMode = UIViewContentMode.scaleAspectFill
            }.configure {
                $0.rowHeight = 200
            }.onSelected({ _ in
                if Engagement.sharedInstance.coverPhoto != nil {
                    let agrume = Agrume(image: Engagement.sharedInstance.coverPhoto!)
                    agrume.showFrom(self)
                }
            })
    }()
    
    // MARK: - User actions
    
    func settingsButtonPressed(sender: UIBarButtonItem) {
        
        let actionSheetController: UIAlertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        if Engagement.sharedInstance.admins.contains(PFUser.current()!.objectId!) {
            let editAction: UIAlertAction = UIAlertAction(title: "Edit", style: .default) { action -> Void in
                // Edit group if admin
                self.navigationController?.pushViewController(EditEngagementGroupViewController(), animated: true)
            }
            actionSheetController.addAction(editAction)
            
            let resignAction: UIAlertAction = UIAlertAction(title: "Resign as Admin", style: .default) { action -> Void in
                // leave group
                if Engagement.sharedInstance.admins.count > 1 {
                    UIApplication.shared.beginIgnoringInteractionEvents()
                    SVProgressHUD.show(withStatus: "Resigning")
                    
                    let subGroupQuery = PFQuery(className: "Engagements")
                    subGroupQuery.whereKey(PF_USER_OBJECTID, equalTo: (Engagement.sharedInstance.engagement?.objectId)!)
                    subGroupQuery.findObjectsInBackground(block: { (engagements: [PFObject]?, error: Error?) in
                        UIApplication.shared.endIgnoringInteractionEvents()
                        if error == nil {
                            if let engagement = engagements!.first {
                                
                                var oldAdmins = engagement[PF_ENGAGEMENTS_ADMINS] as? [String]
                                let removeAdminIndex = oldAdmins!.index(of: PFUser.current()!.objectId!)
                                if removeAdminIndex != nil {
                                    oldAdmins?.remove(at: removeAdminIndex!)
                                    engagement[PF_SUBGROUP_ADMINS] = oldAdmins
                                    Engagement.sharedInstance.admins = oldAdmins!
                                } else {
                                    print("Admin index nil")
                                }
                                
                                engagement.saveInBackground(block: { (success: Bool, error: Error?) in
                                    if error == nil {
                                        SVProgressHUD.showSuccess(withStatus: "Resigned")
                                    } else {
                                        SVProgressHUD.showError(withStatus: "Error Resigning")
                                    }
                                })
                                
                            }
                        }
                    })
                } else {
                    Utilities.showBanner(title: "Cannot Resign", subtitle: "You are the only admin.", duration: 1.5)
                    SVProgressHUD.showError(withStatus: "Error Resigning")
                    
                }
            }
            actionSheetController.addAction(resignAction)
        } else {
            
            let leaveAction: UIAlertAction = UIAlertAction(title: "Leave Group", style: .default) { action -> Void in
                // leave group
                let alert = UIAlertController(title: "Are you sure?", message: "All of your posts, messages and events will be deleted. If you are the only admin of a subgroup that subgroup will be deleted. This cannot be undone.", preferredStyle: UIAlertControllerStyle.alert)
                alert.view.tintColor = MAIN_COLOR
                //Create and add the Cancel action
                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                    //Do some stuff
                }
                alert.addAction(cancelAction)
                let leave: UIAlertAction = UIAlertAction(title: "Leave", style: .default) { action -> Void in
                    Engagement.sharedInstance.leave(oldUser: PFUser.current()!, completion: self.dismiss(animated: true, completion: nil))
                }
                alert.addAction(leave)
                self.present(alert, animated: true, completion: nil)
                
            }
            actionSheetController.addAction(leaveAction)
        }
        
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
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
}

