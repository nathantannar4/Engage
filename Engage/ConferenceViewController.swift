//
//  CompetitionViewController.swift
//  WESST
//
//  Created by Tannar, Nathan on 2016-09-13.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import JSQWebViewController
import MessageUI
import BRYXBanner
import Material

class ConferenceViewController: FormViewController  {
    
    var firstLoad = true
    var positionIDs = [String]()
    var conference: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI and Table Properties
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 60
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        self.navigationItem.titleView = Utilities.setTitle(title: conference!, subtitle: "Conference")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.cm.menu, style: .plain, target: self, action: #selector(leftDrawerButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.cm.moreVertical, style: .plain, target: self, action: #selector(settingsButtonPressed))
        
        Conference.sharedInstance.clear()
        
        SVProgressHUD.show(withStatus: "Loading")
            let query = PFQuery(className: "WESST_Conferences")
            query.whereKey(PF_CONFERENCE_NAME, equalTo: self.conference!)
            query.findObjectsInBackground { (conferences: [PFObject]?, error: Error?) in
                SVProgressHUD.dismiss()
                
                if error == nil {
                    Conference.sharedInstance.conference = conferences?.first
                    if Conference.sharedInstance.conference == nil {
                        print("Creating Conference")
                        Conference.sharedInstance.name = self.conference!
                        Conference.sharedInstance.create()
                    }
                    Conference.sharedInstance.unpack()
                    self.getPositions()
                    self.configure()
                    
                } else {
                    let banner = Banner(title: "An Error Occurred", subtitle: error.debugDescription, image: nil, backgroundColor: MAIN_COLOR!)
                    banner.dismissesOnTap = true
                    banner.show(duration: 2.0)
                }
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !firstLoad {
            updateRows()
            getPositions()
            self.former.remove(section: 1)
            self.former.reload()
            self.loadOC()
        } else {
            firstLoad = false
        }
    }
    
