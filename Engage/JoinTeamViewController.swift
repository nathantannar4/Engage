//
//  JoinTeamViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2/4/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Agrume
import Parse

class JoinTeamViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate {
    
    private var engagement: Engagement!
    
    // MARK: - Initializers
    public convenience init(engagement: Engagement) {
        self.init()
        self.engagement = engagement
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Join a Team"
        self.subtitle = "You can only be apart of one team"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createTeam(sender:)))
        self.dataSource = self
        self.delegate = self
        self.prepareTableView()
    }
    
    func pullToRefresh(sender: UIRefreshControl) {
        self.tableView.refreshControl?.beginRefreshing()
        self.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    // MARK: Preperation Functions
    
    private func prepareTableView() {
        self.tableView.contentInset.bottom = 100
        self.tableView.emptyHeaderHeight = 10
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    // MARK: User Action
    
    func createTeam(sender: UIButton) {
        
    }
    
    func joinTeam(sender: AnyObject) {
        
    }
    
    // MARK: NTTableViewDataSource
    
    func tableView(_ tableView: NTTableView, cellForHeaderInSection section: Int) -> NTHeaderCell? {
        let header = NTHeaderCell.initFromNib()
        header.titleLabel.text = self.engagement.teams[section].name
        return header
    }
    
    func numberOfSections(in tableView: NTTableView) -> Int {
        return self.engagement.teams.count
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if indexPath.row == 0 {
            let cell = NTImageCell.initFromNib()
            cell.cornersRounded = [.topLeft, .topRight]
            cell.cornerRadius = 5
            cell.horizontalInset = 10
            cell.contentImageView.layer.borderWidth = 2
            cell.contentImageView.layer.borderColor = UIColor.white.cgColor
            cell.contentImageView.layer.cornerRadius = 5
            cell.image = self.engagement.teams[indexPath.section].coverImage
            
            if cell.image == nil {
                cell.contentImageView.removeFromSuperview()
                cell.bounds = CGRect.zero
            }
            return cell
        } else if indexPath.row == 1 {
            let cell = NTMenuItemCell.initFromNib()
            cell.horizontalInset = 10
            cell.cornerRadius = 5
            if self.engagement.teams[indexPath.section].coverImage == nil {
                cell.cornersRounded = .allCorners
            } else {
                cell.cornersRounded = [.bottomLeft, .bottomRight]
            }
            cell.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
            cell.title = "Join Team"
            cell.titleLabel.textColor = Color.defaultNavbarTint
            cell.accessoryButton.setImage(Icon.Apple.arrowForward, for: .normal)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(joinTeam(sender:)))
            cell.addGestureRecognizer(tapGesture)
            cell.accessoryButton.addTarget(self, action: #selector(joinTeam(sender:)), for: .touchUpInside)
            return cell
        } else {
            return NTTextViewCell()
        }
    }
    
    // MARK: NTTableViewDelegate
    
    func tableView(_ tableView: NTTableView, didSelectRowAt indexPath: IndexPath) {
        let team = self.engagement.teams[indexPath.section]
        let teamVC = TeamViewController(team: team)
        self.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(teamVC, animated: true)
        self.hidesBottomBarWhenPushed = false
    }
}


