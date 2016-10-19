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

class EditPostViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var post: PFObject?
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveButtonPressed))
        
        configure()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
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
            $0.displayImage.backgroundColor = MAIN_COLOR
            }.configure {
                $0.rowHeight = 200
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
                self.navigationController!.popToRootViewController(animated: true)
                SVProgressHUD.showSuccess(withStatus: "Post Deleted")
        }
        return SectionFormer(rowFormer: removePhotoRow)
    }()
    
    private func configure() {
        title = "Edit Post"
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 20
        
        let infoRow = TextViewRowFormer<FormTextViewCell>() { [weak self] in
            $0.textView.textColor = .formerSubColor()
            $0.textView.font = .systemFont(ofSize: 15)
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



