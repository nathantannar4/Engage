//
//  EngagementViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/29/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Agrume
import Parse

class EngagementViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate {
    
    private var engagement: Engagement!
    
    // MARK: - Initializers
    public convenience init(engagement: Engagement) {
        self.init()
        self.engagement = engagement
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.engagement.name
        self.dataSource = self
        self.delegate = self
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.Apple.info, style: .plain, target: self, action: #selector(groupOptions(sender:)))
        self.prepareTableView()
    }
    
    func pullToRefresh(sender: UIRefreshControl) {
        self.tableView.refreshControl?.beginRefreshing()
        self.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    // MARK: Preperation Functions
    
    private func prepareTableView() {
        self.tableView.contentInset.top = 190
        self.tableView.contentInset.bottom = 100
        self.tableView.emptyHeaderHeight = 10
        let refreshControl = UIRefreshControl()
        if self.engagement.coverImage != nil {
            refreshControl.tintColor = UIColor.white
            refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh", attributes: [NSForegroundColorAttributeName : UIColor.white])
        } else {
            refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        }
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    // MARK: User Action
    
    func editEngagement(sender: UIButton) {
        let navVC = UINavigationController(rootViewController: EditGroupViewController(group: Engagement.current()))
        self.present(navVC, animated: true, completion: nil)
    }
    
    func showMembers(sender: AnyObject) {
        let selectionVC = UserListViewController(group: Engagement.current())
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(selectionVC, animated: true)
        self.hidesBottomBarWhenPushed = false
    }
    
    func showEvents(sender: AnyObject) {
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(CalendarViewController(), animated: true)
        self.hidesBottomBarWhenPushed = false
    }
    
    func createTeam(sender: UIButton) {
        let navVC = UINavigationController(rootViewController: CreateGroupViewController(asTeam: true))
        self.present(navVC, animated: true, completion: nil)
    }
    
    func groupOptions(sender: UIButton) {
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = Color.defaultNavbarTint
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheetController.addAction(cancelAction)
        
        if let admins = self.engagement.admins {
            if admins.contains(User.current().id) {
                let adminFunction: UIAlertAction = UIAlertAction(title: "Admin Functions", style: .default)
                { action -> Void in
                    
                }
                actionSheetController.addAction(adminFunction)
            }
        }
        
        guard let members = self.engagement.members else {
            return
        }
        if members.contains(User.current().id) {
            let leaveAction: UIAlertAction = UIAlertAction(title: "Leave Engagement", style: .default)
            { action -> Void in
                self.engagement.leave(user: User.current(), completion: { (success) in
                    if success {
                        let toast = Toast(text: "Successfully left \(self.engagement.name!)", button: nil, color: Color.darkGray, height: 44)
                        toast.show(duration: 1.5)
                        
                        self.engagement.didResign()
                    }
                })
            }
            actionSheetController.addAction(leaveAction)
        } else {
            let joinTeam: UIAlertAction = UIAlertAction(title: "Join Engagement", style: .default)
            { action -> Void in
                self.engagement.join(user: User.current(), completion: { (success) in
                    if success {
                        self.reloadData()
                        let toast = Toast(text: "Successfully joined \(self.engagement.name!)", button: nil, color: Color.darkGray, height: 44)
                        toast.show(duration: 1.5)
                    }
                })
            }
            actionSheetController.addAction(joinTeam)
        }
        
        actionSheetController.popoverPresentationController?.sourceView = self.view
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func viewProfilePhoto() {
        guard let image = self.engagement.image else {
            return
        }
        let agrume = Agrume(image: image)
        agrume.showFrom(self)
    }
    
    func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: NTTableViewDataSource
    
    func tableView(_ tableView: NTTableView, cellForHeaderInSection section: Int) -> NTHeaderCell? {
        if section == 0 {
            return NTHeaderCell()
        } else if section == 2 {
            let header = NTHeaderCell.initFromNib()
            header.titleLabel.text = "Teams"
            header.actionButton.setTitle("New Team", for: .normal)
            header.actionButton.addTarget(self, action: #selector(createTeam(sender:)), for: .touchUpInside)
            return header
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: NTTableView, cellForFooterInSection section: Int) -> NTFooterCell? {
        return NTFooterCell()
    }
    
    func numberOfSections(in tableView: NTTableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 8
        } else if section == 2{
            return self.engagement.teams.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if indexPath.section == 0 {
            // Page Header
            let cell = NTPageHeaderCell.initFromNib()
            cell.setDefaults()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewProfilePhoto))
            cell.imageView.addGestureRecognizer(tapGesture)
            cell.image = self.engagement.image
            cell.name = self.engagement.name
            if self.engagement.admins!.contains(User.current().id) {
                cell.rightButton.setImage(Icon.Apple.editFilled, for: .normal)
                cell.rightButton.addTarget(self, action: #selector(editEngagement(sender:)), for: .touchUpInside)
            }
            return cell
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                let cell = NTDynamicHeightTextCell.initFromNib()
                cell.horizontalInset = 10
                cell.verticalInset = -5
                cell.cornersRounded = [.topLeft, .topRight]
                cell.cornerRadius = 5
                cell.contentLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
                cell.contentLabel.textColor = Color.defaultNavbarTint
                cell.text = "Info"
                return cell
            case 1:
                let cell = NTDynamicHeightTextCell.initFromNib()
                cell.verticalInset = -5
                cell.horizontalInset = 10
                cell.contentLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightRegular)
                cell.text = self.engagement.info
                return cell
            case 2:
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.title = "Website"
                cell.text = self.engagement.url
                return cell
            case 3:
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.title = "Address"
                cell.text = self.engagement.address
                return cell
            case 4:
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.title = "Phone"
                cell.text = self.engagement.phone
                return cell
            case 5:
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.title = "Email"
                cell.text = self.engagement.email
                return cell
            case 6:
                let cell = NTMenuItemCell.initFromNib()
                cell.horizontalInset = 10
                cell.title = "Event Calendar"
                cell.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
                cell.titleLabel.textColor = Color.defaultNavbarTint
                cell.accessoryButton.setImage(Icon.Apple.arrowForward, for: .normal)
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showEvents(sender:)))
                cell.addGestureRecognizer(tapGesture)
                cell.accessoryButton.addTarget(self, action: #selector(showEvents(sender:)), for: .touchUpInside)
                return cell
            case 7:
                let cell = NTMenuItemCell.initFromNib()
                cell.horizontalInset = 10
                cell.cornersRounded = [.bottomLeft, .bottomRight]
                cell.cornerRadius = 5
                cell.title = "\(self.engagement.members!.count) Members"
                cell.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
                cell.titleLabel.textColor = Color.defaultNavbarTint
                cell.accessoryButton.setImage(Icon.Apple.arrowForward, for: .normal)
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showMembers(sender:)))
                cell.addGestureRecognizer(tapGesture)
                cell.accessoryButton.addTarget(self, action: #selector(showMembers(sender:)), for: .touchUpInside)
                return cell
            default:
                return NTTextViewCell()
            }
            
        } else if indexPath.section == 2 {
            let cell = NTMenuItemCell.initFromNib()
            cell.horizontalInset = 10
            if indexPath.row == 0 {
                cell.cornersRounded = [.topLeft, .topRight]
                if indexPath.row == (self.engagement.teams.count - 1) {
                    cell.cornersRounded = .allCorners
                }
            } else if indexPath.row == (self.engagement.teams.count - 1) {
                cell.cornersRounded = [.bottomLeft, .bottomRight]
            }
            cell.cornerRadius = 5
            cell.title = self.engagement.teams[indexPath.row].name
            cell.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
            cell.titleLabel.textColor = Color.defaultNavbarTint
            cell.accessoryButton.setImage(Icon.Apple.arrowForward, for: .normal)
            return cell
        } else {
            return NTTextViewCell()
        }
    }
    
    func imageForStretchyView(in tableView: NTTableView) -> UIImage? {
        guard let image = self.engagement.coverImage else {
            return nil
        }
        self.tableView.refreshControl?.tintColor = UIColor.white
        self.tableView.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to Refresh", attributes: [NSForegroundColorAttributeName : UIColor.white])
        return image
    }
    
    // MARK: NTTableViewDelegate
    
    func tableView(_ tableView: NTTableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            let team = self.engagement.teams[indexPath.row]
            let teamVC = TeamViewController(team: team)
            self.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(teamVC, animated: true)
            self.hidesBottomBarWhenPushed = false
        }
    }
}

