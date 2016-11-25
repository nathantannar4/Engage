//
//  CreateSubGroupViewController.swift
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
import ChameleonFramework

class CreateSubGroupViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var searching = false
    var isSponsor = false
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        if !isSponsor {
            if Engagement.sharedInstance.subGroupName != "" {
                self.navigationItem.titleView = Utilities.setTitle(title: "Create", subtitle: "New \(Engagement.sharedInstance.subGroupName!)")
            } else {
                self.navigationItem.titleView = Utilities.setTitle(title: "Create", subtitle: "New Subgroup")
            }
        } else {
            title = "New Sponsor"
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createButtonPressed))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonPressed))
        self.tableView.contentInset.top = 10
        self.tableView.contentInset.bottom = 100
        
        EngagementSubGroup.sharedInstance.clear()
        
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
    
    // MARK: Private
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private func configure() {
        
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
                $0.text = EngagementSubGroup.sharedInstance.name
            }.onTextChanged {
                self.searching = true
                let name = $0
                if name == "" {
                    EngagementSubGroup.sharedInstance.name = name
                    customCheckRow.cellUpdate({
                        $0.titleLabel.text = "Please Enter a Name"
                        $0.titleLabel.textColor = MAIN_COLOR
                    })
                } else {
                    let nameQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_SUBGROUP_CLASS_NAME)")
                    nameQuery.whereKey(PF_ENGAGEMENTS_LOWERCASE_NAME, equalTo: name.lowercased())
                    nameQuery.findObjectsInBackground(block: { (engagements: [PFObject]?, error: Error?) in
                        SVProgressHUD.dismiss()
                        if error == nil {
                            if engagements!.count > 0 {
                                EngagementSubGroup.sharedInstance.name = ""
                                customCheckRow.cellUpdate({
                                    $0.titleLabel.text = "Name Not Available"
                                    $0.titleLabel.textColor = UIColor.flatRed()
                                })
                            } else {
                                EngagementSubGroup.sharedInstance.name = name
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
                EngagementSubGroup.sharedInstance.info = $0
        }
        let selectImageRow = self.createMenu("Choose cover photo") { [weak self] in
            self?.former.deselect(animated: true)
            self?.presentImagePicker()
        }
        
        // Create SectionFormers
        let nameSection = SectionFormer(rowFormer: nameRow, customCheckRow)
        
        let personalizationSection = SectionFormer(rowFormer: infoRow, onlyImageRow, selectImageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Personalization"))
        
        self.former.append(sectionFormer: nameSection, personalizationSection).onCellSelected { [weak self] _ in
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
    
    // MARK: User actions
    func cancelButtonPressed(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createButtonPressed(sender: AnyObject) {
        if searching {
            SVProgressHUD.showInfo(withStatus: "Verifying Name")
        } else if EngagementSubGroup.sharedInstance.name != "" {
            EngagementSubGroup.sharedInstance.create(completion: {
                self.dismiss(animated: true, completion: nil)
            }, isSponsor: self.isSponsor)
        } else {
            SVProgressHUD.showError(withStatus: "Invalid Name")
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
            
                EngagementSubGroup.sharedInstance.coverPhoto = Images.resizeImage(image: image, width: resizeFactor * image.size.width, height: resizeFactor * image.size.height)!
            }
        } else{
            print("Something went wrong")
            SVProgressHUD.showError(withStatus: "An Error Occurred")
        }
    }
}

