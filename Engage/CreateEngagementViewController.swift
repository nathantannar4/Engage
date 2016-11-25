
//
//  CreateEngagement.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-11.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import ChameleonFramework

class CreateEngagementViewController: FormViewController {
    
    var searching = false
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        self.navigationItem.titleView = Utilities.setTitle(title: "Create", subtitle: "New Engagement")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createButtonPressed))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonPressed))
        self.tableView.contentInset.top = 10
        self.tableView.contentInset.bottom = 100
        
        Engagement.sharedInstance.clear()
        
        configure()
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
    
    fileprivate lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
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
    
    // MARK: Private
    
    fileprivate lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    fileprivate func configure() {
        
        let customCheckRow = CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.text = ""
            $0.titleLabel.textAlignment = .center
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 13)
            $0.selectionStyle = .none
        }
        
        // Create RowFomers
        let nameRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Name"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.text = Engagement.sharedInstance.name
            }.onTextChanged {
                self.searching = true
                let characterset = NSCharacterSet(charactersIn: " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ")
                let name = $0
                if name == "" {
                    Engagement.sharedInstance.name = name
                    customCheckRow.cellUpdate({
                        $0.titleLabel.text = "Please Enter a Name"
                        $0.titleLabel.textColor = MAIN_COLOR
                    })
                } else if name.rangeOfCharacter(from: characterset.inverted) != nil {
                    Engagement.sharedInstance.name = ""
                    customCheckRow.cellUpdate({
                        $0.titleLabel.text = "Name Contains Special Characters or Numbers"
                        $0.titleLabel.textColor = UIColor.red
                    })
                } else {
                    let nameQuery = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
                    nameQuery.whereKey(PF_ENGAGEMENTS_LOWERCASE_NAME, equalTo: name.lowercased())
                    nameQuery.findObjectsInBackground(block: { (engagements: [PFObject]?, error: Error?) in
                        if error == nil {
                            if engagements!.count > 0 {
                                Engagement.sharedInstance.name = ""
                                customCheckRow.cellUpdate({
                                    $0.titleLabel.text = "Name Not Available"
                                    $0.titleLabel.textColor = UIColor.flatRed()
                                })
                            } else {
                                Engagement.sharedInstance.name = name
                                customCheckRow.cellUpdate({
                                    $0.titleLabel.text = "Name Available"
                                    $0.titleLabel.textColor = UIColor.flatGreen()
                                })
                            }
                        }
                        self.searching = false
                    })
                }
        }
        let infoRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = .formerSubColor()
            $0.textView.font = .systemFont(ofSize: 15)
            }.configure {
                $0.placeholder = "Group info..."
                $0.rowHeight = 200
            }.onTextChanged {
                Engagement.sharedInstance.info = $0
        }
        let selectImageRow = self.createMenu("Choose cover photo") { [weak self] in
            self?.former.deselect(animated: true)
            self?.presentImagePicker()
        }
        let hiddenRow = SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Hide group in search?"
            $0.formSegmented().tintColor = MAIN_COLOR
            $0.formSegmented().selectedSegmentIndex = 0
            }.configure {
                $0.segmentTitles = ["  No  ", "  Yes  "]
                $0.selectedIndex = 0
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
                $0.selectedIndex = 0
            }.onSegmentSelected { (index, choice) in
                if index == 0 {
                    self.former.removeUpdate(rowFormer: passwordRow, rowAnimation: .fade)
                } else {
                    self.former.insertUpdate(rowFormer: passwordRow, toIndexPath: NSIndexPath(row: 2, section: 2) as IndexPath)
                }
        }
        
        // Create SectionFormers
        let nameSection = SectionFormer(rowFormer: nameRow, customCheckRow)
        
        let personalizationSection = SectionFormer(rowFormer: infoRow, onlyImageRow, selectImageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Personalization"))
        
        let securitySection = SectionFormer(rowFormer: hiddenRow, passwordChoiceRow).set(headerViewFormer: TableFunctions.createHeader(text: "Security Settings"))
        
        self.former.append(sectionFormer: nameSection, personalizationSection, securitySection).onCellSelected { [weak self] _ in
            self?.formerInputAccessoryView.update()
        }
    }
    
    fileprivate func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.navigationBar.barTintColor = MAIN_COLOR
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }
    
    // MARK: User actions
    func cancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createButtonPressed(_ sender: AnyObject) {
        if searching {
            SVProgressHUD.showInfo(withStatus: "Verifying Name")
        } else if Engagement.sharedInstance.name != "" {
            Engagement.sharedInstance.create(completion: {
                SVProgressHUD.showSuccess(withStatus: "Group Created")
                self.dismiss(animated: true, completion: nil)
            })
        } else {
            SVProgressHUD.showError(withStatus: "Invalid Name")
        }
    }
}

extension CreateEngagementViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            onlyImageRow.cellUpdate {
                $0.displayImage.image = image
            }
            
            if image.size.width > 750 {
                let resizeFactor = 750 / image.size.width
                
                Engagement.sharedInstance.coverPhoto = Images.resizeImage(image: image, width: resizeFactor * image.size.width, height: resizeFactor * image.size.height)!
            }
        } else{
            print("Something went wrong")
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
