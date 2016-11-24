//
//  EditProfileViewController.swift
//  Former-Demo
//
//  Created by Ryo Aoyama on 10/31/15.
//  Copyright © 2015 Ryo Aoyama. All rights reserved.
//
//  Modified by Nathan Tannar

import UIKit
import Former
import Parse
import Agrume
import SVProgressHUD
import Material

final class EditProfileViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        title = "Edit Profile"
        tableView.contentInset.top = 20
        tableView.contentInset.bottom = 100
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.cm.check, style: .plain, target: self, action: #selector(saveButtonPressed))
        configure()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    func saveButtonPressed() {
        Profile.sharedInstance.saveUser()
    }
    
    // MARK: Private
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
  
    
    private lazy var imageRow: LabelRowFormer<ProfileImageCell> = {
        LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
            $0.iconView.image = Profile.sharedInstance.image
            }.configure {
                $0.text = "Choose profile image from library"
                $0.rowHeight = 60
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                self?.presentImagePicker()
        }
    }()
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.image = Profile.sharedInstance.image
            }.configure {
                $0.rowHeight = 200
            }
            .onSelected({ (cell: LabelRowFormer<ImageCell>) in
                if Profile.sharedInstance.image != nil {
                    let agrume = Agrume(image: cell.cell.displayImage.image!)
                    agrume.showFrom(self)
                }
        })
    }()
    
    private func configure() {
        
        // Create RowFomers
        
        let nameRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Name"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Add your name"
                $0.text = Profile.sharedInstance.name
            }.onTextChanged {
                Profile.sharedInstance.name = $0
        }
        let phoneRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Phone"
            $0.textField.keyboardType = .numberPad
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Add your phone number"
                $0.text = Profile.sharedInstance.phoneNumber
            }.onTextChanged {
                Profile.sharedInstance.phoneNumber = $0
        }
        
        // Create SectionFormers
        let imageSection = SectionFormer(rowFormer: onlyImageRow, imageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Profile Image"))
        
        let basicSection = SectionFormer(rowFormer: nameRow, phoneRow).set(headerViewFormer: TableFunctions.createHeader(text: "Basic"))
        
        former.append(sectionFormer: imageSection, basicSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
        
        // Indicates user is editing profile within engagement
        var customRow = [RowFormer]()
        
        if Engagement.sharedInstance.engagement != nil {
            
            // Query to find current data
            var counter = 0
            for field in Engagement.sharedInstance.profileFields {
                let index = counter
                customRow.append(CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
                    $0.titleLabel.text = field
                    $0.titleLabel.textColor = MAIN_COLOR
                    $0.titleLabel.font = .boldSystemFont(ofSize: 15)
                    $0.selectionStyle = .none
                    })
                
                customRow.append(TextViewRowFormer<FormTextViewCell>() { [weak self] in
                    $0.textView.textColor = UIColor.black
                    
                    $0.textView.font = .systemFont(ofSize: 15)
                    $0.textView.inputAccessoryView = self?.formerInputAccessoryView
                    }.configure {
                        $0.placeholder = "Tap to edit..."
                        $0.text = Profile.sharedInstance.customFields[index]
                        $0.rowHeight = 60
                    }.onTextChanged {
                        Profile.sharedInstance.customFields[index] = $0
                    })
                counter += 1
            }
            
            self.former.insert(sectionFormer: SectionFormer(rowFormers: customRow).set(headerViewFormer: TableFunctions.createHeader(text: "About")), toSection: self.former.sectionFormers.count)
        }
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
            var imageToBeSaved = image
            picker.dismiss(animated: true, completion: nil)
            Profile.sharedInstance.image = image
            imageRow.cellUpdate {
                $0.iconView.image = image
            }
            onlyImageRow.cellUpdate {
                $0.displayImage.image = image
            }
            
            
            if image.size.width > 300 {
                let resizeFactor = 300 / image.size.width
                
                imageToBeSaved = Images.resizeImage(image: image, width: resizeFactor * image.size.width, height: resizeFactor * image.size.height)!
            }
            
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(imageToBeSaved, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error != nil {
                    print("Network error")
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            }
            
            let user = PFUser.current()!
            user[PF_USER_PICTURE] = pictureFile
            user.saveInBackground { (succeeded: Bool, error:
                Error?) -> Void in
                if error != nil {
                    print("Network error")
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
                else {
                    SVProgressHUD.showSuccess(withStatus: "Image Uploaded")
                }
            }
            
        } else{
            print("Something went wrong")
        }
    }
}
