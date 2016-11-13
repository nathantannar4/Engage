//
//  LeftMenuController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-09-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse
import Agrume
import Material

class LeftMenuController: FormViewController {
    
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
        
        tableView.backgroundColor = MAIN_COLOR
        if Engagement.sharedInstance.name != nil && Engagement.sharedInstance.subGroupName != nil{
            if Engagement.sharedInstance.subGroupName != "" {
                if Engagement.sharedInstance.name! == "WESST" {
                    menuItems = ["Activity Feed", "\(Engagement.sharedInstance.name!)", "\(Engagement.sharedInstance.subGroupName!)", "Profile", "Messages", "Events", "Engineering Competition", "AGM & Retreat", "Executives Meeting", "Switch Groups"]
                    if isWESST {
                        menuItems.removeLast()
                    }
                } else {
                    menuItems = ["Activity Feed", "\(Engagement.sharedInstance.name!)", "\(Engagement.sharedInstance.subGroupName!)", "Profile", "Messages", "Events", "Switch Groups"]
                }
            } else {
                if Engagement.sharedInstance.name! == "WESST" {
                    menuItems = ["Activity Feed", "\(Engagement.sharedInstance.name!)", "Subgroups", "Profile", "Messages", "Events", "Engineering Competition", "AGM & Retreat", "Executives Meeting", "Switch Groups"]
                    if isWESST {
                        menuItems.removeLast()
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
            if text == "Switch Groups" {
                $0.selectionStyle = .none
            }
            }.configure {
                $0.text = text
                if text == "Switch Groups" {
                    $0.rowHeight = 100.0
                }
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
                switch self!.menuItems.index(of: item)! {
                case 0:
                    appMenuController.menu.views.first?.isHidden = false
                    self?.switchToView(target: self!.feedVC)
                case 1:
                    appMenuController.menu.views.first?.isHidden = true
                    self?.switchToView(target: self!.groupVC)
                case 2:
                    appMenuController.menu.views.first?.isHidden = true
                    self?.switchToView(target: self!.subGroupsVC)
                case 3:
                    appMenuController.menu.views.first?.isHidden = true
                    self?.switchToView(target: self!.profileVC)
                case 4:
                    appMenuController.menu.views.first?.isHidden = false
                    self?.switchToView(target: self!.messagesVC)
                case 5:
                    appMenuController.menu.views.first?.isHidden = false
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "calendarVC") as! CalendarViewController
                    self?.switchToView(target: vc)
                case 6:
                    if Engagement.sharedInstance.sponsor == true {
                        appMenuController.menu.views.first?.isHidden = true
                        self?.switchToView(target: self!.sponsorsVC)
                    } else {
                        appMenuController.menu.views.first?.isHidden = true
                        if Engagement.sharedInstance.name == "WESST" {
                            let vc = ConferenceViewController()
                            vc.conference = "WEC"
                            self?.switchToView(target: vc)
                        } else {
                            self?.dismiss(animated: true, completion: nil)
                        }
                    }
                case 7:
                    appMenuController.menu.views.first?.isHidden = true
                    if Engagement.sharedInstance.sponsor == true {
                        if Engagement.sharedInstance.name == "WESST" {
                            let vc = ConferenceViewController()
                            vc.conference = "WEC"
                            self?.switchToView(target: vc)
                        } else {
                            self?.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        let vc = ConferenceViewController()
                        vc.conference = "AGMR"
                        self?.switchToView(target: vc)
                    }
                    appMenuController.menu.views.first?.isHidden = true
                case 8:
                    appMenuController.menu.views.first?.isHidden = true
                    if Engagement.sharedInstance.sponsor == true {
                        let vc = ConferenceViewController()
                        vc.conference = "AGMR"
                        self?.switchToView(target: vc)
                    } else {
                        let vc = ConferenceViewController()
                        vc.conference = "EM"
                        self?.switchToView(target: vc)
                    }
                case 9:
                    appMenuController.menu.views.first?.isHidden = true
                    if Engagement.sharedInstance.sponsor == true {
                        let vc = ConferenceViewController()
                        vc.conference = "EM"
                        self?.switchToView(target: vc)
                    } else {
                        self?.dismiss(animated: true, completion: nil)
                    }
                default:
                    self?.dismiss(animated: true, completion: nil)
                }
            })
        }
        
        let menuSection = SectionFormer(rowFormers: menuRows)
        menuSection.headerViewFormer?.viewHeight = 0.0
        
        self.former.append(sectionFormer: menuSection)
        self.former.reload()
    }
    
    internal func switchToView(target: UIViewController) {
        if appToolbarController.rootViewController != target {
            appToolbarController.transition(to: target, duration: 0.01, options: .curveEaseOut, animations: nil , completion: closeNavigationDrawer)
        } else {
            closeNavigationDrawer(result: true)
        }
    }
    
    internal func closeNavigationDrawer(result: Bool) {
        navigationDrawerController?.closeLeftView()
    }
}
