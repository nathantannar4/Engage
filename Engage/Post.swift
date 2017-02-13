//
//  Post.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Foundation
import Parse
import Photos
import NTUIKit

public protocol PostModificationDelegate {
    func didUpdatePost()
    func didDeletePost()
}

public class Post {
    
    public var object: PFObject
    public var id: String {
        get {
            guard let id = self.object.objectId else {
                Log.write(.error, "User ID was nil")
                fatalError()
            }
            return id
        }
    }
    public var user: User? {
        get {
            guard let user = object.object(forKey: PF_MESSAGE_USER) as? PFUser else {
                return nil
            }
            return Cache.retrieveUser(user)
        }
        set {
            self.object[PF_POST_USER] = newValue?.object
        }
    }
    public var content: String? {
        get {
            return self.object.value(forKey: PF_POST_INFO) as? String
        }
        set {
            self.object[PF_POST_INFO] = newValue
        }
    }
    public var image: UIImage?
    public var createdAt: Date? {
        get {
            return self.object.createdAt
        }
    }
    public var updatedAt: Date? {
        get {
            return self.object.updatedAt
        }
    }
    public var likes: [String]? {
        get {
            return self.object.value(forKey: PF_POST_LIKES) as? [String]
        }
    }
    public var comments = [Comment]()
    
    // MARK: Initialization
    
    public init(fromObject object: PFObject) {
        self.object = object
        
        if let objectUser = object.object(forKey: PF_POST_USER) as? PFUser {
            let _ = Cache.retrieveUser(objectUser)
        }
        
        guard let file = self.object.value(forKey: PF_POST_IMAGE) as? PFFile else {
            return
        }
        file.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.image = UIImage(data: imageData)
        }
        
