//
//  CreateAdvancedEventViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-13.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse

final class CreateAdvancedEventViewController: FormViewController, SelectMultipleViewControllerDelegate {
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        title = "New Event"
        tableView.contentInset.top = 10
        tableView.contentInset.bottom = 50
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextButtonPressed))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonPressed))
        
        AdvancedEvent.sharedInstance.clear()
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
    
    // MARK: Private
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private lazy var zeroRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {_ in
            }.configure {
                $0.rowHeight = 0
        }
    }()
    
    private func configure() {
        
        // Create RowFomers
        
        let detailsRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = "What's an advanced event?"
            $0.date = ""
            $0.body = "Advanced events can be used when its required to collect extra information about a user and/or registration for an event is required.\nIn the next steps you will be able to dynamically specify which details you wish to collect by creating a registration form."
            $0.titleColor = MAIN_COLOR
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }
        
        let titleRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.textField.textColor = UIColor.black
            $0.textField.font = .systemFont(ofSize: 15)
            }.configure {
                $0.placeholder = "Event Title"
            }.onTextChanged {
                AdvancedEvent.sharedInstance.title = $0
        }
        let locationRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.textField.textColor = UIColor.black
            $0.textField.font = .systemFont(ofSize: 15)
            }.configure {
                $0.placeholder = "Location"
            }.onTextChanged {
                AdvancedEvent.sharedInstance.location = $0
        }
        
        let endRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
            $0.titleLabel.text = "End"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.displayLabel.textColor = .formerSubColor()
            $0.displayLabel.font = .systemFont(ofSize: 15)
            AdvancedEvent.sharedInstance.end = NSDate()
            }.inlineCellSetup {
                $0.datePicker.datePickerMode = .dateAndTime
            }.onDateChanged {
                AdvancedEvent.sharedInstance.end = $0 as NSDate!
            }.displayTextFromDate(String.mediumDateShortTime)
        
        let startRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
            $0.titleLabel.text = "Start"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.displayLabel.textColor = .formerSubColor()
            $0.displayLabel.font = .systemFont(ofSize: 15)
            AdvancedEvent.sharedInstance.start = NSDate()
            }.inlineCellSetup {
                $0.datePicker.datePickerMode = .dateAndTime
            }.onDateChanged {
                AdvancedEvent.sharedInstance.start = $0 as NSDate!
            }.displayTextFromDate(String.mediumDateShortTime)
    
        let allDayRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = "All-day"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.switchButton.onTintColor = MAIN_COLOR
            }.onSwitchChanged { on in
                startRow.update {
                    $0.displayTextFromDate(
                        on ? String.mediumDateNoTime : String.mediumDateShortTime
                    )
                }
                startRow.inlineCellUpdate {
                    $0.datePicker.datePickerMode = on ? .date : .dateAndTime
                }
                endRow.update {
                    $0.displayTextFromDate(
                        on ? String.mediumDateNoTime : String.mediumDateShortTime
                    )
                }
                endRow.inlineCellUpdate {
                    $0.datePicker.datePickerMode = on ? .date : .dateAndTime
                }
        }
        let urlRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.textField.textColor = UIColor.black
            $0.textField.font = .systemFont(ofSize: 15)
            $0.textField.keyboardType = .alphabet
            }.configure {
                $0.placeholder = "URL"
            }.onTextChanged {
                AdvancedEvent.sharedInstance.url = $0
        }
        let noteRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = UIColor.black
            $0.textView.font = .systemFont(ofSize: 15)
            }.configure {
                $0.placeholder = "Notes"
                $0.rowHeight = 250
            }.onTextChanged {
                AdvancedEvent.sharedInstance.info = $0
        }
        let inviteRow = createMenu("Notify Others") { [weak self] in
            self?.former.deselect(animated: true)
            let vc = SelectMultipleViewController()
            vc.delegate = self
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.barTintColor = MAIN_COLOR!
            self?.present(navVC, animated: true, completion: nil)
        }
        
        // Create SectionFormers
        
        let titleSection = SectionFormer(rowFormer: titleRow, locationRow)
        let dateSection = SectionFormer(rowFormer: allDayRow, startRow, endRow)
        let noteSection = SectionFormer(rowFormer: urlRow, noteRow)
        
        former.append(sectionFormer: SectionFormer(rowFormer: detailsRow), titleSection, SectionFormer(rowFormer: zeroRow),SectionFormer(rowFormer: inviteRow),dateSection, noteSection).onCellSelected { [weak self] _ in
            self?.formerInputAccessoryView.update()
        }
        
    }
    
    // MARK: User actions
    func cancelButtonPressed(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func nextButtonPressed(sender: AnyObject) {
        /* Data Check
        if AdvancedEvent.sharedInstance.title! != "" {
            if !AdvancedEvent.sharedInstance.start!.isInPast() {
                
            } else {
                // Event in the past
                let banner = Banner(title: "Invalid Input", subtitle: "Event start date is in the past.", image: nil, backgroundColor: MAIN_COLOR)
                banner.dismissesOnTap = true
                banner.show(duration: 1.0)
            }
            
        } else {
            // Event name empty
            let banner = Banner(title: "Invalid Input", subtitle: "Event name cannot be empty.", image: nil, backgroundColor: MAIN_COLOR)
            banner.dismissesOnTap = true
            banner.show(duration: 1.0)
        }
        */
        self.navigationController?.pushViewController(CreateFormForEventViewController(), animated: true)
    }
    
    func didSelectMultipleUsers(selectedUsers: [PFUser]!) {
        
        // Returns current user in selectedUsers so they must be removed
        var inviteUsers = selectedUsers
        let index = inviteUsers?.index(of: PFUser.current()!)
        inviteUsers?.remove(at: index!)
        self.former.remove(section: 2)
        Event.sharedInstance.inviteTo = selectedUsers
        let userRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = "Send Notification To:"
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
        self.former.insert(sectionFormer: SectionFormer(rowFormer: userRow), toSection: 2)
        self.former.reload()
    }
}

