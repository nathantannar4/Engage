//
//  EditSubGroupViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-27.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import Material

class EditSubGroupViewController: FormViewController, SelectUsersFromSubGroupDelegate, SelectSingleFromSubGroupDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var setPosition = ""
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.contentInset.top = 10
        self.tableView.contentInset.bottom = 100
        
        prepareToolbar()
        configure()
    }
    
    private func prepareToolbar() {
        guard let tc = toolbarController else {
            return
        }
        tc.toolbar.title = "Edit"
        tc.toolbar.detail = "\(EngagementSubGroup.sharedInstance.name!)"
        tc.toolbar.backgroundColor = MAIN_COLOR
        tc.toolbar.tintColor = UIColor.white
        let saveButton = IconButton(image: Icon.cm.check)
        saveButton.tintColor = UIColor.white
        saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        let backButton = IconButton(image: Icon.cm.arrowBack)
        backButton.tintColor = UIColor.white
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        appToolbarController.prepareToolbarCustom(left: [backButton], right: [saveButton])
    }
    
    @objc private func handleBackButton() {
        appToolbarController.rotateLeft(from: self)
    }
    
    let createMenu: ((String, (() -> Void)?) -> RowFormer) = { text, onSelected in
        return LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 16)
            $0.accessoryType = .disclosureIndicator
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
    }
    
    private lazy var deleteSection: SectionFormer = {
        let removePhotoRow = CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.text = "Delete \(EngagementSubGroup.sharedInstance.name!)"
            $0.titleLabel.textAlignment = .center
            }.onSelected { _ in
                self.former.deselect(animated: true)
                let alert = UIAlertController(title: "Delete Subgroup?", message: "All data will be deleted.", preferredStyle: UIAlertControllerStyle.alert)
                alert.view.tintColor = MAIN_COLOR
                //Create and add the Cancel action
                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                }
                alert.addAction(cancelAction)
                let leave: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { action -> Void in
                    let alert = UIAlertController(title: "Are you sure?", message: "This cannot be undone.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.view.tintColor = MAIN_COLOR
                    //Create and add the Cancel action
                    let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                        //Do some stuff
                    }
                    alert.addAction(cancelAction)
                    let leave: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { action -> Void in
                        // Delete subgroup pointer from each user
                        let userQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_User")
                        userQuery.whereKey(PF_USER_SUBGROUP, equalTo: EngagementSubGroup.sharedInstance.subgroup!)
                        userQuery.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
                            if error == nil {
                                for user in users! {
                                    print(user)
                                    user.remove(forKey: PF_USER_SUBGROUP)
                                    user.saveInBackground()
                                }
                                
                                // Delete subgroup
                                EngagementSubGroup.sharedInstance.subgroup!.deleteInBackground { (success: Bool, error: Error?) in
                                    if success {
                                        SVProgressHUD.showSuccess(withStatus: "Subgroup Deleted")
                                        self.navigationController!.popToRootViewController(animated: true)
                                    } else {
                                        SVProgressHUD.showError(withStatus: "Network Error")
                                    }
                                }
                            } else {
                                print(error.debugDescription)
                                SVProgressHUD.showError(withStatus: "Network Error")
                            }
                        })
                    }
                    alert.addAction(leave)
                    self.present(alert, animated: true, completion: nil)
                    
                }
                alert.addAction(leave)
                self.present(alert, animated: true, completion: nil)
        }
        return SectionFormer(rowFormer: removePhotoRow)
    }()
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.image = EngagementSubGroup.sharedInstance.coverPhoto
            }.configure {
                $0.rowHeight = 200
            }.onSelected({ _ in
                if EngagementSubGroup.sharedInstance.coverPhoto != nil {
                    let agrume = Agrume(image: EngagementSubGroup.sharedInstance.coverPhoto!)
                    agrume.showFrom(self)
                }
            })
    }()
    
    private lazy var phoneRow: TextFieldRowFormer<ProfileFieldCell> = {
        TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Phone"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.textField.keyboardType = .numberPad
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = EngagementSubGroup.sharedInstance.phone
            }.onTextChanged {
                EngagementSubGroup.sharedInstance.phone = $0
        }
    }()
    
    private lazy var urlRow: TextFieldRowFormer<ProfileFieldCell> = {
        TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Website"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = EngagementSubGroup.sharedInstance.url
            }.onTextChanged {
                EngagementSubGroup.sharedInstance.url = $0
        }
    }()
    
    private lazy var emailRow: TextFieldRowFormer<ProfileFieldCell> = {
        TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Email"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = EngagementSubGroup.sharedInstance.email
            }.onTextChanged {
                EngagementSubGroup.sharedInstance.email = $0
        }
    }()
    
    private lazy var addressRow: TextFieldRowFormer<ProfileFieldCell> = {
        TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Address"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = EngagementSubGroup.sharedInstance.address
            }.onTextChanged {
                EngagementSubGroup.sharedInstance.address = $0
        }
    }()
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private func configure() {
        
        // Create RowFomers
        
        let infoRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = .formerSubColor()
            $0.textView.font = .systemFont(ofSize: 15)
            }.configure {
                $0.text = EngagementSubGroup.sharedInstance.info
                $0.placeholder = "Group info..."
                $0.rowHeight = 200
            }.onTextChanged {
                EngagementSubGroup.sharedInstance.info = $0
        }
        let selectImageRow = self.createMenu("Choose cover photo") { [weak self] in
            self?.former.deselect(animated: true)
            self?.presentImagePicker()
        }
        let positionsRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = "Group Positions"
            $0.date = ""
            $0.body = "Set your sub groups positions. Please note position names cannot include special characters and need to be separated by commas."
            $0.titleColor = MAIN_COLOR
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
        let positionFieldsRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = .formerSubColor()
            $0.textView.font = .systemFont(ofSize: 15)
            }.configure {
                var currentFields = ""
                for field in EngagementSubGroup.sharedInstance.positions {
                    currentFields.append("\(field),")
                }
                $0.text = currentFields
                EngagementSubGroup.sharedInstance.positionsField = currentFields
                $0.placeholder = "Separate each position by a comma"
                $0.rowHeight = 100
            }.onTextChanged {
                EngagementSubGroup.sharedInstance.positionsField = $0
        }
        let setPositionRow = createMenu("Assign or Vacate Positions") { [weak self] in
            self?.former.deselect(animated: true)
            self?.setExecutives()
        }
        let inviteRow = createMenu("Assign New Admins") { [weak self] in
            self?.former.deselect(animated: true)
            let vc = SelectUsersFromSubGroupViewController()
            vc.delegate = self
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.barTintColor = MAIN_COLOR!
            self?.present(navVC, animated: true, completion: nil)
        }
        
        // Create SectionFormers
        
        let personalizationSection = SectionFormer(rowFormer: infoRow, onlyImageRow, selectImageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Personalization"))
        
        let aboutSection = SectionFormer(rowFormer: phoneRow, addressRow, urlRow, emailRow).set(headerViewFormer: TableFunctions.createHeader(text: "About"))
        
        let customSection = SectionFormer(rowFormer: positionsRow, positionFieldsRow, setPositionRow).set(headerViewFormer: TableFunctions.createHeader(text: "Customization"))
        
        let adminSection = SectionFormer(rowFormer: inviteRow).set(headerViewFormer: TableFunctions.createHeader(text: "Administration")).set(footerViewFormer: TableFunctions.createFooter(text: ""))
        
        self.former.append(sectionFormer: personalizationSection, aboutSection, customSection, adminSection, deleteSection).onCellSelected { [weak self] _ in
            self?.formerInputAccessoryView.update()
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
    
    private func setExecutives() {
        let actionSheetController: UIAlertController = UIAlertController(title: "\(EngagementSubGroup.sharedInstance.name!) Positions", message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        let set: UIAlertAction = UIAlertAction(title: "Assign", style: .default)
        { action -> Void in
            let actionSheetController: UIAlertController = UIAlertController(title: "Assign \(EngagementSubGroup.sharedInstance.name!) Positions", message: "Which position would you like to assign?", preferredStyle: .actionSheet)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            for currentTitle in EngagementSubGroup.sharedInstance.positions {
                let action: UIAlertAction = UIAlertAction(title: currentTitle, style: .default)
                { action -> Void in
                    self.setPosition = currentTitle
                    let vc = SelectSingleFromSubGroupViewController()
                    vc.delegate = self
                    let navVC = UINavigationController(rootViewController: vc)
                    navVC.navigationBar.barTintColor = MAIN_COLOR!
                    self.present(navVC, animated: true, completion: nil)
                }
                actionSheetController.addAction(action)
            }
            actionSheetController.popoverPresentationController?.sourceView = self.view
            //Present the AlertController
            self.present(actionSheetController, animated: true, completion: nil)
        }
        actionSheetController.addAction(set)
        
        let remove: UIAlertAction = UIAlertAction(title: "Vacate", style: .default)
        { action -> Void in
            let actionSheetController: UIAlertController = UIAlertController(title: "Vacate \(EngagementSubGroup.sharedInstance.name!) Positions", message: "Which positions would you like to vacate?", preferredStyle: .actionSheet)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            for currentTitle in EngagementSubGroup.sharedInstance.positions {
                let action: UIAlertAction = UIAlertAction(title: currentTitle, style: .default)
                { action -> Void in
                    if EngagementSubGroup.sharedInstance.subgroup![currentTitle.lowercased().replacingOccurrences(of: " ", with: "")] != nil {
                        EngagementSubGroup.sharedInstance.subgroup!.remove(forKey: currentTitle.lowercased().replacingOccurrences(of: " ", with: ""))
                        EngagementSubGroup.sharedInstance.subgroup!.saveInBackground(block: { (success: Bool, error: Error?) in
                            if error == nil {
                                print("Saved")
                                SVProgressHUD.showSuccess(withStatus: "\(currentTitle) Vacated")
                            } else {
                                SVProgressHUD.showError(withStatus: "Network Error")
                            }
                        })
                    }
                }
                actionSheetController.addAction(action)
            }
            actionSheetController.popoverPresentationController?.sourceView = self.view
            //Present the AlertController
            self.present(actionSheetController, animated: true, completion: nil)
        }
        actionSheetController.addAction(remove)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    // MARK: User actions
    
    func saveButtonPressed() {
        EngagementSubGroup.sharedInstance.save()
    }
    
    // MARK: Delegate Methods
    
    func didSelectSingleUser(user: PFUser) {
        if setPosition != "" {
            EngagementSubGroup.sharedInstance.subgroup![setPosition.lowercased().replacingOccurrences(of: " ", with: "")] = user.objectId
            EngagementSubGroup.sharedInstance.subgroup!.saveInBackground(block: { (success: Bool, error: Error?) in
                if error == nil {
                    SVProgressHUD.showSuccess(withStatus: "\(self.setPosition) Assigned")
                } else {
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            })
        }
    }
    
    func didSelectMultipleUsers(selectedUsers: [PFUser]!) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        SVProgressHUD.show(withStatus: "Adding Admins")
            for user in selectedUsers {
                EngagementSubGroup.sharedInstance.admins.append(user.objectId!)
            }
            EngagementSubGroup.sharedInstance.subgroup![PF_ENGAGEMENTS_ADMINS] = EngagementSubGroup.sharedInstance.admins
            EngagementSubGroup.sharedInstance.subgroup!.saveInBackground(block: { (success: Bool, error: Error?) in
                UIApplication.shared.endIgnoringInteractionEvents()
                SVProgressHUD.dismiss()
                if success {
                    // Returns current user in selectedUsers so they must be removed
                    var inviteUsers = selectedUsers
                    let index = inviteUsers?.index(of: PFUser.current()!)
                    inviteUsers?.remove(at: index!)
                    let userRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
                        $0.title = "These users are now admins:"
                        var invitedUsers = ""
                        for user in inviteUsers! {
                            invitedUsers.append("\(user[PF_USER_FULLNAME] as! String)\n")
                        }
                        $0.body = invitedUsers
                        $0.titleLabel.font = .boldSystemFont(ofSize: 15)
                        $0.titleLabel.textColor = MAIN_COLOR
                        $0.bodyLabel.font = .systemFont(ofSize: 15)
                        $0.date = ""
                        $0.selectionStyle = .none
                        }.configure {
                            $0.rowHeight = UITableViewAutomaticDimension
                    }
                    self.former.insert(sectionFormer: SectionFormer(rowFormer: userRow), toSection: 4)
                } else {
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            })
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            onlyImageRow.cellUpdate {
                $0.displayImage.image = image
            }
            
            if image.size.width > 750 {
                let resizeFactor = 750 / image.size.width
                
                EngagementSubGroup.sharedInstance.coverPhoto = Images.resizeImage(image: image, width: resizeFactor * image.size.width, height: resizeFactor * image.size.height)!
            }
            
            UIApplication.shared.beginIgnoringInteractionEvents()
            SVProgressHUD.show(withStatus: "Uploading Image")
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(EngagementSubGroup.sharedInstance.coverPhoto!, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error != nil {
                    print("Network error")
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            }
            EngagementSubGroup.sharedInstance.subgroup![PF_SUBGROUP_COVER_PHOTO] = pictureFile
            EngagementSubGroup.sharedInstance.subgroup!.saveInBackground { (success: Bool, error: Error?) in
                UIApplication.shared.endIgnoringInteractionEvents()
                if error != nil {
                    SVProgressHUD.showError(withStatus: "Network Error")
                } else {
                    SVProgressHUD.showSuccess(withStatus: "Image Uploaded")
                }
            }
        } else{
            print("Something went wrong")
            SVProgressHUD.showError(withStatus: "An Error Occurred")
        }
    }
}


