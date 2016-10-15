//
//  TableFunctions.swift
//  Engage
//
//  Created by Nathan Tannar on 10/7/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import Foundation
import UIKit
import Former
import Agrume
import Parse
import SVProgressHUD

class TableFunctions {
    
    class func createMenu(text: String, onSelected: (() -> Void)?) -> RowFormer {
        return LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 16)
            $0.accessoryType = .disclosureIndicator
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
    }
    
    class func createHeader(text: String) -> ViewFormer {
        return LabelViewFormer<FormLabelHeaderView>()
            .configure {
                $0.viewHeight = 40
                $0.text = text
        }
    }
    
    class func createFooter(text: String) -> ViewFormer {
        return LabelViewFormer<FormLabelFooterView>()
            .configure {
                $0.text = text
                $0.viewHeight = 40
        }
    }
    
    class func createFeedCellPhoto(user: PFUser, post: PFObject, nav: UINavigationController) -> RowFormer {
        return CustomRowFormer<FeedCellPhoto>(instantiateType: .Nib(nibName: "FeedCellPhoto")) {
            if post[PF_POST_TO_OBJECT] != nil {
                $0.username.text = "\(user.value(forKey: PF_USER_FULLNAME) as! String) >> \(nav.title!)"
            } else {
                $0.username.text = user.value(forKey: PF_USER_FULLNAME) as? String
            }
            $0.info.text = post[PF_POST_INFO] as? String
            $0.date.text = Utilities.dateToString(time: post.createdAt! as NSDate)
            if post[PF_POST_REPLIES] as! Int == 1 {
                $0.replies.text = "1 Reply"
            } else {
                $0.replies.text = "\(post[PF_POST_REPLIES] as! Int) Replies"
            }
            $0.postPhoto.file = post[PF_POST_IMAGE] as? PFFile
            $0.postPhoto.loadInBackground()
            $0.userPhoto.image = UIImage(named: "profile_blank")
            $0.userPhoto.file = user[PF_USER_PICTURE] as? PFFile
            $0.userPhoto.loadInBackground()
            $0.userPhoto.layer.borderWidth = 1
            $0.userPhoto.layer.masksToBounds = true
            $0.userPhoto.layer.borderColor = MAIN_COLOR?.cgColor
            $0.userPhoto.layer.cornerRadius = $0.userPhoto.frame.height/2
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected {_ in
                let detailVC = PostDetailViewController()
                detailVC.post = post
                detailVC.postUser = post[PF_POST_USER] as? PFUser
                nav.pushViewController(detailVC, animated: true)
        }
    }
    
    class func createFeedCell(user: PFUser, post: PFObject, nav: UINavigationController) -> RowFormer {
        return CustomRowFormer<FeedCell>(instantiateType: .Nib(nibName: "FeedCell")) {
            if post[PF_POST_TO_USER] != nil {
                $0.username.text = "\(user.value(forKey: PF_USER_FULLNAME) as! String) >> \((post[PF_POST_TO_USER] as! PFUser).value(forKey: PF_USER_FULLNAME) as! String)"
            } else if post[PF_POST_TO_OBJECT] != nil {
                $0.username.text = "\(user.value(forKey: PF_USER_FULLNAME) as! String) >> \((post[PF_POST_TO_OBJECT] as! PFObject).value(forKey: PF_SUBGROUP_NAME) as! String)"
            } else {
                $0.username.text = user.value(forKey: PF_USER_FULLNAME) as? String
            }
            $0.info.text = post[PF_POST_INFO] as? String
            $0.date.text = Utilities.dateToString(time: post.createdAt! as NSDate)
            if post[PF_POST_REPLIES] as! Int == 1 {
                $0.replies.text = "1 Reply"
            } else {
                $0.replies.text = "\(post[PF_POST_REPLIES] as! Int) Replies"
            }
            $0.userPhoto.image = UIImage(named: "profile_blank")
            $0.userPhoto.file = user[PF_USER_PICTURE] as? PFFile
            $0.userPhoto.loadInBackground()
            $0.userPhoto.layer.borderWidth = 1
            $0.userPhoto.layer.masksToBounds = true
            $0.userPhoto.layer.borderColor = MAIN_COLOR?.cgColor
            $0.userPhoto.layer.cornerRadius = $0.userPhoto.frame.height/2
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected {_ in
                let detailVC = PostDetailViewController()
                detailVC.post = post
                detailVC.postUser = post[PF_POST_USER] as? PFUser
                nav.pushViewController(detailVC, animated: true)
        }
    }

}
