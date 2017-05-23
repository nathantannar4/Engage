//
//  EditProfileViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/19/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents
import Former
import Parse
import Agrume

class EditUserViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    enum photoSelection {
        case isLogo, isCover
    }
    private var imagePickerType = photoSelection.isLogo
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        setTitleView(title: "Profile", subtitle: "Edit")
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setDefaultShadow()
        tableView.contentInset.top = 10
        tableView.contentInset.bottom = 100
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.Check?.scale(to: 25), style: .plain, target: self, action: #selector(saveButtonPressed(sender:)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Delete?.scale(to: 25), style: .plain, target: self, action: #selector(cancelButtonPressed(sender:)))
        
        
        configure()
    }
    
    // MARK: User Actions
    
    func saveButtonPressed(sender: UIBarButtonItem) {
        Log.write(.status, "Save button pressed")
        User.current()?.save { (success) in
            if success {
                NTPing(type: .isSuccess, title: "Profile Saved").show()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        //User.current().undoModifications()
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: Former Rows
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
  
    
    private lazy var imageRow: LabelRowFormer<ProfileImageCell> = {
        LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
            $0.iconView.image = User.current()?.image
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
            $0.displayImage.image = User.current()?.coverImage
            }.configure {
                $0.rowHeight = 200
            }
            .onSelected({ (cell: LabelRowFormer<ImageCell>) in
                if User.current()?.coverImage != nil {
                    let agrume = Agrume(image: cell.cell.displayImage.image!)
                    agrume.showFrom(self)
                }
            })
    }()
    
    private func configure() {
        
        // Create RowFomers
        
        let coverPhotoSelectionRow = LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = Color.Default.Text.Callout
            $0.titleLabel.font = Font.Default.Callout
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
                $0.text = User.current()?.fullname
            }.onTextChanged {
                User.current()?.fullname = $0
        }
        let emailRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Email"
            $0.textField.keyboardType = .emailAddress
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Add your email"
                $0.text = User.current()?.email
                $0.enabled = false
            }.onTextChanged {
                User.current()?.email = $0
        }
        let phoneRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Phone"
            $0.textField.keyboardType = .numberPad
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Add your phone number"
                $0.text = User.current()?.phone
            }.onTextChanged {
                User.current()?.phone = $0
        }
        let infoRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.font = Font.Default.Body
            }.configure {
                $0.text = User.current()?.userExtension?.bio
                $0.placeholder = "Bio"
                $0.rowHeight = 80
            }.onTextChanged {
                User.current()?.userExtension?.bio = $0
        }
        
        // Create SectionFormers
        let imageSection = SectionFormer(rowFormer: onlyImageRow, coverPhotoSelectionRow, imageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Images"))
        
        let basicSection = SectionFormer(rowFormer: nameRow, emailRow, phoneRow, infoRow).set(headerViewFormer: TableFunctions.createHeader(text: "About"))
        
        self.former.append(sectionFormer: imageSection, basicSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
        
        // Indicates user is editing profile within engagement
        var customRow = [RowFormer]()
        
        // Query to find current data
        guard let fields = Engagement.current()?.profileFields else {
            return
        }
        
        for field in fields {
            customRow.append(TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
                $0.titleLabel.text = field
                $0.textField.inputAccessoryView = self?.formerInputAccessoryView
                }.configure {
                    $0.placeholder = "Tap to edit..."
                    $0.text = User.current()?.userExtension?.field(forIndex: fields.index(of: field)!)
                }.onTextChanged {
                    guard let userExtention = User.current()?.userExtension else {
                        return
                    }
                    userExtention.setValue($0, forField: field)
            })
        }
        
        self.former.insert(sectionFormer: SectionFormer(rowFormers: customRow), toSection: self.former.sectionFormers.count)
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
                imageToBeSaved = image.resizeImage(width: image.size.width * resizeFactor, height: image.size.height * resizeFactor)!
            }
            
            NTToast(text: "Uploading Image...").show(duration: 1.0)
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(imageToBeSaved, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error != nil {
                    Log.write(.error, error.debugDescription)
                    NTToast(text: error?.localizedDescription.capitalized).show()
                }
            }
            
            let user = User.current()?.object
            switch self.imagePickerType {
            case .isLogo:
                user?[PF_USER_PICTURE] = pictureFile
            case .isCover:
                user?[PF_USER_COVER] = pictureFile
            }
            user?.saveInBackground { (succeeded: Bool, error:
                Error?) -> Void in
                if error != nil {
                    Log.write(.error, error.debugDescription)
                    NTToast(text: error?.localizedDescription.capitalized).show()
                }
                else {
                    NTToast(text: "Image Uploaded.").show(duration: 1.0)
                    
                    switch self.imagePickerType {
                    case .isLogo:
                        User.current()?.image = imageToBeSaved
                        self.imageRow.cellUpdate {
                            $0.iconView.image = imageToBeSaved
                        }
                    case .isCover:
                        User.current()?.coverImage = imageToBeSaved
                        self.onlyImageRow.cellUpdate {
                            $0.displayImage.image = imageToBeSaved
                        }
                    }
                }
            }
        } else{
            Log.write(.error, "Could not present image picker")
            NTPing.genericErrorMessage()
        }
    }
}
