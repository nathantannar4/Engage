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

class EngagementMenuController: UITableViewController {
    
    var menuItems = [String]()
    let feedVC = FeedViewController()
    let groupVC = EngagementGroupDetailsViewController()
    let subGroupsVC = SubGroupsViewController()
    let profileVC = ProfileViewController()
    let sponsorsVC = SponsorsViewController()
    let messagesVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "messagesVC") as! MessagesViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Engagement.sharedInstance.subGroupName != "" {
            self.menuItems = ["Menu", "Activity Feed", "\(Engagement.sharedInstance.name!)", "\(Engagement.sharedInstance.subGroupName!)", "Profile", "Messages", "Events", "Engineering Competition", "AGM & Retreat", "Executives Meeting"]
        } else {
            self.menuItems = ["Menu", "Activity Feed", "\(Engagement.sharedInstance.name!)", "Subgroups", "Profile", "Messages", "Events", "Engineering Competition", "AGM & Retreat", "Executives Meeting"]
        }
        
        self.prepareTable()
    }
    
    // MARK: - UITableView Delegate Functions
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isWESST {
            return 1
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.menuItems.count
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UITableViewHeaderFooterView()
        footer.contentView.backgroundColor = MAIN_COLOR
        return footer
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.contentView.backgroundColor = MAIN_COLOR
        cell.textLabel!.font = MAIN_FONT_SUBTITLE
        cell.textLabel!.textColor = UIColor.white
        cell.selectionStyle = .none
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 { cell.textLabel!.font = MAIN_FONT_TITLE }
            cell.textLabel!.text = self.menuItems[indexPath.row]
            return cell
        case 1:
            cell.textLabel!.text = "Switch Groups"
            return cell
        default:
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 1:
                self.switchToView(target: self.feedVC)
            case 2:
                self.switchToView(target: self.groupVC)
            case 3:
                self.switchToView(target: self.subGroupsVC)
            case 4:
                self.switchToView(target: self.profileVC)
            case 5:
                self.switchToView(target: self.messagesVC)
            case 6:
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "calendarVC") as! CalendarViewController
                self.switchToView(target: vc)
            case 7:
                if Engagement.sharedInstance.sponsor == true {
                    self.switchToView(target: self.sponsorsVC)
                } else {
                    if Engagement.sharedInstance.name == "WESST" {
                        let vc = ConferenceViewController()
                        vc.conference = "WEC"
                        self.switchToView(target: vc)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            case 8:
                if Engagement.sharedInstance.sponsor == true {
                    if Engagement.sharedInstance.name == "WESST" {
                        let vc = ConferenceViewController()
                        vc.conference = "WEC"
                        self.switchToView(target: vc)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    let vc = ConferenceViewController()
                    vc.conference = "AGMR"
                    self.switchToView(target: vc)
                }
            case 9:
                if Engagement.sharedInstance.sponsor == true {
                    let vc = ConferenceViewController()
                    vc.conference = "AGMR"
                    self.switchToView(target: vc)
                } else {
                    let vc = ConferenceViewController()
                    vc.conference = "EM"
                    self.switchToView(target: vc)
                }
            case 10:
                if Engagement.sharedInstance.sponsor == true {
                    let vc = ConferenceViewController()
                    vc.conference = "EM"
                    self.switchToView(target: vc)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            default:
                break
            }
        case 1:
            self.dismiss(animated: true, completion: nil)
        default:
            break
        }
    }
    
    // MARK: - Preperation Functions
    private func prepareTable() {
        self.tableView.contentInset.top = 20
        self.tableView.separatorStyle = .none
        self.tableView.bounces = false
        self.tableView.backgroundColor = MAIN_COLOR
        self.tableView.estimatedRowHeight = 44
    }
    
    // MARK: - Navigation
    private func switchToView(target: UIViewController) {
        let navVC = UINavigationController(rootViewController: target)
        navVC.navigationBar.barTintColor = MAIN_COLOR
        self.evo_drawerController?.setCenter(navVC, withCloseAnimation: true, completion: nil)
    }
}
