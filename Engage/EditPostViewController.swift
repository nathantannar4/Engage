//
//  EditPostViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/15/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import Former
import Agrume


class EditPostViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var image: UIImage?
    private var text: String?
    private var post: Post?
    
    // MARK: - Initializers
    public convenience init(post: Post) {
        self.init()
        self.post = post
        self.text = self.post?.content
        self.image = self.post?.image
    }
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setTitleView(title: self.post == nil ? "Create" : "Edit", subtitle: "Post", titleColor: Color.defaultTitle, subtitleColor: Color.defaultSubtitle)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.Google.check, style: .plain, target: self, action: #selector(saveButtonPressed(sender:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Google.close, style: .plain, target: self, action: #selector(cancelButtonPressed(sender:)))
        
        if Color.defaultNavbarBackground.isLight {
            UIApplication.shared.statusBarStyle = .default
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }
        self.tableView.contentInset.top = 10
        self.tableView.contentInset.bottom = 100
        
        self.configure()
    }
    
    // MARK: User Actions
    
    func saveButtonPressed(sender: UIBarButtonItem) {
        if self.post == nil {
            // New Post
            let post = Post(text: self.text, image: self.image)
            post.upload { (success) in
                if success {
                    Cache.add(post)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            // Edit Post
            self.post!.content = self.text
            
            guard var imageToPost = self.image else {
                self.post!.object[PF_POST_IMAGE] = NSNull()
                self.post!.image = nil
                self.post!.save(completion: { (success) in
                    if success {
                        self.dismiss(animated: true, completion: nil)
                    }
                })
                return
            }
            if imageToPost.size.width > 500 {
                let resizeFactor = 500 / image!.size.width
                imageToPost = imageToPost.resizeImage(width: resizeFactor * imageToPost.size.width, height: resizeFactor * imageToPost.size.height, renderingMode: .alwaysOriginal)
            }
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(imageToPost, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error == nil {
                    self.post!.object[PF_POST_IMAGE] = pictureFile
                    self.post!.image = imageToPost
                    self.post!.save(completion: { (success) in
                        if success {
                            self.dismiss(animated: true, completion: nil)
                        }
                    })
                } else {
                    // Unfreeze user interaction
                    UIApplication.shared.endIgnoringInteractionEvents()
                    Toast.genericErrorMessage()
                }
            }
        }
    }
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Former Rows
    
    let createMenu: ((String, (() -> Void)?) -> RowFormer) = { text, onSelected in
        return LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = Color.defaultNavbarTint
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
    }
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.image = self.image
            }.configure {
                $0.rowHeight = 200
            }
            .onSelected({ (cell: LabelRowFormer<ImageCell>) in
                if self.image != nil {
                    let agrume = Agrume(image: cell.cell.displayImage.image!)
                    agrume.showFrom(self)
                }
            })
    }()
    
    private lazy var imageOptionsRow: LabelRowFormer<FormLabelCell> = {
        LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = Color.defaultNavbarTint
            $0.titleLabel.font = .boldSystemFont(ofSize: 14)
            }.configure {
                $0.text = self.image == nil ? "Add image to post" : "Remove image from post"
                $0.rowHeight = 44
            }.onSelected { _ in
                self.former.deselect(animated: true)
                if self.image == nil {
                    self.presentImagePicker()
                } else {
                    self.image = nil
                    self.onlyImageRow.cellUpdate {
                        $0.displayImage.image = nil
                    }
                    self.former.removeUpdate(rowFormer: self.onlyImageRow, rowAnimation: .automatic)
                    self.imageOptionsRow.cellUpdate {
                        $0.titleLabel.text = "Add image to post"
                    }
                }
        }
    }()
    
    private func configure() {
        
        // Create RowFomers
        
        let infoRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.font = UIFont.systemFont(ofSize: 14)
            }.configure {
                $0.text = self.text
                $0.placeholder = "What's new \(User.current().fullname!)?"
                $0.rowHeight = 200
            }.onTextChanged {
                self.text = $0
        }
        
        // Create SectionFormers
        let section = SectionFormer(rowFormer: infoRow, imageOptionsRow)
        if self.image != nil {
            section.insert(rowFormer: onlyImageRow, below: infoRow)
        }
        
        self.former.append(sectionFormer: section)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        self.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.image = image
            self.onlyImageRow.cellUpdate {
                $0.displayImage.image = image
            }
            self.former.insertUpdate(rowFormer: self.onlyImageRow, above: self.imageOptionsRow, rowAnimation: .automatic)
            self.imageOptionsRow.cellUpdate {
                $0.titleLabel.text = "Remove image from post"
            }
        } else{
            Toast.genericErrorMessage()
        }
    }
}

