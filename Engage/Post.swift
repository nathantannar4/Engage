//
//  Post.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Foundation
import Parse
import NTUIKit

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
    public var user: User!
    public var content: String? {
        get {
            return self.object.value(forKey: PF_POST_INFO) as? String
        }
    }
    public var image: UIImage?
    public var createdAt: Date? {
        get {
            return self.object.createdAt
        }
    }
    public var likes: [String]? {
        get {
            return self.object.value(forKey: PF_POST_LIKES) as? [String]
        }
    }
    public var comments: [Comment]?
    
    // MARK: Initialization
    
    public init(fromObject object: PFObject) {
        self.object = object
        
        guard let objectUser = object.object(forKey: PF_POST_USER) as? PFUser else {
            Log.write(.error, "Object with ID \(object.objectId!) did not have a cooresponding user")
            return
        }
        self.user = Cache.retrieveUser(objectUser)
        
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
    }
    
    public init(text: String?, image: UIImage?, completion: ((_ success: Bool) -> Void)?) {
        guard let engagement = Engagement.current() else {
            fatalError()
        }
        self.user = User.current()
        self.object = PFObject(className: engagement.queryName! + PF_POST_CLASSNAME)
        self.object[PF_POST_INFO] = text ?? ""
        self.object[PF_POST_COMMENTS] = []
        self.object[PF_POST_COMMENT_DATES] = []
        self.object[PF_POST_COMMENT_USERS] = []
        self.object[PF_POST_LIKES] = []
        self.object[PF_POST_USER] = PFUser.current()
        if image != nil {
            var imageToPost = image!
            if image!.size.width > 500 {
                let resizeFactor = 500 / image!.size.width
                imageToPost = image!.resizeImage(width: resizeFactor * image!.size.height, height: resizeFactor * image!.size.height, renderingMode: .alwaysOriginal)
            }
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(imageToPost, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error == nil {
                    self.object[PF_POST_IMAGE] = pictureFile
                    self.save { (success) in
                        completion?(success)
                        if success {
                            Log.write(.status, "Post \(self.id) uploaded to databased successfully")
                            let toast = Toast(text: "Post uploaded!", button: nil, color: Color.darkGray, height: 44)
                            toast.dismissOnTap = true
                            toast.show(duration: 1.0)
                        } else {
                            Toast.genericErrorMessage()
                        }
                    }
                }
            }
        } else {
            self.save { (success) in
                completion?(success)
                if success {
                    Log.write(.status, "Post \(self.id) uploaded to databased successfully")
                    let toast = Toast(text: "Post uploaded!", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.0)
                } else {
                    Toast.genericErrorMessage()
                }
            }
        }
    }
    
    // MARK: Private Functions
    
    private func save(completion: ((_ success: Bool) -> Void)?) {
        self.object.saveInBackground { (success, error) in
            completion?(success)
            if error != nil {
                Log.write(.error, error.debugDescription)
                Toast.genericErrorMessage()
            }
        }
    }
    
    // MARK: Public Functions

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
    
    public func handleByOwner(target: UIViewController, sender: UIButton) {
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
        
        target.present(actionSheetController, animated: true, completion: nil)
    }
    
    public func handle(target: UIViewController, sender: UIButton) {
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = Color.defaultButtonTint
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        if self.image != nil {
            let editAction: UIAlertAction = UIAlertAction(title: "Save Photo", style: .default) { action -> Void in
                
            }
            actionSheetController.addAction(editAction)
        }
        
        let deleteAction: UIAlertAction = UIAlertAction(title: "Report", style: .default) { action -> Void in
            
        }
        actionSheetController.addAction(deleteAction)
        
        actionSheetController.popoverPresentationController?.sourceView = sender
        actionSheetController.popoverPresentationController?.sourceRect = sender.bounds
        
        target.present(actionSheetController, animated: true, completion: nil)
    }
}