    private func getPositions() {
        positionIDs.removeAll()
        for position in Conference.sharedInstance.positions {
            if Conference.sharedInstance.conference![position.lowercased().replacingOccurrences(of: " ", with: "")] != nil {
                positionIDs.append(Conference.sharedInstance.conference![position.lowercased().replacingOccurrences(of: " ", with: "")] as! String)
            } else {
                positionIDs.append("")
            }
        }
        print(positionIDs)
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
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.file = Conference.sharedInstance.conference![PF_CONFERENCE_COVER_PHOTO] as? PFFile
            $0.displayImage.loadInBackground()
            }.configure {
                $0.rowHeight = 200
            }.onSelected({ _ in
                if Conference.sharedInstance.coverPhoto != nil {
                    let agrume = Agrume(image: Conference.sharedInstance.coverPhoto!)
                    agrume.showFrom(self)
                }
            })
    }()
    
    private lazy var infoRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Info"
            $0.body = Conference.sharedInstance.info!
            $0.titleLabel.font = RobotoFont.medium(with: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = RobotoFont.regular(with: 15)
            $0.date = ""
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
        }
    }()
    
    private lazy var hostSchoolRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Host"
            $0.body = Conference.sharedInstance.hostSchool
            $0.date = ""
            $0.bodyColor = UIColor.black
            $0.titleLabel.font = RobotoFont.medium(with: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = RobotoFont.regular(with: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
        }
    }()
    
    private lazy var locationRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Location"
            $0.body = Conference.sharedInstance.location
            $0.date = ""
            $0.bodyColor = UIColor.black
            
            $0.titleLabel.font = RobotoFont.medium(with: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = RobotoFont.regular(with: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
        }
    }()
    
    private lazy var timeRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Dates"
            $0.body = "\(Conference.sharedInstance.start!.mediumDateString!) to \(Conference.sharedInstance.end!.mediumDateString!)"
            $0.date = ""
            $0.bodyColor = UIColor.black
            $0.titleLabel.font = RobotoFont.medium(with: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = RobotoFont.regular(with: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
        }
    }()
    
    private lazy var urlRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Website"
            $0.body = Conference.sharedInstance.url
            $0.date = ""
            $0.bodyColor = UIColor.black
            $0.titleLabel.font = RobotoFont.medium(with: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = RobotoFont.regular(with: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                if Conference.sharedInstance.url != "" {
                    let controller = WebViewController(url: NSURL(string: "http://\(Conference.sharedInstance.url!)")! as URL)
                    let nav = UINavigationController(rootViewController: controller)
                    nav.navigationBar.barTintColor = MAIN_COLOR
                    self!.present(nav, animated: true, completion: nil)
                }
        }
    }()
    
    private func configure() {
        
        let delegatePackageRow = createMenu("Delegate Portal") { [weak self] in
            self?.former.deselect(animated: true)
            self?.navigationController?.pushViewController(DelegatePackageViewController(), animated: true)
        }
        
        self.former.append(sectionFormer: SectionFormer(rowFormer: onlyImageRow, infoRow, hostSchoolRow, locationRow, timeRow, urlRow))
        if conference == "WEC" {
            self.former.insert(rowFormer: delegatePackageRow, below: urlRow)
        }
        loadOC()
    }
    
    private func loadOC() {
        
        var members = [RowFormer]()
        let memberQuery = PFUser.query()
        memberQuery!.whereKey(PF_USER_OBJECTID, containedIn: self.positionIDs)
        memberQuery!.addAscendingOrder(PF_USER_FULLNAME)
        memberQuery!.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
            if error == nil {
                if users != nil {
                    for user in users! {
                        if self.positionIDs.contains(user.objectId!) {
                            members.append(LabelRowFormer<ProfileImageDetailCell>(instantiateType: .Nib(nibName: "ProfileImageDetailCell")) {
                                $0.accessoryType = .detailButton
                                $0.iconView.backgroundColor = MAIN_COLOR
                                $0.iconView.layer.borderWidth = 1
                                $0.iconView.layer.borderColor = MAIN_COLOR?.cgColor
                                $0.iconView.image = UIImage(named: "profile_blank")
                                $0.iconView.file = user[PF_USER_PICTURE] as? PFFile
                                $0.iconView.loadInBackground()
                                $0.titleLabel.textColor = UIColor.black
                                $0.detailLabel.textColor = UIColor.gray
                                let index = self.positionIDs.index(of: user.objectId!)
                                $0.detailLabel.text = Conference.sharedInstance.positions[index!]
                                }.configure {
                                    $0.text = user[PF_USER_FULLNAME] as? String
                                    $0.rowHeight = 60
                                }.onSelected { [weak self] _ in
                                    self?.former.deselect(animated: true)
                                    let profileVC = PublicProfileViewController()
                                    profileVC.user = user
                                    let navVC = UINavigationController(rootViewController: profileVC)
                                    navVC.navigationBar.barTintColor = MAIN_COLOR!
                                    self?.present(navVC, animated: true, completion: nil)
                                })
                        }
                    }
                    self.former.insertUpdate(sectionFormer: SectionFormer(rowFormers: members).set(headerViewFormer: TableFunctions.createHeader(text: "Organizing Committee")), toSection: 1, rowAnimation: .fade)
                }
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - User actions
    
    func settingsButtonPressed() {
        
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        if Engagement.sharedInstance.admins.contains(PFUser.current()!.objectId!) {
            let editAction: UIAlertAction = UIAlertAction(title: "Edit", style: .default) { action -> Void in
                self.navigationController?.pushViewController(EditConferenceViewController(), animated: true)
            }
            actionSheetController.addAction(editAction)
            
            let adminFunctionsAction: UIAlertAction = UIAlertAction(title: "Admin Function", style: .default) { action -> Void in
                let delegateQuery = PFQuery(className: "WESST_WEC_Delegates")
                delegateQuery.limit = 300
                delegateQuery.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        var userIds = [String]()
                        if let objects = objects {
                            for object in objects {
                                let user = object.value(forKey: "user") as! PFUser
                                userIds.append(user.objectId!)
                            }
                            let vc = AdminFunctionsViewController()
                            vc.userIds = userIds
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    } else {
                        SVProgressHUD.showError(withStatus: "Network Error")
                    }
                })
            }
            actionSheetController.addAction(adminFunctionsAction)
        }
        actionSheetController.popoverPresentationController?.sourceView = self.view
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func updateRows() {
        infoRow.cellUpdate {
            $0.bodyLabel.text = Conference.sharedInstance.info
        }
        hostSchoolRow.cellUpdate {
            $0.bodyLabel.text = Conference.sharedInstance.hostSchool
        }
        locationRow.cellUpdate {
            $0.bodyLabel.text = Conference.sharedInstance.location
        }
        timeRow.cellUpdate {
            $0.body = "\(Conference.sharedInstance.start!.mediumDateString!) to \(Conference.sharedInstance.end!.mediumDateString!)"
        }
        urlRow.cellUpdate {
            $0.bodyLabel.text = Conference.sharedInstance.url
        }
        onlyImageRow.cellUpdate {
            $0.displayImage.file = Conference.sharedInstance.conference![PF_CONFERENCE_COVER_PHOTO] as? PFFile
            $0.displayImage.loadInBackground()
        }
        self.former.reload()
    }
    
    func leftDrawerButtonPressed() {
        self.evo_drawerController?.toggleDrawerSide(.left, animated: true, completion: nil)
    }
}