        guard let comments = object.value(forKey: PF_POST_COMMENTS) as? [String] else {
            return
        }
        guard let commentUsers = object.value(forKey: PF_POST_COMMENT_USERS) as? [PFUser] else {
            return
        }
        guard let commentDates = object.value(forKey: PF_POST_COMMENT_DATES) as? [Date] else {
            return
        }
        for user in commentUsers {
            user.fetchInBackground(block: { (object, error) in
                guard let user = object as? PFUser else {
                    Log.write(.error, "Could not fetch the user of the comment")
                    Log.write(.error, error.debugDescription)
                    return
                }
                self.comments.append(Comment(user: Cache.retrieveUser(user), text: comments[commentUsers.index(of: user)!], date: commentDates[commentUsers.index(of: user)!]))
            })
        }
    }
    
    public init(text: String?, image: UIImage?) {
        self.object = PFObject(className: Engagement.current().queryName! + PF_POST_CLASSNAME)
        self.user = User.current()
        self.object[PF_POST_INFO] = text ?? ""
        self.object[PF_POST_COMMENTS] = []
        self.object[PF_POST_COMMENT_DATES] = []
        self.object[PF_POST_COMMENT_USERS] = []
        self.object[PF_POST_LIKES] = []
        self.object[PF_POST_USER] = PFUser.current()
        self.image = image
    }
    
    // MARK: Private Functions
    
    @objc private func undoDeletion() {
        self.save { (success) in
            if success {
                let toast = Toast(text: "Post Restored", button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 1.0)
            }
        }
    }
    
    // MARK: Public Functions
    
    public func save(completion: ((_ success: Bool) -> Void)?) {
        self.object.saveInBackground { (success, error) in
            completion?(success)
            if error != nil {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: error?.localizedDescription, button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 1.0)
            } else {
                Cache.update(self)
            }
        }
    }
    
    public func upload(completion: ((_ success: Bool) -> Void)?) {
        // Freeze user interaction
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        if self.image != nil {
            var imageToPost = image!
            if image!.size.width > 500 {
                let resizeFactor = 500 / image!.size.width
                imageToPost = image!.resizeImage(width: resizeFactor * image!.size.width, height: resizeFactor * image!.size.height, renderingMode: .alwaysOriginal)
            }
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(imageToPost, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error == nil {
                    self.object[PF_POST_IMAGE] = pictureFile
                    self.save { (success) in
                        // Unfreeze user interaction
                        UIApplication.shared.endIgnoringInteractionEvents()
                        
                        completion?(success)
                        if success {
                            Log.write(.status, "Post \(self.id) uploaded to databased successfully")
                            let toast = Toast(text: "Post Uploaded", button: nil, color: Color.darkGray, height: 44)
                            toast.dismissOnTap = true
                            toast.show(duration: 1.0)
                        } else {
                            let toast = Toast(text: error?.localizedDescription, button: nil, color: Color.darkGray, height: 44)
                            toast.dismissOnTap = true
                            toast.show(duration: 1.0)
                        }
                    }
                } else {
                    // Unfreeze user interaction
                    UIApplication.shared.endIgnoringInteractionEvents()
                    let toast = Toast(text: error?.localizedDescription, button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.0)
                }
            }
        } else {
            self.save { (success) in
                // Unfreeze user interaction
                UIApplication.shared.endIgnoringInteractionEvents()
                
                completion?(success)
                if success {
                    Log.write(.status, "Post \(self.id) uploaded to databased successfully")
                    let toast = Toast(text: "Post Uploaded", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.0)
                }
            }
        }
    }
    
    public func addComment(_ comment: Comment, completion: ((_ success: Bool) -> Void)?) {
        guard var comments = object.value(forKey: PF_POST_COMMENTS) as? [String] else {
            completion?(false)
            Toast.genericErrorMessage()
            return
        }
        guard var commentUsers = object.value(forKey: PF_POST_COMMENT_USERS) as? [PFUser] else {
            completion?(false)
            Toast.genericErrorMessage()
            return
        }
        guard var commentDates = object.value(forKey: PF_POST_COMMENT_DATES) as? [Date] else {
            completion?(false)
            Toast.genericErrorMessage()
            return
        }
        comments.append(comment.text)
        self.object[PF_POST_COMMENTS] = comments
        commentUsers.append(comment.user.object)
        self.object[PF_POST_COMMENT_USERS] = commentUsers
        commentDates.append(comment.date)
        self.object[PF_POST_COMMENT_DATES] = commentDates
        self.comments.append(comment)
        self.save { (success) in
            if success {
                completion?(true)
            }
        }
    }

    public func liked(byUser user: User, completion: ((_ success: Bool) -> Void)?) {
        guard var currentLikes = self.likes else {
            self.object[PF_POST_LIKES] = [user.id]
            self.save(completion: { (success) in
                completion?(success)
                if success {
                    Log.write(.status, "User \(user.id) liked the post \(self.id)")
                }
            })
            return
        }
        if !currentLikes.contains(user.id) {
            currentLikes.append(user.id)
            self.object[PF_POST_LIKES] = currentLikes
            self.save(completion: { (success) in
                completion?(success)
                if success {
                    Log.write(.status, "User \(user.id) liked the post \(self.id)")
                }
            })
        }
    }
    
    public func unliked(byUser user: User, completion: ((_ success: Bool) -> Void)?) {
        guard var currentLikes = self.likes else {
            Log.write(.warning, "An unlike action was made on post \(self.id) by user \(user.id) but the posts likes array was nil")
            completion?(false)
            return
        }
        if currentLikes.contains(user.id) {
            let index = currentLikes.index(of: user.id)!
            currentLikes.remove(at: index)
            self.object[PF_POST_LIKES] = currentLikes
            self.save(completion: { (success) in
                completion?(success)
                if success {
                    Log.write(.status, "User \(user.id) unliked the post \(self.id)")
                }
            })
        } else {
            Log.write(.warning, "An unlike action was made on post \(self.id) by user \(user.id) but the user had not previously liked it")
            completion?(false)
        }
    }
    
    public func flag(fromUser user: User, reason: String, completion: ((_ success: Bool) -> Void)?) {
        
    }
    
    public func handleByOwner(target: UIViewController, delegate: PostModificationDelegate, sender: UIButton) {
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = Color.defaultButtonTint
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheetController.addAction(cancelAction)
        
        let editAction: UIAlertAction = UIAlertAction(title: "Edit", style: .default) { action -> Void in
            target.present(UINavigationController(rootViewController: EditPostViewController(post: self)), animated: true, completion: {
                delegate.didUpdatePost()
            })
        }
        actionSheetController.addAction(editAction)
        
        let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { action -> Void in
            let alert = UIAlertController(title: "Are you sure?", message: "This cannot be undone.", preferredStyle: UIAlertControllerStyle.alert)
            alert.view.tintColor = Color.defaultNavbarTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(cancelAction)
            
            let delete: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { action -> Void in
                self.object.deleteInBackground(block: { (success: Bool, error: Error?) in
                    if success {
                        let toast = Toast(text: "Post Deleted", button: nil, color: Color.darkGray, height: 44)
                        toast.show(target.view, duration: 2.0)
                        delegate.didDeletePost()
                    } else {
                        Toast.genericErrorMessage()
                    }
                })
            }
            alert.addAction(delete)
            target.present(alert, animated: true, completion: nil)
        }
        actionSheetController.addAction(deleteAction)
        
        actionSheetController.popoverPresentationController?.sourceView = sender
        actionSheetController.popoverPresentationController?.sourceRect = sender.bounds
        
        target.present(actionSheetController, animated: true, completion: nil)
    }
    
    public func handle(target: UIViewController, sender: UIButton) {
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = Color.defaultButtonTint
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheetController.addAction(cancelAction)
        
        if self.image != nil {
            let editAction: UIAlertAction = UIAlertAction(title: "Save Photo", style: .default) { action -> Void in
                PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAsset(from: self.image!)}, completionHandler: { success, error in
                    if success {
                        let toast = Toast(text: "Photo saved to camera roll", button: nil, color: Color.darkGray, height: 44)
                        toast.show(duration: 1.5)
                    } else {
                        let toast = Toast(text: "Could not save photo", button: nil, color: Color.darkGray, height: 44)
                        toast.show(duration: 1.5)
                    }
                })
            }
            actionSheetController.addAction(editAction)
        }
        
        let deleteAction: UIAlertAction = UIAlertAction(title: "Report", style: .default) { action -> Void in
            self.reportPost(target: target)
        }
        actionSheetController.addAction(deleteAction)
        
        actionSheetController.popoverPresentationController?.sourceView = sender
        actionSheetController.popoverPresentationController?.sourceRect = sender.bounds
        
        target.present(actionSheetController, animated: true, completion: nil)
    }
    
    private func reportPost(target: UIViewController) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Flag Post As", message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = Color.defaultNavbarTint
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheetController.addAction(cancelAction)
        
        let inappropriateAction: UIAlertAction = UIAlertAction(title: "Inappropriate Content", style: .default) { action -> Void in
            let flagObject = PFObject(className: Engagement.current().queryName! + PF_FLAGGED_POST_CLASSNAME)
            flagObject[PF_FLAGGED_POST_POST] = self.object
            flagObject[PF_FLAGGED_POST_REASON] = "Inappropriate Content"
            flagObject[PF_FLAGGED_POST_USER] = User.current().object
            flagObject.saveInBackground(block: { (success: Bool, error: Error?) in
                if error == nil {
                    let toast = Toast(text: "Post flagged", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.5)
                } else {
                    Toast.genericErrorMessage()
                }
            })
        }
        actionSheetController.addAction(inappropriateAction)
        
        let offensiveAction: UIAlertAction = UIAlertAction(title: "Offensive Content", style: .default) { action -> Void in
            let flagObject = PFObject(className: Engagement.current().queryName! + PF_FLAGGED_POST_CLASSNAME)
            flagObject[PF_FLAGGED_POST_POST] = self.object
            flagObject[PF_FLAGGED_POST_REASON] = "Offensive Content"
            flagObject[PF_FLAGGED_POST_USER] = User.current().object
            flagObject.saveInBackground(block: { (success: Bool, error: Error?) in
                if error == nil {
                    let toast = Toast(text: "Post flagged", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.5)
                } else {
                    Toast.genericErrorMessage()
                }
            })
        }
        actionSheetController.addAction(offensiveAction)
        
        let spamAction: UIAlertAction = UIAlertAction(title: "Spam", style: .default) { action -> Void in
            let flagObject = PFObject(className: Engagement.current().queryName! + PF_FLAGGED_POST_CLASSNAME)
            flagObject[PF_FLAGGED_POST_POST] = self.object
            flagObject[PF_FLAGGED_POST_REASON] = "Spam"
            flagObject[PF_FLAGGED_POST_USER] = User.current().object
            flagObject.saveInBackground(block: { (success: Bool, error: Error?) in
                if error == nil {
                    let toast = Toast(text: "Post flagged", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.5)
                } else {
                    Toast.genericErrorMessage()
                }
            })
        }
        actionSheetController.addAction(spamAction)
        actionSheetController.popoverPresentationController?.sourceView = target.view
        
        target.present(actionSheetController, animated: true, completion: nil)
    }
}
