//
//  ActivityFeedViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import ParseUI
import Agrume
import DZNEmptyDataSet

class ActivityFeedViewController: NTTableViewController, NTTableViewDataSource, NTTableViewDelegate {
    
    private var posts: [Post] = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Activity Feed"
        self.dataSource = self
        self.delegate = self
        self.tableView.emptyHeaderHeight = 10
        self.tableView.emptyFooterHeight = 10
        self.tableView.contentInset.bottom = 100
        self.queryForPosts()
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
        return posts.count
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        switch indexPath.row {
        case 0:
            let cell = NTProfileCell.initFromNib()
            cell.setDefaults()
            cell.setImageViewDefaults()
            cell.cornersRounded = [.topLeft, .topRight]
            cell.title = self.posts[indexPath.section].user.fullname
            cell.image = self.posts[indexPath.section].user.image
            cell.accessoryButton.setImage(Icon.Apple.moreVerticalFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
            cell.accessoryButton.addTarget(self, action: #selector(handleMore(sender:)), for: .touchUpInside)
            return cell
        case 1:
            let cell = NTImageCell.initFromNib()
            cell.horizontalInset = 10
            cell.contentImageView.layer.borderWidth = 2
            cell.contentImageView.layer.borderColor = UIColor.white.cgColor
            cell.contentImageView.layer.cornerRadius = 5
            cell.image = self.posts[indexPath.section].image
            return cell
        case 2:
            let cell = NTDynamicHeightTextCell.initFromNib()
            cell.verticalInset = -5
            cell.horizontalInset = 10
            cell.text = self.posts[indexPath.section].content
            return cell
        case 3:
            let cell = NTActionCell.initFromNib()
            cell.setDefaults()
            cell.cornersRounded = [.bottomLeft, .bottomRight]
            cell.leftButton.setImage(Icon.Apple.likeFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
            let likes = self.posts[indexPath.section].likes
            let likeCount = likes?.count ?? 0
            cell.leftButton.setTitle(" \(likeCount)", for: .normal)
            cell.leftButton.tag = indexPath.section
            cell.leftButton.addTarget(self, action: #selector(toggleLike(sender:)), for: .touchUpInside)
            cell.centerButton.setImage(Icon.Apple.commentFilled?.resizeImage(width: 20, height: 20, renderingMode: .alwaysTemplate), for: .normal)
            let comments = self.posts[indexPath.section].comments
            let commentsCount = comments?.count ?? 0
            cell.centerButton.setTitle(" \(commentsCount)", for: .normal)
            cell.centerButton.tag = indexPath.section
            let createdAt = self.posts[indexPath.section].createdAt
            cell.rightButton.setTitle(String.mediumDateNoTime(date: createdAt ?? Date()), for: .normal)
            cell.rightButton.setTitleColor(UIColor.black, for: .normal)
            cell.rightButton.isEnabled = false
            return cell
        default:
            return NTTableViewCell()
        }
    }
    
    // MARK: User Actions
    
    func toggleLike(sender: UIButton) {
        guard let likes = self.posts[sender.tag].likes else {
            return
        }
        if likes.contains(User.current().id) {
            sender.setTitle(" \(likes.count - 1)", for: .normal)
            self.posts[sender.tag].unliked(byUser: User.current()) { (success) in
                if !success {
                    // Reset if save failed
                    let likes = self.posts[sender.tag].likes
                    let likeCount = likes?.count ?? 0
                    sender.setTitle(" \(likeCount)", for: .normal)
                }
            }
        } else {
            sender.setTitle(" \(likes.count + 1)", for: .normal)
            self.posts[sender.tag].liked(byUser: User.current()) { (success) in
                if !success {
                    // Reset if save failed
                    let likes = self.posts[sender.tag].likes
                    let likeCount = likes?.count ?? 0
                    sender.setTitle(" \(likeCount)", for: .normal)
                }
            }
        }
    }
    
    func handleMore(sender: UIButton) {
        let post = self.posts[sender.tag]
        if post.user.id == User.current().id {
            let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = Color.defaultButtonTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            let editAction: UIAlertAction = UIAlertAction(title: "Edit", style: .default) { action -> Void in
                
            }
            actionSheetController.addAction(editAction)
            
            let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { action -> Void in
                
            }
            actionSheetController.addAction(deleteAction)
            
            actionSheetController.popoverPresentationController?.sourceView = sender
            actionSheetController.popoverPresentationController?.sourceRect = sender.bounds
            
            self.present(actionSheetController, animated: true, completion: nil)
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = Color.defaultButtonTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            if post.image != nil {
                let editAction: UIAlertAction = UIAlertAction(title: "Save Photo", style: .default) { action -> Void in
                    
                }
                actionSheetController.addAction(editAction)
            }
            
            let deleteAction: UIAlertAction = UIAlertAction(title: "Report", style: .default) { action -> Void in
                
            }
            actionSheetController.addAction(deleteAction)
            
            actionSheetController.popoverPresentationController?.sourceView = sender
            actionSheetController.popoverPresentationController?.sourceRect = sender.bounds
            
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
    
    
    // MARK: Data Connecter
    
    func queryForPosts() {
        let postQuery = PFQuery(className: "Test_Posts")
        postQuery.includeKey(PF_POST_USER)
        postQuery.addDescendingOrder(PF_POST_CREATED_AT)
        postQuery.findObjectsInBackground { (objects, error) in
            guard let posts = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            Log.write(.status, "Downloaded \(posts.count) posts")
            for post in posts {
                self.posts.append(Post(fromObject: post))
            }
            self.reloadData()
        }
    }
    
    
    // MARK: DZNEmptyDataSetSource
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Engage", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 44)])
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "Engage_Logo")
    }
}

