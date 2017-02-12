


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
    enum userSelection {
        case promotion, removal, positionAssigned, positionEmptied, none
    }
    private var userSelectionPurpose = userSelection.none
    private var setPositionTo = String()
    
    // MARK: - Initializers
    public convenience init(group: Group) {
        self.init()
        self.group = group
    }
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setTitleView(title: self.group.name, subtitle: "Edit", titleColor: Color.defaultTitle, subtitleColor: Color.defaultSubtitle)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.Google.check, style: .plain, target: self, action: #selector(saveButtonPressed(sender:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Google.close, style: .plain, target: self, action: #selector(cancelButtonPressed(sender:)))
        
        UIApplication.shared.statusBarStyle = .default
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
            $0.accessoryType = .disclosureIndicator
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
        let hiddenRow = SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Hide group in search?"
            $0.formSegmented().tintColor = Color.defaultNavbarTint
            }.configure {
                $0.segmentTitles = ["  No  ", "  Yes  "]
                if self.group.hidden! {
                    $0.selectedIndex = 1
                } else {
                    $0.selectedIndex = 0
                }
            }.onSegmentSelected { (index, choice) in
                if index == 0 {
                    self.group.hidden = false
                } else {
                    self.group.hidden = true
                }
        }
        let passwordRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Password"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = self.group.password
            }.onTextChanged {
                self.group.password = $0
        }
        let passwordChoiceRow = SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Password Protected?"
            $0.formSegmented().tintColor = Color.defaultNavbarTint
            $0.formSegmented().selectedSegmentIndex = 0
            }.configure {
                $0.segmentTitles = ["  No  ", "  Yes  "]
                if self.group.password!.isEmpty {
                    $0.selectedIndex = 0
                } else {
                    $0.selectedIndex = 1
                }
            }.onSegmentSelected { (index, choice) in
                if index == 0 {
                    self.former.removeUpdate(rowFormer: passwordRow, rowAnimation: .fade)
                    self.group.password = String()
                    passwordRow.configure {
                        $0.text = String()
                    }
                } else {
                    self.former.insertUpdate(rowFormer: passwordRow, toIndexPath: IndexPath(row: 2, section: 4))
                }
        }
        let detailsRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = "Profile Fields"
            $0.date = ""
            $0.body = "These are fields of extra information about each user. You can choose what those fields are! Please note field names cannot include spaces or special characters and need to be separated by commas."
            $0.titleColor = Color.defaultNavbarTint
            $0.bodyColor = Color.defaultTitle
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
        let profileFieldsRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = Color.defaultSubtitle
            $0.textView.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightLight)
            }.configure {
                var currentFields = String()
                for field in self.group.profileFields! {
                    currentFields.append("\(field),")
                }
                $0.text = currentFields
                $0.placeholder = "Separate each field by a comma"
                $0.rowHeight = 100
            }.onTextChanged {
                let components = $0.components(separatedBy: ",")
                var parsedComponents = [String]()
                for component in components {
                    let data = component.replacingOccurrences(of: " ", with: "").lowercased().capitalized
                    if !data.isEmpty {
                        parsedComponents.append(data)
                    }
                }
                self.group.profileFields = parsedComponents
        }
        let positionsRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = "Group Positions"
            $0.date = ""
            $0.body = "Set your groups positions. Please note position names cannot include special characters and need to be separated by commas."
            $0.titleColor = Color.defaultNavbarTint
            $0.bodyColor = Color.defaultTitle
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
        let positionFieldsRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = Color.defaultSubtitle
            $0.textView.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightLight)
            }.configure {
                var currentFields = String()
                for field in self.group.positions! {
                    currentFields.append("\(field),")
                }
                $0.text = currentFields
                $0.placeholder = "Separate each position by a comma"
                $0.rowHeight = 100
            }.onTextChanged {
                let components = $0.components(separatedBy: ",")
                var parsedComponents = [String]()
                for component in components {
                    let data = component.replacingOccurrences(of: " ", with: "").lowercased().capitalized
                    if !data.isEmpty {
                        parsedComponents.append(data)
                    }
                }
                self.group.positions = parsedComponents
        }
        let setPositionRow = self.createMenu("Assign or Vacate Positions") { _ in
            self.former.deselect(animated: true)
            self.setPosition()
        }
        let promoteRow = self.createMenu("Promote member(s) to admin") { _ in
            self.former.deselect(animated: true)
            self.userSelectionPurpose = .promotion
            let vc = UserSelectionViewController(group: self.group)
            vc.selectionDelegate = self
            vc.allowMultipleSelection = true
            let navVC = UINavigationController(rootViewController: vc)
            self.present(navVC, animated: true, completion: nil)
        }
        let kickRow = self.createMenu("Remove member(s)") { _ in
            self.former.deselect(animated: true)
            self.userSelectionPurpose = .removal
            let vc = UserSelectionViewController(group: self.group)
            vc.selectionDelegate = self
            vc.allowMultipleSelection = true
            let navVC = UINavigationController(rootViewController: vc)
            self.present(navVC, animated: true, completion: nil)
        }

        // Create SectionFormers
        let imageSection = SectionFormer(rowFormer: onlyImageRow, coverPhotoSelectionRow, imageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Images"))
        
        let aboutSection = SectionFormer(rowFormer: infoRow, urlRow, addressRow, phoneRow, emailRow).set(headerViewFormer: TableFunctions.createHeader(text: "About"))
        
        let customSection = SectionFormer(rowFormer: detailsRow, profileFieldsRow, positionsRow, positionFieldsRow, setPositionRow).set(headerViewFormer: TableFunctions.createHeader(text: "Customization"))
        
        let adminSection = SectionFormer(rowFormer: promoteRow, kickRow).set(headerViewFormer: TableFunctions.createHeader(text: "Administration"))
        
        self.former.append(sectionFormer: imageSection, aboutSection, customSection, adminSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
        
        if self.group is Engagement {
            let securitySection = SectionFormer(rowFormer: hiddenRow, passwordChoiceRow).set(headerViewFormer: TableFunctions.createHeader(text: "Security & Privacy"))
            if !self.group.password!.isEmpty {
                securitySection.append(rowFormer: passwordRow)
            }
            self.former.append(sectionFormer: securitySection)
        }
    }
    
    // MARK: UserSelectionDelegate
    
    func didMakeSelection(ofUsers users: [User]) {
        if users.count == 0 {
            return
        }
        switch self.userSelectionPurpose {
        case .positionAssigned:
            self.group.setPosition(forUser: users[0], position: self.setPositionTo.lowercased(), completion: { (success) in
                if success {
                    let toast = Toast(text: "\(users[0].fullname) was assigned \(self.setPositionTo.capitalized)", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.0)
                }
            })
        case .positionEmptied:
            self.group.emptyPosition(self.setPositionTo.lowercased(), completion: { (success) in
                if success {
                    let toast = Toast(text: "\(self.setPositionTo.capitalized) was vacated", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.0)
                }
            })
        case .promotion:
            for user in users {
                self.group.promote(user: user, completion: { (success) in
                    if success {
                        let toast = Toast(text: "\(user.fullname!) was made an admin", button: nil, color: Color.darkGray, height: 44)
                        toast.dismissOnTap = true
                        toast.show(duration: 1.0)
                    }
                })
            }
        case .removal:
            for user in users {
                self.group.leave(user: user, completion: { (success) in
                    if success {
                        let toast = Toast(text: "\(user.fullname!) was removed", button: nil, color: Color.darkGray, height: 44)
                        toast.dismissOnTap = true
                        toast.show(duration: 1.0)
                    }
                })
            }
        case .none:
            break
        }
    }
    
    private func setPosition() {
        let actionSheetController: UIAlertController = UIAlertController(title: "\(self.group.name!) Positions", message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = Color.defaultNavbarTint
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheetController.addAction(cancelAction)
        
        let set: UIAlertAction = UIAlertAction(title: "Assign", style: .default)
        { action -> Void in
            let actionSheetController: UIAlertController = UIAlertController(title: "Assign \(self.group.name!) Positions", message: "Which position would you like to assign?", preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = Color.defaultNavbarTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheetController.addAction(cancelAction)
            
            for currentTitle in self.group.positions! {
                let action: UIAlertAction = UIAlertAction(title: currentTitle, style: .default)
                { action -> Void in
                    let vc = UserSelectionViewController(group: self.group)
                    self.userSelectionPurpose = .positionAssigned
                    self.setPositionTo = currentTitle
                    vc.selectionDelegate = self
                    vc.allowMultipleSelection = false
                    let navVC = UINavigationController(rootViewController: vc)
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
            let actionSheetController: UIAlertController = UIAlertController(title: "Vacate \(self.group.name!) Positions", message: "Which positions would you like to vacate?", preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = Color.defaultNavbarTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheetController.addAction(cancelAction)
            
            for currentTitle in self.group.positions! {
                let action: UIAlertAction = UIAlertAction(title: currentTitle, style: .default)
                { action -> Void in
                    let vc = UserSelectionViewController(group: self.group)
                    self.userSelectionPurpose = .positionEmptied
                    self.setPositionTo = currentTitle
                    vc.selectionDelegate = self
                    vc.allowMultipleSelection = false
                    let navVC = UINavigationController(rootViewController: vc)
                    self.present(navVC, animated: true, completion: nil)
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

