//
//  DelegateProfileViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 11/25/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import MessageUI
import BRYXBanner
import Material
import M13PDFKit

class DelegateProfileViewController: FormViewController, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate  {
    
    var user: PFObject?
    var delegateInfo: PFObject?
    var button = UIButton()
    
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
        self.tableView.contentInset.bottom = 100
        configure()
    }
    
    func messageButtonPressed() {
        let user1 = PFUser.current()!
        let user2 = user! as? PFUser
        
        let messageVC = ChatViewController()
        messageVC.groupId = Messages.startPrivateChat(user1: user1, user2: user2!)
        messageVC.groupName = user2!.value(forKey: PF_USER_FULLNAME) as! String
        
        self.navigationController?.pushViewController(messageVC, animated: true)
    }
    
    func closeButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func infoButtonPressed() {
        
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
                    mailComposeViewController.navigationBar.backgroundColor = MAIN_COLOR
                    if MFMailComposeViewController.canSendMail() {
                        self.present(mailComposeViewController, animated: true, completion: nil)
                    } else {
                        let banner = Banner(title: "Failed to send email", subtitle: "Please check your network settings", image: nil, backgroundColor: MAIN_COLOR!)
                        banner.dismissesOnTap = true
                        banner.show(duration: 2.0)
                    }
                }
        }
        
        var delegateInfoRow = [CustomRowFormer<DynamicHeightCell>]()
        
        for field in delegateInfo!.allKeys {
            delegateInfoRow.append(CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
                $0.selectionStyle = .none
                $0.title = field.replacingOccurrences(of: "_", with: "  ").capitalized
                $0.body = self.delegateInfo![field] as? String
                $0.date = ""
                $0.bodyColor = UIColor.black
                $0.titleLabel.font = RobotoFont.medium(with: 15)
                $0.titleLabel.textColor = MAIN_COLOR
                $0.bodyLabel.font = RobotoFont.regular(with: 15)
                }.configure {
                    $0.rowHeight = UITableViewAutomaticDimension
            })
        }
        
        let resumeRow = self.createMenu("View Resume") { [weak self] in
            self?.former.deselect(animated: true)
            
            let resume = self?.user!.value(forKey: "resume") as? PFFile
            if resume != nil {
                resume?.getDataDownloadStreamInBackground(progressBlock: { (progress: Int32) in
                    SVProgressHUD.showProgress(Float(progress), status: "Downloading")
                    if progress == 100 {
                        print("Downloaded Resume")
                        if resume != nil {
                            let viewer = PDFKBasicPDFViewer()
                            let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0].appending("/Caches/Parse/PFFileCache/\(resume!.name)")
                            let document: PDFKDocument = PDFKDocument(contentsOfFile: path, password: nil)
                            SVProgressHUD.dismiss()
                            viewer.loadDocument(document)
                            let navVC = UINavigationController(rootViewController: viewer)
                            navVC.navigationBar.barTintColor = MAIN_COLOR
                            viewer.navigationItem.titleView = Utilities.setTitle(title: "\(self?.user!.value(forKey: PF_USER_FULLNAME) as! String)'s", subtitle: "Resume") 
                            self?.present(navVC, animated: true)
                        } else {
                            SVProgressHUD.showError(withStatus: "An Error Occurred")
                        }
                    }
                })
            } else {
                SVProgressHUD.showError(withStatus: "No Resume Exists")
            }
            
        }
        
        self.former.append(sectionFormer: SectionFormer(rowFormer: headerRow, phoneRow, emailRow))
        self.former.append(sectionFormer: SectionFormer(rowFormer: resumeRow).set(headerViewFormer: TableFunctions.createHeader(text: "Resume")))
        self.former.append(sectionFormer: SectionFormer(rowFormers: delegateInfoRow).set(headerViewFormer: TableFunctions.createHeader(text: "Delegate Info")))
        self.former.reload()
        
    }

    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    let createMenu: ((String, (() -> Void)?) -> RowFormer) = { text, onSelected in
        return LabelRowFormer<FormLabelCell>() {
            $0.tintColor = MAIN_COLOR
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 16)
            $0.accessoryType = .detailButton
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
    }
}

