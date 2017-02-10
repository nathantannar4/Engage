//
//  EditProfileViewController.swift
//  Former-Demo
//
//  Created by Ryo Aoyama on 10/31/15.
//  Copyright © 2015 Ryo Aoyama. All rights reserved.
//
//  Modified by Nathan Tannar

import UIKit
import NTUIKit
import Former
import Parse
import Agrume

class EditProfileViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    enum photoSelection {
        case isLogo, isCover
    }
    private var imagePickerType = photoSelection.isLogo
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        self.setTitleView(title: "Profile", subtitle: "Edit", titleColor: Color.defaultTitle , subtitleColor: Color.defaultSubtitle)
        self.navigationController?.navigationBar.isTranslucent = false
        self.tableView.contentInset.top = 10
        self.tableView.contentInset.bottom = 100
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.Google.check, style: .plain, target: self, action: #selector(saveButtonPressed(sender:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Google.close, style: .plain, target: self, action: #selector(cancelButtonPressed(sender:)))
        if Color.defaultNavbarBackground.isLight {
            UIApplication.shared.statusBarStyle = .default
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }
        
        self.configure()
    }
    
    // MARK: User Actions
    
    func saveButtonPressed(sender: UIBarButtonItem) {
        Log.write(.status, "Save button pressed")
        User.current().save { (success) in
            if success {
                let toast = Toast(text: "Profile Updated", button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 2.0)
                self.dismiss(animated: true, completion: nil)
            } else {
                Toast.genericErrorMessage()
            }
        }
    }
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        User.current().undoModifications()
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Former Rows
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
  
    
    private lazy var imageRow: LabelRowFormer<ProfileImageCell> = {
        LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
            $0.iconView.image = User.current().image
            }.configure {
                $0.text = "Choose profile image from library"
                $0.rowHeight = 60
            }.onSelected {_ in
                self.former.deselect(animated: true)
                self.imagePickerType = .isLogo
                self.presentImagePicker()
        }
    }()
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.image = User.current().coverImage
            }.configure {
                $0.rowHeight = 200
            }
            .onSelected({ (cell: LabelRowFormer<ImageCell>) in
                if User.current().coverImage != nil {
                    let agrume = Agrume(image: cell.cell.displayImage.image!)
                    agrume.showFrom(self)
                }
            })
    }()
    
    private func configure() {
        
        // Create RowFomers
        
        let coverPhotoSelectionRow = LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = Color.defaultNavbarTint
            $0.titleLabel.font = .boldSystemFont(ofSize: 16)
            }.configure {
                $0.text = "Choose cover photo from library"
            }.onSelected { _ in
                self.former.deselect(animated: true)
                self.imagePickerType = .isCover
                self.presentImagePicker()
        }
        let nameRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Name"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Full Name"
                $0.text = User.current().fullname
            }.onTextChanged {
                User.current().fullname = $0
        }
        let phoneRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Phone"
            $0.textField.keyboardType = .numberPad
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Add your phone number"
                $0.text = User.current().phone
            }.onTextChanged {
                User.current().phone = $0
        }
        let infoRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.font = UIFont.systemFont(ofSize: 14)
            }.configure {
                $0.text = User.current().userExtension?.bio
                $0.placeholder = "Bio"
                $0.rowHeight = 80
            }.onTextChanged {
                User.current().userExtension?.bio = $0
        }
        
        // Create SectionFormers
        let imageSection = SectionFormer(rowFormer: onlyImageRow, coverPhotoSelectionRow, imageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Images"))
        
        let basicSection = SectionFormer(rowFormer: nameRow, phoneRow, infoRow).set(headerViewFormer: TableFunctions.createHeader(text: "Basic"))
        
        self.former.append(sectionFormer: imageSection, basicSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
        
        // Indicates user is editing profile within engagement
        var customRow = [RowFormer]()
        
        // Query to find current data
        guard let fields = Engagement.current().profileFields else {
            return
        }
        
        for field in fields {
            customRow.append(TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
                $0.titleLabel.text = field
                $0.textField.inputAccessoryView = self?.formerInputAccessoryView
                }.configure {
                    $0.placeholder = "Tap to edit..."
                    $0.text = User.current().userExtension?.field(forIndex: fields.index(of: field)!)
                }.onTextChanged {
                    guard let userExtention = User.current().userExtension else {
                        return
                    }
                    userExtention.setValue($0, forField: field)
            })
        }
        
        self.former.insert(sectionFormer: SectionFormer(rowFormers: customRow).set(headerViewFormer: TableFunctions.createHeader(text: "About")), toSection: self.former.sectionFormers.count)
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
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            var imageToBeSaved = image
            picker.dismiss(animated: true, completion: nil)
            
            if image.size.width > 500 {
                let resizeFactor = 500 / image.size.width
                imageToBeSaved = image.resizeImage(width: resizeFactor * image.size.width, height: resizeFactor * image.size.height, renderingMode: .alwaysOriginal)
            }
            
            let toast = Toast(text: "Uploading Image...", button: nil, color: Color.darkGray, height: 44)
            toast.show(duration: 1.0)
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(imageToBeSaved, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error != nil {
                    Log.write(.error, error.debugDescription)
                    Toast.genericErrorMessage()
                }
            }
            
            let user = User.current().object
            switch self.imagePickerType {
            case .isLogo:
                user[PF_USER_PICTURE] = pictureFile
            case .isCover:
                user[PF_USER_COVER] = pictureFile
            }
            user.saveInBackground { (succeeded: Bool, error:
                Error?) -> Void in
                if error != nil {
                    Log.write(.error, error.debugDescription)
                    Toast.genericErrorMessage()
                }
                else {
                    let toast = Toast(text: "Image Uploaded", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.0)
                    
                    switch self.imagePickerType {
                    case .isLogo:
                        User.current().image = imageToBeSaved
                        self.imageRow.cellUpdate {
                            $0.iconView.image = imageToBeSaved
                        }
                    case .isCover:
                        User.current().coverImage = imageToBeSaved
                        self.onlyImageRow.cellUpdate {
                            $0.displayImage.image = imageToBeSaved
                        }
                    }
                }
            }
        } else{
            Log.write(.error, "Could not present image picker")
            Toast.genericErrorMessage()
        }
    }
}
