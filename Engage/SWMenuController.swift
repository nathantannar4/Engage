//
//  MenuController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-09-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse
import Agrume

final class SWMenuController: FormViewController {
    
    var menuItems = [String]()
    let feedVC = FeedViewController()
    let groupVC = EngagementGroupDetailsViewController()
    let subGroupsVC = SubGroupsViewController()
    let profileVC = ProfileViewController()
    let sponsorsVC = SponsorsViewController()
    let messagesVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "messagesVC") as! MessagesViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        tableView.contentInset.top = 30
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.backgroundColor = MAIN_COLOR
        if Engagement.sharedInstance.name != nil && Engagement.sharedInstance.subGroupName != nil{
            if Engagement.sharedInstance.subGroupName != "" {
                if Engagement.sharedInstance.name! == "WESST" {
                    menuItems = ["Activity Feed", "\(Engagement.sharedInstance.name!)", "\(Engagement.sharedInstance.subGroupName!)", "Profile", "Messages", "Events", "Engineering Competition", "AGM & Retreat", "Executives Meeting", "Switch Groups"]
                    if isWESST {
                        menuItems.popLast()
                    }
                } else {
                    menuItems = ["Activity Feed", "\(Engagement.sharedInstance.name!)", "\(Engagement.sharedInstance.subGroupName!)", "Profile", "Messages", "Events", "Switch Groups"]
                }
            } else {
                if Engagement.sharedInstance.name! == "WESST" {
                    menuItems = ["Activity Feed", "\(Engagement.sharedInstance.name!)", "Subgroups", "Profile", "Messages", "Events", "Engineering Competition", "AGM & Retreat", "Executives Meeting", "Switch Groups"]
                    if isWESST {
                        menuItems.popLast()
                    }
                } else {
                    menuItems = ["Activity Feed", "\(Engagement.sharedInstance.name!)", "Subgroups", "Profile", "Messages", "Events", "Switch Groups"]
                }
            }
            if Engagement.sharedInstance.sponsor == true {
                menuItems.insert("Sponsors", at: 6)
            }
        } else {
            // Engagement wasn't unpacked on time
            menuItems = ["Activity Feed", "Group", "Subgroups", "Profile", "Messages", "Events", "Switch Groups"]
        }
        
        if self.former.sectionFormers.count > 0 {
            self.former.removeAll()
            self.former.reload()
        }
        configure()
    }
    
    let createMenu: ((String, (() -> Void)?) -> RowFormer) = { text, onSelected in
        return LabelRowFormer<FormLabelCell>() {
            //$0.selectionStyle = .
            $0.self.backgroundColor = MAIN_COLOR
            $0.titleLabel.textColor = UIColor.white
            $0.titleLabel.font = .boldSystemFont(ofSize: 16)
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
    }
    
    private func configure() {
        
        var menuRows = [RowFormer]()
        menuRows.append(LabelRowFormer<FormLabelCell>() {
            $0.selectionStyle = .none
            $0.self.backgroundColor = MAIN_COLOR
            $0.titleLabel.textColor = UIColor.white
            $0.titleLabel.font = .boldSystemFont(ofSize: 20)
            }.configure {
                $0.text = "Menu"
        })
        for item in menuItems {
            menuRows.append(createMenu(item) { [weak self] in
                self?.former.deselect(animated: true)
                var navVC: UINavigationController!
                switch self!.menuItems.index(of: item)! {
                case 0:
                    navVC = UINavigationController(rootViewController: self!.feedVC)
                case 1:
                    navVC = UINavigationController(rootViewController: self!.groupVC)
                case 2:
                    navVC = UINavigationController(rootViewController: self!.subGroupsVC)
                case 3:
                    navVC = UINavigationController(rootViewController: self!.profileVC)
                case 4:
                    navVC = UINavigationController(rootViewController: self!.messagesVC)
                case 5:
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "calendarVC") as! CalendarViewController
                    navVC = UINavigationController(rootViewController: vc)
                case 6:
                    if Engagement.sharedInstance.sponsor == true {
                        navVC = UINavigationController(rootViewController: self!.sponsorsVC)
                    } else {
                        if Engagement.sharedInstance.name == "WESST" {
                            let vc = ConferenceViewController()
                            vc.conference = "WEC"
                            navVC = UINavigationController(rootViewController: vc)
                        } else {
                            self?.dismiss(animated: true, completion: nil)
                        }
                    }
                case 7:
                    if Engagement.sharedInstance.sponsor == true {
                        if Engagement.sharedInstance.name == "WESST" {
                            let vc = ConferenceViewController()
                            vc.conference = "WEC"
                            navVC = UINavigationController(rootViewController: vc)
                        } else {
                            self?.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        let vc = ConferenceViewController()
                        vc.conference = "AGMR"
                        navVC = UINavigationController(rootViewController: vc)
                    }
                case 8:
                    if Engagement.sharedInstance.sponsor == true {
                        let vc = ConferenceViewController()
                        vc.conference = "AGMR"
                        navVC = UINavigationController(rootViewController: vc)
                    } else {
                        let vc = ConferenceViewController()
                        vc.conference = "EM"
                        navVC = UINavigationController(rootViewController: vc)
                    }
                case 9:
                    if Engagement.sharedInstance.sponsor == true {
                        let vc = ConferenceViewController()
                        vc.conference = "EM"
                        navVC = UINavigationController(rootViewController: vc)
                    } else {
                        self?.dismiss(animated: true, completion: nil)
                    }
                default:
                    self?.dismiss(animated: true, completion: nil)
                }
                if navVC != nil {
                    navVC.navigationBar.barTintColor = MAIN_COLOR!
                    let segue = SWRevealViewControllerSeguePushController(identifier: item, source: self!, destination: navVC)
                    segue.perform()
                }
            })
        }
        
        let menuSection = SectionFormer(rowFormers: menuRows)
        menuSection.headerViewFormer?.viewHeight = 0.0
        
        self.former.append(sectionFormer: menuSection)
        self.former.reload()
    }
}
