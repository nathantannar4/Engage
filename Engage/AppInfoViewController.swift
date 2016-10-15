//
//  AppInfoViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-11.
//  Copyright © 2016 NathanTannar. All rights reserved.
//


import UIKit
import Former
import Parse
import Agrume
import JSQWebViewController

final class AppInfoViewController: FormViewController {
    
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset.top = 10
        tableView.contentInset.bottom = 100
        
        configure()
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
    
    // MARK: Private
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    
    private func configure() {
        title = "App Info"
        tableView.contentInset.top = 10
        tableView.contentInset.bottom = 0
        
        // Create RowFomers
        
        var aboutTheDevRows = [RowFormer]()
        
        aboutTheDevRows.append(CustomRowFormer<DetailPostCell>(instantiateType: .Nib(nibName: "DetailPostCell")) {
            $0.selectionStyle = .none
            $0.username.text = "Nathan Tannar"
            $0.info.font = .systemFont(ofSize: 16)
            $0.info.textColor = UIColor.black
            $0.info.text = "Hey everyone!\n\nThank you for supporting myself and the new WESST communication platform. For those of you who don't know me, I study Computer Engineering SFU Burnaby and have been self teaching myself Swift since Feburary of 2016.\n\nI will continue to update and support this application until it has all the features everyone wants so please, if you have a suggestion feel free to message me."
            $0.school.text =  ""
            $0.iconView.layer.borderWidth = 1
            $0.iconView.layer.masksToBounds = false
            $0.iconView.layer.borderColor = UIColor.white.cgColor
            $0.iconView.clipsToBounds = true
            $0.iconView.layer.borderWidth = 2
            $0.iconView.layer.borderColor = MAIN_COLOR?.cgColor
            $0.iconView.backgroundColor = MAIN_COLOR
            $0.iconView.layer.cornerRadius = $0.iconView.frame.height/2
            $0.iconView.image = UIImage(named: "Nathan.jpg")
            $0.date.text = ""
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            })
        aboutTheDevRows.append(createMenu("View Profile") { [weak self] in
            self?.former.deselect(animated: true)
            let nathanQuery = PFUser.query()
            nathanQuery?.whereKey(PF_USER_OBJECTID, equalTo: "3U5n1dTgnl")
            nathanQuery?.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    if let user = objects?.first {
                        let profileVC = PublicProfileViewController()
                        profileVC.user = user
                        self?.navigationController?.pushViewController(profileVC, animated: true)
                    }
                }
            })
            })
        aboutTheDevRows.append(createMenu("View Code on GitHub") { [weak self] in
            self?.former.deselect(animated: true)
            let controller = WebViewController(url: NSURL(string: "https://github.com/nathantannar4/WESST")! as URL)
            let nav = UINavigationController(rootViewController: controller)
            nav.navigationBar.barTintColor = MAIN_COLOR
            self!.present(nav, animated: true, completion: nil)
            })
        
        var futureEnhancementsRows = [CustomRowFormer<DynamicHeightCell>]()
        
        futureEnhancementsRows.append(CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "October"
            $0.date = ""
            $0.body = "- Simple Suggestions from WESST AGM"
            $0.titleColor = MAIN_COLOR
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected({ (cell: CustomRowFormer<DynamicHeightCell>) in
                self.former.deselect(animated: true)
            }))
        
        futureEnhancementsRows.append(CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Fall 2016"
            $0.date = ""
            $0.body = "- Push Notification Enhancements\n- Conference Page Enhancements\n- Complex Suggestions from WESST AGM\n-Database Migration to another provider"
            $0.titleColor = MAIN_COLOR
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected({ (cell: CustomRowFormer<DynamicHeightCell>) in
                self.former.deselect(animated: true)
            }))
        
        var changeLogRows = [CustomRowFormer<DynamicHeightCell>]()
        
        changeLogRows.append(CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Version 1.0.2"
            $0.date = "September 28, 2016"
            $0.body = "- Bug Fixes\n- Photo Resolution Display\n- Event Calendar not displaying on some screens\n- SubGroup admin assignment bugs\n- Push notifications for messages"
            $0.titleColor = MAIN_COLOR
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected({ (cell: CustomRowFormer<DynamicHeightCell>) in
                self.former.deselect(animated: true)
            }))
        
        changeLogRows.append(CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Version 1.0.1"
            $0.date = "September 19, 2016"
            $0.body = "- Initial Release Bug Fixes\n- Edit Post Functionality\n- Edit Event Functionality\n- Reworked Members View\n- Added App Info Page"
            $0.titleColor = MAIN_COLOR
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected({ (cell: CustomRowFormer<DynamicHeightCell>) in
                self.former.deselect(animated: true)
            }))
        
        changeLogRows.append(CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Version 1.0.0"
            $0.date = "September 16, 2016"
            $0.body = "- Public Release"
            $0.titleColor = MAIN_COLOR
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected({ (cell: CustomRowFormer<DynamicHeightCell>) in
                self.former.deselect(animated: true)
            }))
        
        let licenseRow = CustomRowFormer<TitleCell>() {
            $0.accessoryType = .disclosureIndicator
            $0.textLabel?.text = "View Licenses and Acknowledgements"
            $0.textLabel?.textAlignment = .center
            $0.textLabel?.textColor = MAIN_COLOR
            $0.textLabel?.font = .boldSystemFont(ofSize: 16)
            }.onSelected {_ in
                self.former.deselect(animated: true)
                let licensingViewController = LicensingViewController()
                
                licensingViewController.title = "Acknowledgments"
                
                let parseItem = LicensingItem(
                    title: "Parse",
                    license: License.mit(owner: "Parse", years: "2016")
                )
                
                let formerItem = LicensingItem(
                    title: "Former",
                    license: License.mit(owner: "Ryo Aoyama (https://github.com/ra1028/Former)", years: "2015")
                )
                
                let messagesItem = LicensingItem(
                    title: "JSQMessagesController",
                    license: License.mit(owner: "Jessie Squires (https://github.com/jessesquires/JSQMessagesViewController)", years: "2015")
                )
                
                let webItem = LicensingItem(
                    title: "JSQWebViewController",
                    license: License.mit(owner: "Jessie Squires (https://github.com/jessesquires/JSQWebViewController)", years: "2016")
                )
                
                let bannerItem = LicensingItem(
                    title: "BRYX Banner",
                    license: License.mit(owner: "Harlan Haskins (https://github.com/bryx-inc/BRYXBanner)", years: "2015")
                )
                
                let agrumeItem = LicensingItem(
                    title: "Agrume",
                    license: License.mit(owner: "Jan Gorman (https://github.com/JanGorman/Agrume)", years: "2015")
                )
                
                let progressItem = LicensingItem(
                    title: "SVProgressHUD",
                    license: License.mit(owner: "Sam Vermette (https://github.com/SVProgressHUD/SVProgressHUD)", years: "2016")
                )
                
                licensingViewController.items = [parseItem, formerItem, messagesItem, webItem, bannerItem, agrumeItem, progressItem]
                self.navigationController?.pushViewController(licensingViewController, animated: true)
        }
        
        
        // Create SectionFormers
        
        let aboutSection = SectionFormer(rowFormers: aboutTheDevRows).set(headerViewFormer: TableFunctions.createHeader(text: "About the Developer"))
        
        let futureSection = SectionFormer(rowFormers: futureEnhancementsRows).set(headerViewFormer: TableFunctions.createHeader(text: "Coming Soon"))
        
        let changeLogSection = SectionFormer(rowFormers: changeLogRows).set(headerViewFormer: TableFunctions.createHeader(text: "Change Log"))
        
        let licenseSection = SectionFormer(rowFormer: licenseRow).set(headerViewFormer: TableFunctions
            .createHeader(text: "Added Frameworks")).set(footerViewFormer: TableFunctions.createFooter(text: "WESST - Version: \(VERSION)"))
        former.append(sectionFormer: futureSection, changeLogSection, aboutSection, licenseSection)
    }
}
