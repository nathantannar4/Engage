//
//  DemoTableViewController.swift
//  NTUIKit Demo
//
//  Created by Nathan Tannar on 12/28/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit

class DemoProfileViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Nathan Tannar"
        self.subtitle = "iOS Developer"
        self.dataSource = self
        self.delegate = self
        self.tableView.contentInset.top = 200
        self.tableView.contentInset.bottom = 100
        self.tableView.emptyHeaderHeight = 10
        self.fadeInNavBarOnScroll = true
    }
    
    // MARK: NTTableViewDataSource
    
    func tableView(_ tableView: NTTableView, cellForHeaderInSection section: Int) -> NTHeaderCell? {
        if section == 2 {
            let header = NTHeaderCell.initFromNib()
            header.titleLabel.text = "Recent Posts"
            header.actionButton.setTitle("New Post", for: .normal)
            return header
        } else { return nil }

    }
    
    func tableView(_ tableView: NTTableView, cellForFooterInSection section: Int) -> NTFooterCell? {
        if section == 5 {
            let footer = NTFooterCell.initFromNib()
            footer.titleLabel.text = "Profile View Demo"
            return footer
        } else { return NTFooterCell() }
    }
    
    func numberOfSections(in tableView: NTTableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        if section >= 2 {
            return 4
        }
        return 1
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if indexPath.section == 0 {
            let cell = NTProfileHeaderCell.initFromNib()
            cell.setDefaults()
            cell.image = Icon.facebook
            cell.name = "Nathan Tannar"
            cell.title = "iOS Developer"
            cell.subtitle = "SFU Computer Science"
            cell.rightButton.setImage(Icon.Apple.editFilled?.resizeImage(width: 25, height: 25, renderingMode: .alwaysTemplate), for: .normal)
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
        if indexPath.section >= 2 {
            if indexPath.row == 0 {
                let cell = NTDetailedProfileCell.initFromNib()
                cell.setDefaults()
                cell.setImageViewDefaults()
                cell.cornersRounded = [.topLeft, .topRight]
                cell.title = "Nathan Tannar"
                cell.subtitle = "iOS Developer"
                cell.image =  Icon.facebook
                cell.accessoryButton.setImage(Icon.Apple.moreVerticalFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
                return cell
            } else if indexPath.row == 1 {
                let cell = NTImageCell.initFromNib()
                cell.horizontalInset = 10
                cell.image =  Icon.facebook
                return cell
            } else if indexPath.row == 2 {
                let cell = NTDynamicHeightTextCell.initFromNib()
                cell.horizontalInset = 10
                cell.text = "I became particularly interested in mobile and web development as it joined to unique aspects: designing UI/UX and programming the functionality to complement it. This is because I enjoy someone picking up something I've made in amazement. Now I am starting to learn more about servers, databases and security in a never ending persuit of my imagination."
                
                return cell
            } else {
                let cell = NTActionCell.initFromNib()
                cell.setDefaults()
                cell.cornersRounded = [.bottomLeft, .bottomRight]
                cell.leftButton.setImage(Icon.Apple.likeFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
                cell.leftButton.setTitle(" Like", for: .normal)
                cell.centerButton.setImage(Icon.Apple.commentFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
                cell.centerButton.setTitle(" 17 Comments", for: .normal)
                cell.rightButton.setTitle("January 1, 2016", for: .normal)
                cell.rightButton.setTitleColor(UIColor.black, for: .normal)
                cell.rightButton.isEnabled = false
                return cell
            }
        }
        return NTTableViewCell()
    }
    
    func imageForStretchyView(in tableView: NTTableView) -> UIImage? {
        return Icon.facebook
    }
    
}
