//
//  DemoTableViewController.swift
//  NTUIKit Demo
//
//  Created by Nathan Tannar on 12/28/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit

class ProfileViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate {
    
    var user: User!
    
    // MARK: - Initializers
    public convenience init(user: User) {
        self.init()
        self.user = user
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        self.tableView.contentInset.top = 200
        self.tableView.contentInset.bottom = 100
        self.tableView.emptyHeaderHeight = 10
        self.fadeInNavBarOnScroll = true
    }
    
    // MARK: User Action
    
    func newPost() {
        
    }
    
    func editProfile() {
        
    }
    
    // MARK: NTTableViewDataSource
    
    func tableView(_ tableView: NTTableView, cellForHeaderInSection section: Int) -> NTHeaderCell? {
        if section == 2 {
            let header = NTHeaderCell.initFromNib()
            header.titleLabel.text = "Recent Posts"
            if self.user.id == User.current().id {
                header.actionButton.setTitle("New Post", for: .normal)
                header.actionButton.addTarget(self, action: #selector(newPost), for: .touchUpInside)
            }
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
        if section >= 2 {
            return 4
        } else if section == 1 {
            return 3
        }
        return 1
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if indexPath.section == 0 {
            let cell = NTProfileHeaderCell.initFromNib()
            cell.setDefaults()
            cell.image = self.user.image
            cell.name = self.user.fullname
            cell.title = ""
            cell.subtitle = ""
            if self.user.id == User.current().id {
                cell.rightButton.setImage(Icon.Apple.editFilled?.resizeImage(width: 25, height: 25, renderingMode: .alwaysTemplate), for: .normal)
                cell.rightButton.addTarget(self, action: #selector(editProfile), for: .touchUpInside)
            }
            return cell
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = NTInfoLinkCell.initFromNib()
                cell.setDefaults()
                cell.leftTitle = "9 Repositories"
                cell.leftSubtitle = "Github"
                cell.rightTitle = "76,204"
                cell.rightSubtitle = "Lines of Code"
                return cell
            }
        }
        return NTTableViewCell()
    }
    
    func imageForStretchyView(in tableView: NTTableView) -> UIImage? {
        return #imageLiteral(resourceName: "header")
    }
    
}
