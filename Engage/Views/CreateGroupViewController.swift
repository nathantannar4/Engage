//
//  CreateGroupViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/20/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents
import Former
import Agrume
import Parse

class CreateGroupViewController: NTNavigationViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        tableView.contentInset.bottom = 60
        return tableView
    }()
    private lazy var former: Former = Former(tableView: self.tableView)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Create Engagement"
        backButton.image = Icon.Delete
        nextButton.image = Icon.Check?.scale(to: 30)
        
        view.addSubview(tableView)
        tableView.anchor(navBarView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        
        view.sendSubview(toBack: tableView)
        
        configure()
    }
    
    override func backButtonPressed() {
        let alert = NTAlertViewController(title: "Are you sure?", subtitle: "You will lose all progress", type: .isDanger)
        alert.confirmButton.title = "Cancel creation"
        alert.cancelButton.title = "Wait I am not finished"
        alert.onConfirm = {
            super.backButtonPressed()
        }
        present(alert, animated: true, completion: nil)
    }
    
    override func nextButtonPressed() {
        guard let name = group.name else {
            NTPing(type: .isDanger, title: "You Must Enter a Name").show()
            return
        }
        let characterset = NSCharacterSet(charactersIn: " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
        if name.rangeOfCharacter(from: characterset.inverted) != nil {
            NTPing(type: .isDanger, title: "Invalid Name").show()
        } else if name.characters.count >= 3 {
            group.create { (success) in
                if success {
                    Engagement.didSelect(with: self.group as! Engagement)
                }
            }
        } else {
            NTPing(type: .isDanger, title: "Invalid Name").show()
        }
    }
    
    enum photoSelection {
        case isLogo, isCover
    }
    private var imagePickerType = photoSelection.isLogo
    private var group: Group!
    private var searching = false
    
    // MARK: Initialization
    
    convenience init(asEngagement: Bool) {
        self.init()
        self.group = Engagement()
        self.group.name = String()
    }
    
    // MARK: - Form
    
    let createMenu: ((String, (() -> Void)?) -> RowFormer) = { text, onSelected in
        return LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = Color.Default.Text.Callout
            $0.titleLabel.font = Font.Default.Callout
            $0.accessoryType = .disclosureIndicator
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
    }
    
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
    
    // MARK: Private
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private func configure() {
        
        let customCheckRow = CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.text = ""
            $0.titleLabel.textAlignment = .center
            $0.titleLabel.font = Font.Default.Body
            $0.titleLabel.textColor = Color.Default.Text.Body
            $0.selectionStyle = .none
        }
        
        // Create RowFomers
        let nameRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Name"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Required"
            }.onTextChanged {
                self.searching = true
                let characterset = NSCharacterSet(charactersIn: " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
                let name = $0
                if name.isEmpty {
                    self.group.name = name
                    customCheckRow.cellUpdate({
                        $0.titleLabel.text = "Please Enter a Name"
                        $0.titleLabel.textColor = Color.Default.Text.Body
                    })
                } else if name.characters.count <= 2 {
                    self.group.name = ""
                    customCheckRow.cellUpdate({
                        $0.titleLabel.text = "Name Is Too Short"
                        $0.titleLabel.textColor = Color.Default.Status.Danger
                    })
                } else if name.rangeOfCharacter(from: characterset.inverted) != nil {
                    self.group.name = ""
                    customCheckRow.cellUpdate({
                        $0.titleLabel.text = "Name Contains Special Characters or Numbers"
                        $0.titleLabel.textColor = Color.Default.Status.Danger
                    })
                } else {
                    let nameQuery = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
                    nameQuery.whereKey(PF_ENGAGEMENTS_LOWERCASE_NAME, equalTo: name.lowercased())
                    nameQuery.findObjectsInBackground(block: { (engagements: [PFObject]?, error: Error?) in
                        if error == nil {
                            if engagements!.count > 0 {
                                self.group.name = ""
                                customCheckRow.cellUpdate({
                                    $0.titleLabel.text = "Name Not Available"
                                    $0.titleLabel.textColor = Color.Default.Status.Danger
                                })
                            } else {
                                self.group.name = name
                                customCheckRow.cellUpdate({
                                    $0.titleLabel.text = "Name Available"
                                    $0.titleLabel.textColor = Color.Default.Status.Success
                                })
                            }
                        }
                        self.searching = false
                    })
                }
        }
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
        
        let infoRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.font = Font.Default.Body
            $0.textView.textColor = Color.Default.Text.Body
            $0.textView.inputAccessoryView = self.formerInputAccessoryView
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
            $0.textField.autocorrectionType = .no
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
            $0.titleLabel.font = Font.Default.Body
            $0.formSegmented().tintColor = Color.Default.Tint.View
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
            $0.titleLabel.font = Font.Default.Body
            $0.formSegmented().tintColor = Color.Default.Tint.View
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
                    self.former.insertUpdate(rowFormer: passwordRow, toIndexPath: IndexPath(row: 2, section: 2))
                }
        }
        
        // Create SectionFormers
        let imageSection = SectionFormer(rowFormer: onlyImageRow, coverPhotoSelectionRow, imageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Images"))
        
        let aboutSection = SectionFormer(rowFormer: nameRow, customCheckRow, infoRow, urlRow, addressRow, phoneRow, emailRow).set(headerViewFormer: TableFunctions.createHeader(text: "About"))
        
        let securitySection = SectionFormer(rowFormer: hiddenRow, passwordChoiceRow).set(headerViewFormer: TableFunctions.createHeader(text: "Security & Privacy"))
        
        self.former.append(sectionFormer: imageSection, aboutSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
        
        if self.group is Engagement {
            self.former.append(sectionFormer: securitySection)
        }
    }
    
    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.navigationBar.barTintColor = Color.Default.Background.NavigationBar
        picker.navigationBar.tintColor = Color.Default.Tint.NavigationBar
        picker.navigationBar.shadowImage = UIImage()
        picker.navigationBar.isTranslucent = false
        picker.navigationBar.setBackgroundImage(UIImage(), for: .default)
        picker.navigationBar.setDefaultShadow()
        present(picker, animated: true, completion: nil)
    }
    
    // MARK: User actions
    func cancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createButtonPressed(_ sender: AnyObject) {
        if self.searching {
            NTPing(type: .isWarning, title: "Verifying Name Availability").show()
        } else if !self.group.name!.isEmpty {
            self.group.create(completion: { (success) in
                if success {
                    NTPing(type: .isSuccess, title: "Group Created").show()
                    self.dismiss(animated: true, completion: nil)
                }
            })
        } else {
            NTPing(type: .isDanger, title: "Invalid Name").show()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            var imageToBeSaved = image
            picker.dismiss(animated: true, completion: nil)
            
            if image.size.width > 500 {
                let resizeFactor = 500 / image.size.width
                imageToBeSaved = image.resizeImage(width: image.size.width * resizeFactor, height: image.size.height * resizeFactor)!
            }
            
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
}
