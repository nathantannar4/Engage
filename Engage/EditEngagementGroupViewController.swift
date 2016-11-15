


//
//  EditEngagementGroupViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-13.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import Material

class EditEngagementGroupViewController: FormViewController, SelectUsersFromGroupDelegate, SelectSingleViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var setPosition = ""
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.contentInset.top = 10
        self.tableView.contentInset.bottom = 100
        
        configure()
        prepareToolbar()
    }
    
    private func prepareToolbar() {
        guard let tc = toolbarController else {
            return
        }
        tc.toolbar.title = "Edit"
        tc.toolbar.detail = "\(Engagement.sharedInstance.name!)"
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
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    func saveButtonPressed() {
        Engagement.sharedInstance.save()
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
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.image = Engagement.sharedInstance.coverPhoto
            }.configure {
                $0.rowHeight = 200
            }.onSelected({ _ in
                if Engagement.sharedInstance.coverPhoto != nil {
                    let agrume = Agrume(image: Engagement.sharedInstance.coverPhoto!)
                    agrume.showFrom(self)
                }
            })
    }()
    
    private lazy var urlRow: TextFieldRowFormer<ProfileFieldCell> = {
        TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Website"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = Engagement.sharedInstance.url
            }.onTextChanged {
                Engagement.sharedInstance.url = $0
        }
    }()
    
    private lazy var emailRow: TextFieldRowFormer<ProfileFieldCell> = {
        TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Email"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = Engagement.sharedInstance.email
            }.onTextChanged {
                Engagement.sharedInstance.email = $0
        }
    }()
    
    private lazy var deleteSection: SectionFormer = {
        let deleteRow = CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.text = "Delete \(Engagement.sharedInstance.name!)"
            $0.titleLabel.textAlignment = .center
            }.onSelected { _ in
                self.former.deselect(animated: true)
                let alert = UIAlertController(title: "Delete Group?", message: "All data will be deleted.", preferredStyle: UIAlertControllerStyle.alert)
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
                        Engagement.sharedInstance.delete(completion: {
                            SVProgressHUD.showSuccess(withStatus: "Group Deleted")
                            self.dismiss(animated: true, completion: nil)
                        }())
                    }
                    alert.addAction(leave)
                    self.present(alert, animated: true, completion: nil)

                }
                alert.addAction(leave)
                self.present(alert, animated: true, completion: nil)
        }
        return SectionFormer(rowFormer: deleteRow).set(headerViewFormer: TableFunctions.createFooter(text: ""))
    }()
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private func configure() {
        
        let infoRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = .formerSubColor()
            $0.textView.font = .systemFont(ofSize: 15)
            }.configure {
                $0.text = Engagement.sharedInstance.info!
                $0.placeholder = "Group info..."
                $0.rowHeight = 200
            }.onTextChanged {
                Engagement.sharedInstance.info = $0
        }
        let selectImageRow = self.createMenu("Choose cover photo") { [weak self] in
            self?.former.deselect(animated: true)
            self?.presentImagePicker()
        }
        _ = SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Do you have sponsors?"
            $0.formSegmented().tintColor = MAIN_COLOR
            $0.formSegmented().selectedSegmentIndex = 0
            }.configure {
                $0.segmentTitles = ["  No  ", "  Yes  "]
                if Engagement.sharedInstance.sponsor == true {
                    $0.selectedIndex = 1
                } else {
                    $0.selectedIndex = 0
                }
            }.onSegmentSelected { (index, choice) in
                if index == 0 {
                    Engagement.sharedInstance.sponsor = false
                } else {
                    Engagement.sharedInstance.sponsor = true
                }
        }
        let hiddenRow = SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Hide group in search?"
            $0.formSegmented().tintColor = MAIN_COLOR
            }.configure {
                $0.segmentTitles = ["  No  ", "  Yes  "]
                if Engagement.sharedInstance.hidden! {
                    $0.selectedIndex = 1
                } else {
                    $0.selectedIndex = 0
                }
            }.onSegmentSelected { (index, choice) in
                if index == 0 {
                    Engagement.sharedInstance.hidden = false
                } else {
                    Engagement.sharedInstance.hidden = true
                }
        }
        let passwordRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Password"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = Engagement.sharedInstance.password
            }.onTextChanged {
                Engagement.sharedInstance.password = $0
        }
        let passwordChoiceRow = SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Password Protected?"
            $0.formSegmented().tintColor = MAIN_COLOR
            $0.formSegmented().selectedSegmentIndex = 0
            }.configure {
                $0.segmentTitles = ["  No  ", "  Yes  "]
                if Engagement.sharedInstance.password == "" {
                    $0.selectedIndex = 0
                } else {
                    $0.selectedIndex = 1
                }
            }.onSegmentSelected { (index, choice) in
                if index == 0 {
                    self.former.removeUpdate(rowFormer: passwordRow, rowAnimation: .fade)
                    Engagement.sharedInstance.password = ""
                    passwordRow.configure {
                        $0.text = ""
                    }
                } else {
                    self.former.insertUpdate(rowFormer: passwordRow, toIndexPath: IndexPath(row: 2, section: 2))
                }
        }
        let subGroupNameDetails = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = "Subgroup Name"
            $0.date = ""
            $0.body = "You can specify an alternative name to your subgroups that will be displayed in the menu and subgroup page. If the field is left blank the default name will be used."
            $0.titleColor = MAIN_COLOR
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
        let subGroupNameRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Alt. Name"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = Engagement.sharedInstance.subGroupName
            }.onTextChanged {
                Engagement.sharedInstance.subGroupName = $0
        }
        let detailsRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = "Profile Fields"
            $0.date = ""
            $0.body = "These are fields of extra information about each user. You can choose what those fields are! Please note field names cannot include spaces or special characters and need to be separated by commas."
            $0.titleColor = MAIN_COLOR
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
        let profileFieldsRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = .formerSubColor()
            $0.textView.font = .systemFont(ofSize: 15)
            }.configure {
                var currentFields = ""
                for field in Engagement.sharedInstance.profileFields {
                    currentFields.append("\(field),")
                }
                $0.text = currentFields
                Engagement.sharedInstance.fieldInput = currentFields
                $0.placeholder = "Separate each field by a comma"
                $0.rowHeight = 100
            }.onTextChanged {
                Engagement.sharedInstance.fieldInput = $0
        }
        let positionsRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = "Group Positions"
            $0.date = ""
            $0.body = "Set your groups positions. Please note position names cannot include special characters and need to be separated by commas."
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
                for field in Engagement.sharedInstance.positions {
                    currentFields.append("\(field),")
                }
                $0.text = currentFields
                Engagement.sharedInstance.positionsField = currentFields
                $0.placeholder = "Separate each position by a comma"
                $0.rowHeight = 100
            }.onTextChanged {
                Engagement.sharedInstance.positionsField = $0
        }
        let setPositionRow = createMenu("Assign or Vacate Positions") { [weak self] in
            self?.former.deselect(animated: true)
            self?.setExecutives()
        }

        let inviteRow = createMenu("Assign New Admins") { [weak self] in
            self?.former.deselect(animated: true)
            let vc = SelectUsersFromGroupViewController()
            vc.delegate = self
            let navVC = UINavigationController(rootViewController:  vc)
            navVC.navigationBar.barTintColor = MAIN_COLOR!
            self?.present(navVC, animated: true, completion: nil)
        }
        let colorHexRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Color"
            $0.textField.placeholder = "HEX Value"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = Engagement.sharedInstance.color
            }.onTextChanged {
                if $0.contains("#") {
                    if $0.length == 4 || $0.length == 7 {
                        Engagement.sharedInstance.color = $0
                    }
                    
                } else {
                    if $0.length == 3 || $0.length == 6 {
                        Engagement.sharedInstance.color = "#" + $0
                    }
                }
        }
        let colorListRow = CustomRowFormer<ColorListCell>(instantiateType: .Nib(nibName: "ColorListCell")) {
            $0.colors = [
                UIColor.flatRedColorDark(),
                UIColor.flatBlue(),
                UIColor.flatBlueColorDark(),
                UIColor.flatNavyBlue(),
                UIColor.flatNavyBlueColorDark(),
                UIColor.flatSkyBlue(),
                UIColor.flatSkyBlueColorDark(),
                UIColor.flatYellowColorDark(),
                UIColor.flatGreen(),
                UIColor.flatGreenColorDark(),
                UIColor.flatForestGreen(),
                UIColor.flatForestGreenColorDark(),
                UIColor.flatPink(),
                UIColor.flatPurple(),
                UIColor.flatPurpleColorDark(),
                UIColor(red: 153.0/255, green:62.0/255.0, blue:123.0/255, alpha: 1),
                UIColor.flatOrange(),
                UIColor.flatOrangeColorDark(),
                UIColor.flatBrown(),
                UIColor.flatCoffee(),
                UIColor.flatCoffeeColorDark(),
                UIColor.flatGray(),
                UIColor.flatGrayColorDark(),
                UIColor.flatBlack()
            ]
            $0.onColorSelected = { color in
                colorHexRow.cellUpdate({ (cell) in
                    cell.textField.text = color.hexValue()
                })
                Engagement.sharedInstance.color = color.hexValue()
                self.navigationController?.navigationBar.barTintColor = color
            }
            }.configure {
                $0.rowHeight = 60
        }
        
        
        // Create SectionFormers
        
        let personalizationSection = SectionFormer(rowFormer: infoRow, colorHexRow, colorListRow, onlyImageRow, selectImageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Personalization"))
        
        let aboutSection = SectionFormer(rowFormer: urlRow, emailRow).set(headerViewFormer: TableFunctions.createHeader(text: "About"))
        
        let securitySection = SectionFormer(rowFormer: hiddenRow, passwordChoiceRow).set(headerViewFormer: TableFunctions.createHeader(text: "Security Settings"))
        
        let customSection = SectionFormer(rowFormer: subGroupNameDetails, subGroupNameRow, detailsRow, profileFieldsRow, positionsRow, positionFieldsRow, setPositionRow).set(headerViewFormer: TableFunctions.createHeader(text: "Customization"))
        
        let adminSection = SectionFormer(rowFormer: inviteRow).set(headerViewFormer: TableFunctions.createHeader(text: "Administration"))

        
        self.former.append(sectionFormer: personalizationSection, aboutSection, securitySection, customSection, adminSection, deleteSection).onCellSelected { [weak self] _ in
            self?.formerInputAccessoryView.update()
        }
        self.former.reload()
        
        if Engagement.sharedInstance.password != "" {
            self.former.insertUpdate(rowFormer: passwordRow, toIndexPath: IndexPath(row: 2, section: 2))
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
        let actionSheetController: UIAlertController = UIAlertController(title: "\(Engagement.sharedInstance.name!) Positions", message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        let set: UIAlertAction = UIAlertAction(title: "Assign", style: .default)
        { action -> Void in
            let actionSheetController: UIAlertController = UIAlertController(title: "Assign \(Engagement.sharedInstance.name!) Positions", message: "Which position would you like to assign?", preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = MAIN_COLOR
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            for currentTitle in Engagement.sharedInstance.positions {
                let action: UIAlertAction = UIAlertAction(title: currentTitle, style: .default)
                { action -> Void in
                    self.setPosition = currentTitle
                    let vc = SelectSingleViewController()
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
            let actionSheetController: UIAlertController = UIAlertController(title: "Vacate \(Engagement.sharedInstance.name!) Positions", message: "Which positions would you like to vacate?", preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = MAIN_COLOR
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            for currentTitle in Engagement.sharedInstance.positions {
                let action: UIAlertAction = UIAlertAction(title: currentTitle, style: .default)
                { action -> Void in
                    if Engagement.sharedInstance.engagement![currentTitle.lowercased().replacingOccurrences(of: " ", with: "")] != nil {
                        Engagement.sharedInstance.engagement!.remove(forKey: currentTitle.lowercased().replacingOccurrences(of: " ", with: ""))
                        Engagement.sharedInstance.engagement!.saveInBackground(block: { (success: Bool, error: Error?) in
                            if error == nil {
                                print("Saved")
                                SVProgressHUD.showSuccess(withStatus: "\(currentTitle) Vacted")
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
    
    // MARK: Delegate Methods
    
    func didSelectSingleUser(user: PFUser) {
        if setPosition != "" {
            Engagement.sharedInstance.engagement![setPosition.lowercased().replacingOccurrences(of: " ", with: "")] = user.objectId
            Engagement.sharedInstance.engagement!.saveInBackground(block: { (success: Bool, error: Error?) in
                if error == nil {
                    SVProgressHUD.showSuccess(withStatus: "Position Assigned")
                } else {
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            })
        }
    }
    
    func didSelectMultipleUsers(selectedUsers: [PFUser]!) {
        
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
        self.former.insert(sectionFormer: SectionFormer(rowFormer: userRow), toSection: 5)
        self.former.reload()
        
        for newAdmin in selectedUsers {
            Engagement.sharedInstance.admins.append(newAdmin.objectId!)
        }
        let engagement = Engagement.sharedInstance.engagement
        engagement![PF_ENGAGEMENTS_ADMINS] = Engagement.sharedInstance.admins
        engagement!.saveInBackground()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            onlyImageRow.cellUpdate {
                $0.displayImage.image = image
            }
            
            if image.size.width > 750 {
                let resizeFactor = 750 / image.size.width
                
                Engagement.sharedInstance.coverPhoto = Images.resizeImage(image: image, width: resizeFactor * image.size.width, height: resizeFactor * image.size.height)!
            }
            
            UIApplication.shared.beginIgnoringInteractionEvents()
            SVProgressHUD.show(withStatus: "Uploading Image")
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(Engagement.sharedInstance.coverPhoto!, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error != nil {
                    print("Network error")
                }
            }
            Engagement.sharedInstance.engagement![PF_ENGAGEMENTS_COVER_PHOTO] = pictureFile
            Engagement.sharedInstance.engagement!.saveInBackground { (success: Bool, error: Error?) in
                UIApplication.shared.endIgnoringInteractionEvents()
                if error != nil {
                    print("Network error")
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

