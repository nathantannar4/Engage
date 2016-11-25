//
//  RightAnnouncementsViewController.swift
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

class AnnouncementsViewController: UITableViewController {
    
    internal var querySkip = 0
    internal var announcements = [PFObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        tableView.separatorStyle = .none
        tableView.contentInset.top = 10
        tableView.backgroundColor = MAIN_COLOR
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.white
        refreshControl?.addTarget(self, action: #selector(AnnouncementsViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(self.refreshControl!)
        loadAnnouncements()
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        querySkip = 0
        loadAnnouncements()
        refreshControl.endRefreshing()
    }
    
    private func loadAnnouncements() {
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Announcements")
        query.limit = 20
        query.skip = self.querySkip
        query.order(byDescending: "createdAt")
        //query.includeKey(PF_POST_USER)
        query.findObjectsInBackground { (loadedPosts: [PFObject]?, error: Error?) in
            if error == nil {
                if self.querySkip == 0 {
                    self.announcements.removeAll()
                }
                if loadedPosts != nil && (loadedPosts?.count)! > 0 {
                    for post in loadedPosts! {
                        self.announcements.append(post)
                    }
                    if loadedPosts!.count != 20 {
                        self.querySkip -= (20 - loadedPosts!.count)
                    }
                    self.tableView.reloadData()
                }
            } else {
                print(error.debugDescription)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 50
        } else {
            let content = self.announcements[indexPath.row - 1].value(forKey: PF_POST_INFO) as! String
            let contentCount = content.characters.count
            var height: CGFloat = 100
            var count = 29
            while count < contentCount {
                height += 19
                count += 29
            }
            return height
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.announcements.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let header = UITableViewCell()
            header.textLabel?.text = "Announcements"
            header.textLabel?.textColor = UIColor.white
            header.textLabel?.font = RobotoFont.bold(with: 20.0)
            header.textLabel?.textAlignment = .right
            header.backgroundColor = MAIN_COLOR
            header.selectionStyle = .none
            return header
        } else {
            let cell = UITableViewCell()
            let card = Card()
            
            // Content
            //***********
            let contentView = UILabel()
            contentView.numberOfLines = 0
            contentView.text = self.announcements[indexPath.row - 1].value(forKey: PF_POST_INFO) as? String
            contentView.font = RobotoFont.regular(with: 15)
            
            // Bottom Bar
            //***********
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateLabel = UILabel()
            dateLabel.font = RobotoFont.regular(with: 13)
            dateLabel.textColor = Color.gray
            dateLabel.text = dateFormatter.string(from: self.announcements[indexPath.row - 1].createdAt!)
            dateLabel.textAlignment = .right
            
            
            // Bottom Bar
            let bottomBar = Bar()
            bottomBar.rightViews = [dateLabel]
            
            // Configure Card
            card.contentView = contentView
            card.contentViewEdgeInsetsPreset = .wideRectangle2
            card.bottomBar = bottomBar
            card.bottomBarEdgeInsetsPreset = .wideRectangle2
            
            /* Configure Cell
            if UIDevice.current.modelName == "iPhone 6 Plus" || UIDevice.current.modelName == "iPhone 6s Plus" || UIDevice.current.modelName == "iPhone 7 Plus" {
                // 5.5 Inch Screen
                cell.contentView.layout(card).horizontally(left: 10, right: 140).center()
            } else if UIDevice.current.modelName == "iPhone 6" || UIDevice.current.modelName == "iPhone 6s" || UIDevice.current.modelName == "iPhone 7" || UIDevice.current.modelName == "i386" || UIDevice.current.modelName == "x86_64" {
                // 4.7 Inch Screen & Simulator
                cell.contentView.layout(card).horizontally(left: 10, right: 100).center()
            } else {
                // 4 Inch Screen & Simulator
                cell.contentView.layout(card).horizontally(left: 10, right: 47).center()
            } */
            cell.contentView.layout(card).horizontally(left: 10, right: 10).center()
            cell.selectionStyle = .none
            cell.backgroundColor = MAIN_COLOR
            
            return cell
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        if(y > h) {
            if self.announcements.count >= (20 + querySkip) {
                print("load more rows")
                querySkip += 20
                loadAnnouncements()
            }
        }
    }
}

