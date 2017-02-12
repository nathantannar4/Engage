//
//  AdminFunctionsViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 11/8/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//
/*
import Former
import Parse
import MessageUI
import SVProgressHUD
import Material

class AdminFunctionsViewController: FormViewController, SelectUsersFromGroupDelegate, MFMailComposeViewControllerDelegate {
    
    var pushNotificationText = ""
    var selectUsersForPush = false
    var userIds = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if userIds.count == 0 {
            userIds = Engagement.sharedInstance.members
        }
        
        self.title = "Admin Functions"
        self.navigationItem.titleView = Utilities.setTitle(title: "Admin Function", subtitle: "\(userIds.count) Members")
        self.tableView.contentInset.top = 10
        self.tableView.contentInset.bottom = 60
        
        
        
        self.configure()
    }
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private func configure() {
        
        let pushRow = TextViewRowFormer<FormTextViewCell>() { [weak self] in
            $0.textView.textColor = .formerSubColor()
            $0.textView.font = RobotoFont.regular(with: 15)
            $0.textView.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Message"
                $0.text = ""
            }.onTextChanged {
                self.pushNotificationText = $0
        }
        
        let pushSendRow = createMenu("Send Push") { [weak self] in
            self?.former.deselect(animated: true)
            if (self?.pushNotificationText.characters.count)! > 1 && (self?.pushNotificationText.characters.count)! <= 140 {
                let actionSheetController: UIAlertController = UIAlertController(title: "Send Push", message: "Select your audience", preferredStyle: .actionSheet)
                actionSheetController.view.tintColor = MAIN_COLOR
                
                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                    //Just dismiss the action sheet
                }
                actionSheetController.addAction(cancelAction)
                
                let selectMembersAction: UIAlertAction = UIAlertAction(title: "Select Members", style: .default) { action -> Void in
                
                    self?.selectUsersForPush = true
                    let vc = SelectUsersFromGroupViewController()
                    vc.delegate = self
                    let navVC = UINavigationController(rootViewController:  vc)
                    navVC.navigationBar.barTintColor = MAIN_COLOR!
                    self?.present(navVC, animated: true, completion: nil)
                }
                actionSheetController.addAction(selectMembersAction)
                
                let allMembersAction: UIAlertAction = UIAlertAction(title: "All Members", style: .default) { action -> Void in
                    SVProgressHUD.show(withStatus: "Loading Members")
                    let userQuery = PFUser.query()!
                    userQuery.limit = 1000
                    userQuery.whereKey("objectId", containedIn: self!.userIds)
                    userQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                        if error == nil {
                            var idString = ""
                            if let users = users {
                                for user in users {
                                    idString.append(user.objectId!)
                                }
                            }
                            SVProgressHUD.dismiss()
                            self?.pushToUsers(id: idString)
                            
                        } else {
                            SVProgressHUD.showError(withStatus: "Network Error")
                        }
                    })

                }
                actionSheetController.addAction(allMembersAction)
                
                actionSheetController.popoverPresentationController?.sourceView = self?.view
                
                //Present the AlertController
                self?.present(actionSheetController, animated: true, completion: nil)
            } else {
                SVProgressHUD.showError(withStatus: "Notifiation should be under 140 characters")
            }
        }
        
        let emailRow = createMenu("Email Members") { [weak self] in
            self?.former.deselect(animated: true)
            let actionSheetController: UIAlertController = UIAlertController(title: "Email Members", message: "Select your audience", preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = MAIN_COLOR
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            let selectMembersAction: UIAlertAction = UIAlertAction(title: "Select Members", style: .default) { action -> Void in
                self?.selectUsersForPush = false
                let vc = SelectUsersFromGroupViewController()
                vc.delegate = self
                let navVC = UINavigationController(rootViewController:  vc)
                navVC.navigationBar.barTintColor = MAIN_COLOR!
                self?.present(navVC, animated: true, completion: nil)
            }
            actionSheetController.addAction(selectMembersAction)
            
            let allMembersAction: UIAlertAction = UIAlertAction(title: "All Members", style: .default) { action -> Void in
                SVProgressHUD.show(withStatus: "Loading Emails")
                let userQuery = PFUser.query()!
                userQuery.limit = 1000
                userQuery.whereKey("objectId", containedIn: self!.userIds)
                userQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                    if error == nil {
                        var emails = [String]()
                        if let users = users {
                            for user in users {
                                emails.append(user.value(forKey: "email") as! String)
                            }
                        }
                        SVProgressHUD.dismiss()
                        self?.emailToUsers(emails: emails)
                        
                    } else {
                        SVProgressHUD.showError(withStatus: "Network Error")
                    }
                })
            }
            actionSheetController.addAction(allMembersAction)
            
            actionSheetController.popoverPresentationController?.sourceView = self?.view
            
            //Present the AlertController
            self?.present(actionSheetController, animated: true, completion: nil)
        }
        
        self.former.append(sectionFormer: SectionFormer(rowFormer: pushRow, pushSendRow).set(headerViewFormer: TableFunctions.createHeader(text: "Announcement")))
        self.former.append(sectionFormer: SectionFormer(rowFormer: emailRow).set(headerViewFormer: TableFunctions.createHeader(text: "Email Notifications")))
        
        if Conference.sharedInstance.name == "WEC" {
            let exportRow = createMenu("Email Data") { [weak self] in
                self?.former.deselect(animated: true)
                SVProgressHUD.show(withStatus: "Loading Data")
                let exportQuery = PFQuery(className: "WESST_WEC_Delegates")
                exportQuery.limit = 1000
                exportQuery.includeKey("user")
                exportQuery.order(byAscending: "school")
                exportQuery.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        var exportString = ""
                        if let objects = objects {
                            for object in objects {
                                let user = object.object(forKey: "user") as! PFUser
                                exportString.append((user.value(forKey: PF_USER_FULLNAME) as! String) + " ")
                                
                                for key in object.allKeys {
                                    if key != "user" {
                                        exportString.append("\(object.value(forKey: key)) |")
                                    }
                                }
                                
                                exportString.append("\n")
                            }
                        }
                        SVProgressHUD.dismiss()
                        let mailComposeViewController = MFMailComposeViewController()
                        mailComposeViewController.navigationBar.tintColor = UIColor.white
                        mailComposeViewController.navigationBar.shadowImage = UIImage()
                        mailComposeViewController.navigationBar.setBackgroundImage(UIImage(), for: .default)
                        mailComposeViewController.mailComposeDelegate = self
                        mailComposeViewController.setToRecipients([PFUser.current()!.value(forKey: PF_USER_EMAIL) as! String])
                        mailComposeViewController.setMessageBody(exportString, isHTML: false)
                        mailComposeViewController.setSubject("[Notification] \(Engagement.sharedInstance.name!)")
                        mailComposeViewController.view.tintColor = MAIN_COLOR
                        mailComposeViewController.navigationBar.barTintColor = MAIN_COLOR!
                        if MFMailComposeViewController.canSendMail() {
                            self?.present(mailComposeViewController, animated: true, completion: { UIApplication.shared.statusBarStyle = .lightContent })
                        }
                        
                    } else {
                        SVProgressHUD.showError(withStatus: "Network Error")
                    }
                })
            }
            
            self.former.append(sectionFormer: SectionFormer(rowFormer: exportRow).set(headerViewFormer: TableFunctions.createHeader(text: "Export Members")))
        }
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
    
    private func emailToUsers(emails: [String]) {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.navigationBar.tintColor = UIColor.white
        mailComposeViewController.navigationBar.shadowImage = UIImage()
        mailComposeViewController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        mailComposeViewController.mailComposeDelegate = self
        mailComposeViewController.setToRecipients(emails)
        mailComposeViewController.setMessageBody("", isHTML: false)
        mailComposeViewController.setSubject("[Notification] \(Engagement.sharedInstance.name!)")
        mailComposeViewController.view.tintColor = MAIN_COLOR
        mailComposeViewController.navigationBar.barTintColor = MAIN_COLOR!
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: { UIApplication.shared.statusBarStyle = .lightContent })
        }
    }
    
    private func pushToUsers(id: String) {
        let announcementObject = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Announcements")
        announcementObject[PF_POST_USER] = PFUser.current()!
        announcementObject[PF_POST_INFO] = self.pushNotificationText
        announcementObject.saveInBackground { (success: Bool, error: Error?) in
            if success {
                SVProgressHUD.showSuccess(withStatus: "Announcement Sent")
                PushNotication.sendPushNotificationMessage(id, text: self.pushNotificationText)
                self.pushNotificationText = ""
                self.former.removeAll()
                self.configure()
            } else {
                SVProgressHUD.showError(withStatus: "Network Error")
            }
        }
    }
    
    func didSelectMultipleUsers(selectedUsers: [PFUser]!) {
        if self.selectUsersForPush {
            // PUSH NOTIFICATION ACTION
            var idString = ""
            for user in selectedUsers {
                idString.append(user.objectId!)
            }
            self.pushToUsers(id: idString)
        } else {
            // EMAIL ACTION
            var emails = [String]()
            for user in selectedUsers {
                emails.append(user.value(forKey: "email") as! String)
            }
            self.emailToUsers(emails: emails)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}
 */
