//
//  EditChannelViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2/9/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import Former
import Agrume


class EditChannelViewController: FormViewController, UserSelectionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var channel: Channel!
    private var isEditingChannel = false
    
    // MARK: - Initializers
    public convenience init(channel: Channel) {
        self.init()
        self.channel = channel
    }
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setTitleView(title: self.channel.name, subtitle: "Edit", titleColor: Color.defaultTitle, subtitleColor: Color.defaultSubtitle)
        self.navigationController?.navigationBar.isTranslucent = false
        
        if let admins = self.channel.admins {
            if admins.contains(User.current().id) {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleEditing))
            }
        }
        
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
    
    func toggleEditing() {
        self.isEditingChannel = !self.isEditingChannel
        if self.isEditingChannel {
            self.navigationItem.setRightBarButton(UIBarButtonItem(image: Icon.Google.check, style: .plain, target: self, action: #selector(saveButtonPressed(sender:))), animated: true)
        } else {
            self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleEditing)), animated: true)
        }
    }
    
    func saveButtonPressed(sender: UIBarButtonItem) {
        Log.write(.status, "Save button pressed")
        self.channel.save { (success) in
            if success {
                let toast = Toast(text: "Channel Updated", button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 2.0)
                self.toggleEditing()
            }
        }
    }
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        if self.isEditingChannel {
            self.channel.undoModifications()
            self.toggleEditing()
            self.former.reload()
        } else {
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
            $0.iconView.image = self.channel.image
            }.configure {
                $0.text = "Choose logo from library"
                $0.rowHeight = 60
            }.onSelected {_ in
                self.former.deselect(animated: true)
                self.presentImagePicker()
        }
    }()
    
    private func configure() {
        
        // Create RowFomers
        let nameRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Name"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Group Name"
                $0.text = self.channel.name
                $0.enabled = self.isEditingChannel
            }.onTextChanged {
                self.channel.name = $0
        }
        
        var memberRows = [RowFormer]()
        for member in self.channel.members! {
            memberRows.append(LabelRowFormer<ProfileImageDetailCell>(instantiateType: .Nib(nibName: "ProfileImageDetailCell")) {
                $0.accessoryType = .detailButton
                $0.tintColor = Color.defaultNavbarTint
                $0.iconView.backgroundColor = Color.defaultNavbarTint
                $0.iconView.layer.borderWidth = 1
                $0.iconView.layer.borderColor = Color.defaultNavbarTint.cgColor
                $0.iconView.image = Cache.retrieveUser(member)?.image
                $0.titleLabel.textColor = UIColor.black
                $0.detailLabel.textColor = UIColor.gray
                $0.detailLabel.text = "Admin"
                }.configure {
                    $0.text = Cache.retrieveUser(member)?.fullname
                    $0.rowHeight = 60
                }.onSelected { [weak self] _ in
                    self?.former.deselect(animated: true)
                    
            })
        }
        
        // Create SectionFormers
        let aboutSection = SectionFormer(rowFormer: imageRow, nameRow).set(headerViewFormer: TableFunctions.createHeader(text: "About"))
        
        let membersSection = SectionFormer(rowFormers: memberRows).set(headerViewFormer: TableFunctions.createHeader(text: "Members"))
        
        former.append(sectionFormer: aboutSection, membersSection)
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
            
            let channel = self.channel.object
            channel[PF_CHANNEL_IMAGE] = pictureFile
            channel.saveInBackground { (succeeded: Bool, error:
                Error?) -> Void in
                if error != nil {
                    Log.write(.error, error.debugDescription)
                    Toast.genericErrorMessage()
                }
                else {
                    let toast = Toast(text: "Image Uploaded", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.0)
                    
                    self.channel.image = imageToBeSaved
                    self.imageRow.cellUpdate {
                        $0.iconView.image = imageToBeSaved
                    }
                }
            }
            
        } else{
            Log.write(.error, "Could not present image picker")
            Toast.genericErrorMessage()
        }
    }
}


