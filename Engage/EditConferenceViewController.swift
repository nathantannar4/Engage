//
//  EditConferenceViewController.swift
//  WESST
//
//  Created by Tannar, Nathan on 2016-09-14.
//  Copyright © 2016 NathanTannar. All rights reserved.
//


import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import BRYXBanner
import Material

class EditConferenceViewController: FormViewController, SelectSingleViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var setPosition = ""
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset.bottom = 100
        
        configure()
        prepareToolbar()
    }
    
    private func prepareToolbar() {
        guard let tc = toolbarController else {
            return
        }
        tc.toolbar.title = "Edit"
        tc.toolbar.detail = Conference.sharedInstance.name!
        tc.toolbar.backgroundColor = MAIN_COLOR
        let backButton = IconButton(image: Icon.cm.arrowBack)
        backButton.tintColor = UIColor.white
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        let saveButton = IconButton(image: Icon.cm.check)
        saveButton.tintColor = UIColor.white
        saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        tc.toolbar.leftViews = [backButton]
        tc.toolbar.rightViews = [saveButton]
    }
    
    @objc private func handleBackButton() {
        appToolbarController.rotateLeft(from: self)
    }
    
    func saveButtonPressed(sender: AnyObject) {
        Conference.sharedInstance.save()
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
            $0.displayImage.image = Conference.sharedInstance.coverPhoto
            }.configure {
                $0.rowHeight = 200
            }.onSelected({ _ in
                if Conference.sharedInstance.coverPhoto != nil {
                    let agrume = Agrume(image: Conference.sharedInstance.coverPhoto!)
                    agrume.showFrom(self)
                }
            })
    }()
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private func configure() {
        
        // Create row formers
        let selectImageRow = self.createMenu("Choose cover photo") { [weak self] in
            self?.former.deselect(animated: true)
            self?.presentImagePicker()
        }
        let infoRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = .formerSubColor()
            $0.textView.font = .systemFont(ofSize: 15)
            }.configure {
                $0.text = Conference.sharedInstance.info!
                $0.placeholder = "Conference info..."
                $0.rowHeight = 200
            }.onTextChanged {
                Conference.sharedInstance.info = $0
        }
        let hostSchoolRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Host"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "School Name"
                $0.text = Conference.sharedInstance.hostSchool
            }.onTextChanged {
                Conference.sharedInstance.hostSchool = $0
        }
        let locationRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Location"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "City Name"
                $0.text = Conference.sharedInstance.location
            }.onTextChanged {
                Conference.sharedInstance.location = $0
        }
        let endRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
            $0.titleLabel.text = "End"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.displayLabel.textColor = .formerSubColor()
            $0.displayLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.date = Conference.sharedInstance.end! as Date
            }.inlineCellSetup {
                $0.datePicker.datePickerMode = .date
            }.onDateChanged {
                Conference.sharedInstance.end = $0 as NSDate!
            }.displayTextFromDate(String.mediumDateNoTime)
        
        let startRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
            $0.titleLabel.text = "Start"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.displayLabel.textColor = .formerSubColor()
            $0.displayLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.date = Conference.sharedInstance.start! as Date
            }.inlineCellSetup {
                $0.datePicker.datePickerMode = .date
            }.onDateChanged {
                Conference.sharedInstance.start = $0 as NSDate!
            }.displayTextFromDate(String.mediumDateNoTime)

        let urlRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Website"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "URL"
                $0.text = Conference.sharedInstance.url
            }.onTextChanged {
                Conference.sharedInstance.url = $0
        }
        let keyRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Key"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = "Regstration Code"
                $0.text = Conference.sharedInstance.password
            }.onTextChanged {
                Conference.sharedInstance.password = $0
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
                for field in Conference.sharedInstance.positions {
                    currentFields.append("\(field),")
                }
                $0.text = currentFields
                Conference.sharedInstance.positionsField = currentFields
                $0.placeholder = "Separate each position by a comma"
                $0.rowHeight = 100
            }.onTextChanged {
                Conference.sharedInstance.positionsField = $0
        }
        let setPositionRow = createMenu("Assign or Vacate Positions") { [weak self] in
            self?.former.deselect(animated: true)
            self?.setExecutives()
        }
        
        
        // Create SectionFormers
        
        let personalizationSection = SectionFormer(rowFormer: onlyImageRow, selectImageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Cover Photo"))
        
        let aboutSection = SectionFormer(rowFormer: infoRow, hostSchoolRow, locationRow, startRow, endRow, urlRow, keyRow).set(headerViewFormer: TableFunctions.createHeader(text: "About"))
        
        let customSection = SectionFormer(rowFormer: positionsRow, positionFieldsRow, setPositionRow).set(headerViewFormer: TableFunctions.createHeader(text: "Roles"))
        
        self.former.append(sectionFormer: personalizationSection, aboutSection, customSection).onCellSelected { [weak self] _ in
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
        let actionSheetController: UIAlertController = UIAlertController(title: "\(Conference.sharedInstance.name!) Positions", message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        let set: UIAlertAction = UIAlertAction(title: "Assign", style: .default)
        { action -> Void in
            let actionSheetController: UIAlertController = UIAlertController(title: "Assign \(Conference.sharedInstance.name!) Positions", message: "Which position would you like to assign?", preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = MAIN_COLOR
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            for currentTitle in Conference.sharedInstance.positions {
                let action: UIAlertAction = UIAlertAction(title: currentTitle, style: .default)
                { action -> Void in
                    let vc = SelectSingleViewController()
                    vc.delegate = self
                    let navVC = UINavigationController(rootViewController: vc)
                    self.setPosition = currentTitle
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
            let actionSheetController: UIAlertController = UIAlertController(title: "Vacate \(Conference.sharedInstance.name!) Positions", message: "Which positions would you like to vacate?", preferredStyle: .actionSheet)
            actionSheetController.view.tintColor = MAIN_COLOR
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            for currentTitle in Conference.sharedInstance.positions {
                let action: UIAlertAction = UIAlertAction(title: currentTitle, style: .default)
                { action -> Void in
                    if Conference.sharedInstance.conference![currentTitle.lowercased().replacingOccurrences(of: " ", with: "")] != nil {
                        Conference.sharedInstance.conference!.remove(forKey: currentTitle.lowercased().replacingOccurrences(of: " ", with: ""))
                        Conference.sharedInstance.conference!.saveInBackground(block: { (success: Bool, error: Error?) in
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
    
    // MARK: Delegate Methods
    
    func didSelectSingleUser(user: PFUser) {
        if setPosition != "" {
            Conference.sharedInstance.conference![setPosition.lowercased().replacingOccurrences(of: " ", with: "")] = user.objectId
            Conference.sharedInstance.conference!.saveInBackground(block: { (success: Bool, error: Error?) in
                if error == nil {
                    SVProgressHUD.showSuccess(withStatus: "\(self.setPosition) Assigned")
                } else {
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            })
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            onlyImageRow.cellUpdate {
                $0.displayImage.image = image
            }
            
            if image.size.width > 750 {
                let resizeFactor = 750 / image.size.width
                
                Conference.sharedInstance.coverPhoto = Images.resizeImage(image: image, width: resizeFactor * image.size.width, height: resizeFactor * image.size.height)!
            }
            
            UIApplication.shared.beginIgnoringInteractionEvents()
            SVProgressHUD.show(withStatus: "Uploading Photo")
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(Conference.sharedInstance.coverPhoto!, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error != nil {
                    print("Network error")
                }
            }
            Conference.sharedInstance.conference![PF_ENGAGEMENTS_COVER_PHOTO] = pictureFile
            Conference.sharedInstance.conference!.saveInBackground { (success: Bool, error: Error?) in
                UIApplication.shared.endIgnoringInteractionEvents()
                SVProgressHUD.dismiss()
                if error != nil {
                    print("Network error")
                    SVProgressHUD.showError(withStatus: "Network Error")
                }
            }
        } else{
            print("Something went wrong")
            SVProgressHUD.showError(withStatus: "An Error Occurred")
        }
    }
}
