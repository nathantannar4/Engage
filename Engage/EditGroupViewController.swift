


//
//  EditEngagementGroupViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-13.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import Former
import Agrume


class EditGroupViewController: FormViewController, UserSelectionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    enum photoSelection {
        case isLogo, isCover
    }
    private var imagePickerType = photoSelection.isLogo
    private var group: Group!
    
    // MARK: - Initializers
    public convenience init(group: Group) {
        self.init()
        self.group = group
    }
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setTitleView(title: self.group.name, subtitle: "Edit", titleColor: Color.defaultTitle, subtitleColor: Color.defaultSubtitle)
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
        Log.write(.status, "Save button pressed")
        self.group.save { (success) in
            if success {
                if self.group is Engagement {
                    let toast = Toast(text: "Engagement Updated", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 2.0)
                    self.dismiss(animated: true, completion: nil)
                } else if self.group is Team {
                    let toast = Toast(text: "Team Updated", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 2.0)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        if let engagement = self.group as? Engagement {
            engagement.undoModifications()
            self.dismiss(animated: true, completion: nil)
        } else if let team = self.group as? Team {
            team.undoModifications()
            self.dismiss(animated: true, completion: nil)
        }
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
    
    private lazy var imageRow: LabelRowFormer<ProfileImageCell> = {
        LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
            $0.iconView.image = self.group.image
            }.configure {
                $0.text = "Choose logo from library"
                $0.rowHeight = 60
            }.onSelected {_ in 
                self.former.deselect(animated: true)
                self.imagePickerType = .isLogo
                self.presentImagePicker()
        }
    }()
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.image = self.group.coverImage
            }.configure {
                $0.rowHeight = 200
            }
            .onSelected({ (cell: LabelRowFormer<ImageCell>) in
                if self.group.coverImage != nil {
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
        
        let infoRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.font = UIFont.systemFont(ofSize: 14)
            }.configure {
                $0.text = self.group.info
                $0.placeholder = "Info"
                $0.rowHeight = 200
            }.onTextChanged {
                self.group.info = $0
        }
        let urlRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Website"
            $0.textField.keyboardType = .URL
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Add url"
                $0.text = self.group.url
            }.onTextChanged {
                self.group.url = $0
        }
        let addressRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Address"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Add address"
                $0.text = self.group.address
            }.onTextChanged {
                self.group.address = $0
        }
        let phoneRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Phone"
            $0.textField.keyboardType = .numberPad
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Add phone number"
                $0.text = self.group.phone
            }.onTextChanged {
                self.group.phone = $0
        }
        let emailRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Email"
            $0.textField.keyboardType = .emailAddress
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Add email"
                $0.text = self.group.email
            }.onTextChanged {
                self.group.email = $0
        }
        
        // Create SectionFormers
        let imageSection = SectionFormer(rowFormer: onlyImageRow, coverPhotoSelectionRow, imageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Images"))
        
        let aboutSection = SectionFormer(rowFormer: infoRow, urlRow, addressRow, phoneRow, emailRow).set(headerViewFormer: TableFunctions.createHeader(text: "About"))
        
        former.append(sectionFormer: imageSection, aboutSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
    }
    
    // MARK: UserSelectionDelegate
    
    func didMakeSelection(ofUsers users: [User]) {
        
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
            
            let group = self.group.object
            switch self.imagePickerType {
            case .isLogo:
                group[PF_ENGAGEMENTS_LOGO] = pictureFile
            case .isCover:
                group[PF_ENGAGEMENTS_COVER_PHOTO] = pictureFile
            }
            group.saveInBackground { (succeeded: Bool, error:
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
                        self.group.image = imageToBeSaved
                        self.imageRow.cellUpdate {
                            $0.iconView.image = imageToBeSaved
                        }
                    case .isCover:
                        self.group.coverImage = imageToBeSaved
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

