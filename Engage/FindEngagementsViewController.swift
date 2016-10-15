//
//  FindEngagementsViewController.swift
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

final class FindEngagementsViewController: FormViewController {
    
    var refreshControl: UIRefreshControl!
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        title = "Public Groups"
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(EngagementsViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Plus"), style: .plain, target: self, action: #selector(createEngagement))
        
        queryEngagements()
    }
    
    func refresh(_ sender:AnyObject) {
        // Updating your data here...
        former.removeAllUpdate(rowAnimation: .fade)
        self.refreshControl?.endRefreshing()
        queryEngagements()
    }
    
    func createEngagement(_ sender: UIBarButtonItem) {
        let navVC = UINavigationController(rootViewController: CreateEngagementViewController())
        self.present(navVC, animated: true, completion: nil)
    }
    
    // MARK: Private
    
    fileprivate func queryEngagements() {
        
        var availableRows = [LabelRowFormer<ProfileImageDetailCell>]()
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        SVProgressHUD.show(withStatus: "Loading")
        let engagementsQuery = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
        engagementsQuery.addAscendingOrder(PF_ENGAGEMENTS_NAME)
        engagementsQuery.addAscendingOrder(PF_ENGAGEMENTS_MEMBER_COUNT)
        engagementsQuery.includeKey(PF_ENGAGEMENTS_MEMBERS)
        engagementsQuery.includeKey(PF_ENGAGEMENTS_ADMINS)
        engagementsQuery.whereKey(PF_INSTALLATION_OBJECTID, notContainedIn: Profile.sharedInstance.engagements)
        engagementsQuery.whereKey(PF_ENGAGEMENTS_HIDDEN, equalTo: false)
        engagementsQuery.findObjectsInBackground { (engagements: [PFObject]?, error: Error?) in
            UIApplication.shared.endIgnoringInteractionEvents()
            SVProgressHUD.dismiss()
            if error == nil {
                for engagement in engagements! {
                    availableRows.append(LabelRowFormer<ProfileImageDetailCell>(instantiateType: .Nib(nibName: "ProfileImageDetailCell")) {
                        $0.accessoryType = .disclosureIndicator
                        $0.iconView.backgroundColor = MAIN_COLOR
                        $0.iconView.layer.borderWidth = 2
                        $0.iconView.layer.borderColor = MAIN_COLOR?.cgColor
                        $0.titleLabel.textColor = UIColor.black
                        if (engagement[PF_ENGAGEMENTS_MEMBER_COUNT] as! Int) > 1 {
                            $0.detailLabel.text = "\(engagement[PF_ENGAGEMENTS_MEMBER_COUNT] as! Int) Members"
                        } else {
                            $0.detailLabel.text = "\(engagement[PF_ENGAGEMENTS_MEMBER_COUNT] as! Int) Member"
                        }
                        $0.detailLabel.textColor = UIColor.gray
                        }.configure {
                            $0.text = (engagement[PF_ENGAGEMENTS_NAME] as? String)?.uppercased()
                            $0.rowHeight = 60
                        }.onSelected { [weak self] _ in
                            self?.former.deselect(animated: true)
                            
                            // Send to Group
                            Engagement.sharedInstance.engagement = engagement
                            Engagement.sharedInstance.unpack()
                            if Engagement.sharedInstance.password != "" {
                                // Group password protected
                                let actionSheetController: UIAlertController = UIAlertController(title: "Password", message: "Case sensitive", preferredStyle: .alert)
                                
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
                                        SVProgressHUD.showError(withStatus: "Incorrect Passwod")
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
                                let actionSheetController: UIAlertController = UIAlertController(title: "Join Group?", message: nil, preferredStyle: .alert)
                                
                                //Create and add the Cancel action
                                let cancelAction: UIAlertAction = UIAlertAction(title: "No", style: .cancel) { action -> Void in
                                    //Do some stuff
                                }
                                actionSheetController.addAction(cancelAction)
                                //Create and an option action
                                let nextAction: UIAlertAction = UIAlertAction(title: "Yes", style: .default) { action -> Void in
                                    Engagement.sharedInstance.join(newUser: PFUser.current()!)
                                    Utilities.showEngagement(self!)
                                }
                                actionSheetController.addAction(nextAction)
                                
                                
                                //Present the AlertController
                                self!.present(actionSheetController, animated: true, completion: nil)
                            }
                    })
                }
                self.former.append(sectionFormer: SectionFormer(rowFormers: availableRows))
                self.former.reload()
            } else {
                Utilities.showBanner(title: "Error Loading Groups", subtitle: error.debugDescription, duration: 1.5)
            }
        }
    }
}
