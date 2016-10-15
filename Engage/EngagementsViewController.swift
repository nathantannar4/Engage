//
//  EngagementsViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-11.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse
import Agrume
import SVProgressHUD

final class EngagementsViewController: FormViewController {
    
    var firstLoad = true
    var engagementsCount = 0
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        title = "Engage"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutButtonPressed))
        
        SVProgressHUD.show(withStatus: "Loading")
        queryEngagements()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Engagement.sharedInstance.clear()
        MAIN_COLOR = UIColor.flatSkyBlueColorDark()
        refresh(self)
    }
    
    func refresh(_ sender:AnyObject) {
        // Updating your data here...
        queryEngagements()
    }
    
    func createEngagement(_ sender: UIBarButtonItem) {
        let navVC = UINavigationController(rootViewController: CreateEngagementViewController())
        self.present(navVC, animated: true, completion: nil)
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
    
    fileprivate lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.image = UIImage(named: "Engage-Wide.jpg")
            $0.displayImage.contentMode = UIViewContentMode.scaleAspectFit
            }.configure {
                $0.rowHeight = 200
            }
    }()
    
    // MARK: Private

    fileprivate func queryEngagements() {
        
        var myRows = [RowFormer]()
        let engagementsQuery = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
        engagementsQuery.addAscendingOrder(PF_ENGAGEMENTS_NAME)
        engagementsQuery.includeKey(PF_ENGAGEMENTS_MEMBERS)
        engagementsQuery.includeKey(PF_ENGAGEMENTS_ADMINS)
        engagementsQuery.whereKey(PF_INSTALLATION_OBJECTID, containedIn: Profile.sharedInstance.engagements)
        engagementsQuery.findObjectsInBackground { (engagements: [PFObject]?, error: Error?) in
            SVProgressHUD.dismiss()
            if error == nil {
                if engagements?.count != self.engagementsCount {
                    if self.former.sectionFormers.count > 0 {
                        self.former.removeAll()
                        self.former.reload()
                    }
                    self.engagementsCount = (engagements?.count)!
                    for engagement in engagements! {
                        myRows.append(CustomRowFormer<DetailLeftLabelCell>(instantiateType: .Nib(nibName: "DetailLeftLabelCell")) {
                            $0.accessoryType = .disclosureIndicator
                            $0.titleLabel.text = engagement[PF_ENGAGEMENTS_NAME] as! String?
                            $0.titleLabel.textColor = UIColor.black
                            if (engagement[PF_ENGAGEMENTS_MEMBER_COUNT] as! Int) > 1 {
                                $0.detailLabel.text = "\(engagement[PF_ENGAGEMENTS_MEMBER_COUNT] as! Int) Members"
                            } else {
                                $0.detailLabel.text = "\(engagement[PF_ENGAGEMENTS_MEMBER_COUNT] as! Int) Member"
                            }
                            $0.detailLabel.textColor = UIColor.gray
                            }.configure {
                                $0.rowHeight = 60
                            }.onSelected { [weak self] _ in
                                self?.former.deselect(animated: true)
                                
                                // Send to Group
                                Engagement.sharedInstance.engagement = engagement
                                Engagement.sharedInstance.unpack()
                                Utilities.showEngagement(self!)
                        })
                    }
                    let findRow = self.createMenu("Find Groups") { [weak self] in
                        self?.former.deselect(animated: true)
                        self?.navigationController!.pushViewController(FindEngagementsViewController(), animated: true)
                    }
                    let joinRow = self.createMenu("Join Group by Name") { [weak self] in
                        self?.former.deselect(animated: true)
                        
                        let actionSheetController: UIAlertController = UIAlertController(title: "Group Name", message: "Not case sensitive", preferredStyle: .alert)
                        actionSheetController.view.tintColor = MAIN_COLOR
                        
                        //Create and add the Cancel action
                        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                            //Do some stuff
                        }
                        actionSheetController.addAction(cancelAction)
                        //Create and an option action
                        let nextAction: UIAlertAction = UIAlertAction(title: "Join", style: .default) { action -> Void in
                            //Do some other stuff
                            let entry = actionSheetController.textFields![0].text!
                            let searchQuery = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
                            searchQuery.whereKey(PF_ENGAGEMENTS_LOWERCASE_NAME, equalTo: entry.lowercased())
                            searchQuery.findObjectsInBackground(block: { (engagements: [PFObject]?, error: Error?) in
                                if error == nil {
                                    if (engagements?.count)! > 0 {
                                        // Process join request
                                        Engagement.sharedInstance.engagement = engagements![0]
                                        Engagement.sharedInstance.unpack()
                                        if Engagement.sharedInstance.password != "" {
                                            // Group password protected
                                            let actionSheetController: UIAlertController = UIAlertController(title: "Password", message: "Case sensitive", preferredStyle: .alert)
                                            actionSheetController.view.tintColor = MAIN_COLOR
                                            
                                            //Create and add the Cancel action
                                            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                                                //Do some stuff
                                            }
                                            actionSheetController.addAction(cancelAction)
                                            //Create and an option action
                                            let nextAction: UIAlertAction = UIAlertAction(title: "Join", style: .default) { action -> Void in
                                                let password = actionSheetController.textFields![0].text!
                                                if password == Engagement.sharedInstance.password {
                                                    if !Profile.sharedInstance.engagements.contains(engagements![0].objectId!) {
                                                        Engagement.sharedInstance.join(newUser: PFUser.current()!)
                                                    }
                                                    Utilities.showEngagement(self!)
                                                } else {
                                                    SVProgressHUD.showError(withStatus: "Incorrect Password")
                                                }
                                            }
                                            actionSheetController.addAction(nextAction)
                                            //Add a text field
                                            actionSheetController.addTextField { textField -> Void in
                                                //TextField configuration
                                            }
                                            
                                            //Present the AlertController
                                            self!.present(actionSheetController, animated: true, completion: nil)
                                            
                                        } else {
                                            // Open group
                                            if !Profile.sharedInstance.engagements.contains(engagements![0].objectId!) {
                                                Engagement.sharedInstance.join(newUser: PFUser.current()!)
                                            }
                                            Utilities.showEngagement(self!)
                                        }
                                        
                                    } else {
                                        // Search returned no group
                                        SVProgressHUD.showError(withStatus: "Group Does not Exist")
                                    }
                                } else {
                                    // Error while searching database
                                    SVProgressHUD.showError(withStatus: "Network Error")
                                }
                            })
                        }
                        actionSheetController.addAction(nextAction)
                        //Add a text field
                        actionSheetController.addTextField { textField -> Void in
                            //TextField configuration
                        }
                        
                        //Present the AlertController
                        self!.present(actionSheetController, animated: true, completion: nil)
                    }
                    
                    myRows.append(self.onlyImageRow)
                    myRows.append(findRow)
                    myRows.append(joinRow)
                    
                    self.former.append(sectionFormer: SectionFormer(rowFormers: myRows).set(headerViewFormer: TableFunctions.createHeader(text: "My Groups")))
                    self.former.reload()
                    
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Plus"), style: .plain, target: self, action: #selector(self.createEngagement))
                }
            } else {
                self.former.append(sectionFormer: self.reloadSection)
                self.former.reload()
                print(error)
                SVProgressHUD.showError(withStatus: "You appear to be offline")
            }
        }
    }
    
    private lazy var reloadSection: SectionFormer = {
        let loadMoreRow = CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.text = "Reload"
            $0.titleLabel.textAlignment = .center
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                self?.refresh(self!)
        }
        return SectionFormer(rowFormer: loadMoreRow)
    }()
    
    func logoutButtonPressed(sender: UIBarButtonItem) {
        PFUser.logOut()
        Profile.sharedInstance.clear()
        PushNotication.parsePushUserResign()
        Utilities.postNotification(NOTIFICATION_USER_LOGGED_OUT)
        self.dismiss(animated: true, completion: nil)
    }
}
