//
//  EditPostViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-13.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import Material

class EditPostViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var post: PFObject?
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.titleView = Utilities.setTitle(title: "Edit", subtitle: "Post")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.cm.check, style: .plain, target: self, action: #selector(saveButtonPressed))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.cm.close, style: .plain, target: self, action: #selector(cancelButtonPressed))
        
        configure()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    func cancelButtonPressed(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveButtonPressed(sender: UIBarButtonItem) {
        if self.post!["hasImage"] as? Bool == true {
            
            if self.image!.size.width > 300 {
                
                let resizeFactor = 300 / self.image!.size.width
                
                self.image = Images.resizeImage(image: self.image!, width: resizeFactor * self.image!.size.width, height: resizeFactor * self.image!.size.height)!
            }
            
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(self.image!, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error == nil {
                    self.post!["image"] = pictureFile
                    self.post!.saveInBackground(block: { (success: Bool, error: Error?) in
                        if error == nil {
                            SVProgressHUD.showSuccess(withStatus: "Post Updated")
                        } else {
                            SVProgressHUD.showError(withStatus: "Network Error")

                        }
                    })
                }
            }
        } else {
            self.post!.saveInBackground(block: { (success: Bool, error: Error?) in
                if error == nil {
                    SVProgressHUD.showSuccess(withStatus: "Post Updated")
                } else {
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            })
        }
    }
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private lazy var zeroRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {_ in
            }.configure {
                $0.rowHeight = 0
        }
    }()
    
    private lazy var imageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.image = self.image
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: $0.displayImage.frame.width, height: 20.0))
            label.backgroundColor = MAIN_COLOR
            label.textColor = UIColor.white
            label.font = RobotoFont.regular(with: 16.0)
            label.center = CGPoint(x: $0.displayImage.frame.width/5, y: 150)
            label.textAlignment = .center
            label.text = "Tap to Change Image"
            $0.displayImage.addSubview(label)
            $0.displayImage.contentMode = .scaleAspectFit
            }.configure {
                $0.rowHeight = 300
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                self?.presentImagePicker()
        }
    }()
    
    private lazy var removePhotoRow: RowFormer = {
        let removePhotoRow = CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.text = "Remove Photo"
            $0.titleLabel.textAlignment = .center
            }.onSelected { _ in
                self.former.deselect(animated: true)
                self.post!["hasImage"] = false
                self.image = nil
                self.imageRow.cellUpdate {
                    $0.displayImage.image = self.image
                }
        }
        return removePhotoRow
    }()
    
    private lazy var deletePostSection: SectionFormer = {
        let removePhotoRow = CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.text = "Delete Post"
            $0.titleLabel.textAlignment = .center
            }.onSelected { _ in
                self.former.deselect(animated: true)
                self.post!.deleteInBackground()
                self.dismiss(animated: true)
                SVProgressHUD.showSuccess(withStatus: "Post Deleted")
        }
        return SectionFormer(rowFormer: removePhotoRow)
    }()
    
    private func configure() {
        title = "Edit Post"
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 50
        
        let infoRow = TextViewRowFormer<FormTextViewCell>() { [weak self] in
            $0.textView.textColor = .formerSubColor()
            $0.textView.font = RobotoFont.regular(with: 15)
            $0.textView.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "What's new?"
                $0.text = self.post!["info"] as? String
                $0.rowHeight = 350
            }.onTextChanged {
                self.post!["info"] = $0
        }
        
        let editPostSection = SectionFormer(rowFormer: infoRow, imageRow, removePhotoRow)
        former.append(sectionFormer: editPostSection, deletePostSection).onCellSelected { [weak self] _ in
            self?.formerInputAccessoryView.update()
        }
        former.reload()
    }
    
    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.navigationBar.barTintColor = MAIN_COLOR
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.image = image
            self.post!["hasImage"] = true
            imageRow.cellUpdate {
                $0.displayImage.image = image
            }
        } else{
            print("Something went wrong")
            SVProgressHUD.showError(withStatus: "An Error Occurred")
        }
    }
}



