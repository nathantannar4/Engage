//
//  Feed.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-19.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

final class Post {
    
    static var new = Post()
    static var post = Post()
    
    var image: UIImage?
    var info: String?
    var user: PFUser?
    var replies: Int?
    var createdAt: NSDate?
    var comments: [String]?
    var commentsDate: [NSDate]?
    var commentsUsers: [PFUser]?
    var hasImage: Bool?
    var toObject: PFObject?
    
    func clear() {
        Post.new.info = ""
        Post.new.comments?.removeAll()
        Post.new.commentsDate?.removeAll()
        Post.new.commentsUsers?.removeAll()
        Post.new.replies = 0
        Post.new.hasImage = false
        Post.new.user = nil
        Post.new.image = nil
        Post.new.toObject = nil
    }
    
    func createPost(object: PFObject?, completion: @escaping () -> Void) {
        if Post.new.info != "" {
            SVProgressHUD.show(withStatus: "Posting")
            let newPost = PFObject(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Posts")
            newPost[PF_POST_INFO] = Post.new.info
            newPost[PF_POST_COMMENTS] = []
            newPost[PF_POST_COMMENT_DATES] = []
            newPost[PF_POST_COMMENT_USERS] = []
            newPost[PF_POST_REPLIES] = 0
            newPost[PF_POST_USER] = PFUser.current()
            if object != nil {
                if let _ = object as? PFUser {
                    newPost[PF_POST_TO_USER] = object
                } else {
                    newPost[PF_POST_TO_OBJECT] = object
                }
            }
            
            if Post.new.hasImage == true {
                
                if Post.new.image!.size.width > 300 {
                    
                    let resizeFactor = 300 / Post.new.image!.size.width
                    
                    Post.new.image = Images.resizeImage(image: Post.new.image!, width: resizeFactor * Post.new.image!.size.width, height: resizeFactor * Post.new.image!.size.height)!
                }
                
                let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(Post.new.image!, 0.6)!)
                pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                    if error == nil {
                        newPost[PF_POST_HAS_IMAGE] = true
                        newPost[PF_POST_IMAGE] = pictureFile
                        newPost.saveInBackground(block: { (success: Bool, error: Error?) in
                            completion()
                            if error == nil {
                                Post.new.clear()
                                SVProgressHUD.showSuccess(withStatus: "Posted!")
                            } else {
                                SVProgressHUD.showError(withStatus: "Network Error")
                            }
                        })
                    }
                }
            } else {
                newPost[PF_POST_HAS_IMAGE] = false
                newPost.saveInBackground(block: { (success: Bool, error: Error?) in
                    completion()
                    if error == nil {
                        Post.new.clear()
                        SVProgressHUD.showSuccess(withStatus: "Posted!")
                    } else {
                        SVProgressHUD.showError(withStatus: "Network Error")
                    }
                })
            }
            
            
        }
    }
}
