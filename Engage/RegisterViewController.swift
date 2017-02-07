//
//  RegisterViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2/4/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import Former

class RegisterViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var name: String?
    private var email: String?
    private var password: String?
    private var passwordVerification: String?
    private var image: UIImage?
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        self.setTitleView(title: "Registration", subtitle: nil, titleColor: Color.defaultTitle , subtitleColor: Color.defaultSubtitle)
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
        Log.write(.status, "Register button pressed")
        
        // Create new user
        let user = PFUser()
        user.username = self.email
        user.email = self.email
        user.password = self.passwordVerification
        user[PF_USER_FULLNAME] = self.name
        user[PF_USER_FULLNAME_LOWER] = self.name?.lowercased()
        
        // Save new user
        user.signUpInBackground { (success, error) -> Void in
            UIApplication.shared.endIgnoringInteractionEvents()
            if success {
                if self.image != nil {
                    let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(self.image!, 0.6)!)
                    pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                        if error != nil {
                            Log.write(.error, error.debugDescription)
                        }
                    }
                } else {
                    let query = PFQuery(className: "Engagements")
                    query.whereKey("name", equalTo: "Test")
                    query.findObjectsInBackground(block: { (objects, error) in
                        if let object = objects?.first {
                            User.didLogin(with: PFUser.current()!)
                            Engagement.didSelect(with: object)
                        }
                    })
                }
            } else {
                Log.write(.error, error.debugDescription)
                Toast.genericErrorMessage()
            }
        }
    }
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Former Rows
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private lazy var imageRow: LabelRowFormer<ProfileImageCell> = {
        LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) { _ in
            }.configure {
                $0.text = "Choose profile image from library"
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
                $0.placeholder = "Required"
            }.onTextChanged {
                self.name = $0
        }
        let emailRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Email"
            $0.textField.keyboardType = .emailAddress
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Required"
            }.onTextChanged {
                self.email = $0
        }
        let passwordRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Password"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Required"
            }.onTextChanged {
                self.password = $0
        }
        let passwordVerifyRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Password"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Required"
            }.onTextChanged {
                self.passwordVerification = $0
        }
        
        
        // Create SectionFormers
        let section = SectionFormer(rowFormer: nameRow, emailRow, passwordRow, passwordVerifyRow, imageRow)
        
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
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            var imageToBeSaved = image
            picker.dismiss(animated: true, completion: nil)
            
            if image.size.width > 500 {
                let resizeFactor = 500 / image.size.width
                imageToBeSaved = image.resizeImage(width: resizeFactor * image.size.width, height: resizeFactor * image.size.height, renderingMode: .alwaysOriginal)
            }
            
            self.image = imageToBeSaved
            self.imageRow.cellUpdate {
                $0.iconView.image = imageToBeSaved
            }
        } else{
            Log.write(.error, "Could not present image picker")
            Toast.genericErrorMessage()
        }
    }
}
