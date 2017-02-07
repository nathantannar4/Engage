//
//  TeamViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2/1/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Agrume
import Parse

class TeamViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate {
    
    private var team: Team!
    
    // MARK: - Initializers
    public convenience init(team: Team) {
        self.init()
        self.team = team
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.team.name
        self.dataSource = self
        self.delegate = self
        if self.getNTNavigationContainer == nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Google.close, style: .plain, target: self, action: #selector(dismiss(sender:)))
        }
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
        self.fadeInNavBarOnScroll = true
        let refreshControl = UIRefreshControl()
        if self.team.coverImage != nil {
            refreshControl.tintColor = UIColor.white
            refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh", attributes: [NSForegroundColorAttributeName : UIColor.white])
        } else {
            refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        }
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    // MARK: User Action
    
    func editTeam(sender: UIButton) {
        let navVC = UINavigationController(rootViewController: EditGroupViewController(group: self.team))
        self.present(navVC, animated: true, completion: nil)
    }
    
    func showMembers(sender: UIButton) {
        let selectionVC = UserListViewController(group: self.team)
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(selectionVC, animated: true)
        self.hidesBottomBarWhenPushed = false
    }
    
    func viewProfilePhoto() {
        guard let image = self.team.image else {
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
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: NTTableView, cellForFooterInSection section: Int) -> NTFooterCell? {
        return NTFooterCell()
    }
    
    func numberOfSections(in tableView: NTTableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 7
        } else {
            return self.team.admins?.count ?? 0
        }
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if indexPath.section == 0 {
            // Page Header
            let cell = NTPageHeaderCell.initFromNib()
            cell.setDefaults()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewProfilePhoto))
            cell.imageView.addGestureRecognizer(tapGesture)
            cell.image = self.team.image
            cell.name = self.team.name
            if self.team.admins!.contains(User.current().id) {
                cell.rightButton.setImage(Icon.Apple.editFilled, for: .normal)
                cell.rightButton.addTarget(self, action: #selector(editTeam(sender:)), for: .touchUpInside)
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
                cell.text = self.team.info
                return cell
            case 2:
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.title = "Website"
                cell.text = self.team.url
                return cell
            case 3:
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.title = "Address"
                cell.text = self.team.address
                return cell
            case 4:
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.title = "Phone"
                cell.text = self.team.phone
                return cell
            case 5:
                let cell = NTLabeledCell.initFromNib()
                cell.horizontalInset = 10
                cell.title = "Email"
                cell.text = self.team.email
                return cell
            case 6:
                let cell = NTMenuItemCell.initFromNib()
                cell.horizontalInset = 10
                cell.cornersRounded = [.bottomLeft, .bottomRight]
                cell.cornerRadius = 5
                cell.title = "\(self.team.members!.count) Members"
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
            
        } else {
            return NTTextViewCell()
        }
    }
    
    func imageForStretchyView(in tableView: NTTableView) -> UIImage? {
        guard let image = self.team.coverImage else {
            self.fadeInNavBarOnScroll = false
            return nil
        }
        self.fadeInNavBarOnScroll = true
        self.tableView.refreshControl?.tintColor = UIColor.white
        self.tableView.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to Refresh", attributes: [NSForegroundColorAttributeName : UIColor.white])
        return image
    }
}


