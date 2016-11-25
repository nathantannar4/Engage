//
//  CreateSimpleEventViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-13.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse
import Material

final class CreateSimpleEventViewController: FormViewController, SelectMultipleViewControllerDelegate {
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        self.navigationItem.titleView = Utilities.setTitle(title: "Create", subtitle: "New Event")
        tableView.contentInset.top = 10
        tableView.contentInset.bottom = 50
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.cm.check, style: .plain, target: self, action: #selector(createButtonPressed))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.cm.close, style: .plain, target: self, action: #selector(cancelButtonPressed))
        
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationRow.cellUpdate { (cell) in
            cell.titleLabel.text = Event.sharedInstance.location
        }
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
    
    private enum Repeat {
        case Never, Daily, Weekly, Monthly, Yearly
        func title() -> String {
            switch self {
            case .Never: return "Never"
            case .Daily: return "Daily"
            case .Weekly: return "Weekly"
            case .Monthly: return "Monthly"
            case .Yearly: return "Yearly"
            }
        }
        static func values() -> [Repeat] {
            return [Daily, Weekly, Monthly, Yearly]
        }
    }
    
    private enum Alert {
        case None, AtTime, Five, Thirty, Hour, Day, Week
        func title() -> String {
            switch self {
            case .None: return "None"
            case .AtTime: return "At time of event"
            case .Five: return "5 minutes before"
            case .Thirty: return "30 minutes before"
            case .Hour: return "1 hour before"
            case .Day: return "1 day before"
            case .Week: return "1 week before"
            }
        }
        static func values() -> [Alert] {
            return [AtTime, Five, Thirty, Hour, Day, Week]
        }
    }
    
    private lazy var locationRow: CustomRowFormer<TitleCell> = {
        CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.text = Event.sharedInstance.location
            $0.titleLabel.textAlignment = .left
            $0.titleLabel.textColor = UIColor.black
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.selectionStyle = .none
        }
    }()

    private func configure() {
        
        // Create RowFomers
        
        let titleRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.textField.textColor = UIColor.black
            $0.textField.font = .systemFont(ofSize: 15)
            }.configure {
                $0.placeholder = "Event Title"
            }.onTextChanged {
                Event.sharedInstance.title = $0
        }
    
        let locationPickerRow = createMenu("Choose Location") {
            self.former.deselect(animated: true)
            let vc = LocationPickerViewController()
            vc.searchBarStyle = .default
            vc.mapType = .standard
            let navVC = UINavigationController(rootViewController: vc)
            navVC.navigationBar.barTintColor = MAIN_COLOR!
            self.present(navVC, animated: true)
        }
    
        let endRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
            $0.titleLabel.text = "End"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.displayLabel.textColor = .formerSubColor()
            $0.displayLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.date = Event.sharedInstance.start as! Date
            }.inlineCellSetup {
                $0.datePicker.datePickerMode = .dateAndTime
                $0.datePicker.date = Event.sharedInstance.start as! Date
            }.onDateChanged {
                Event.sharedInstance.end = $0 as NSDate!
            }.displayTextFromDate(String.mediumDateShortTime)
        
        let startRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
            $0.titleLabel.text = "Start"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.displayLabel.textColor = .formerSubColor()
            $0.displayLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.date = Event.sharedInstance.start as! Date
            }.inlineCellSetup {
                $0.datePicker.datePickerMode = .dateAndTime
            }.onDateChanged {
                Event.sharedInstance.start = $0 as NSDate!
                if (Event.sharedInstance.start?.isLaterThanDate(Event.sharedInstance.end as! Date))! {
                    endRow.update {
                        $0.date = Event.sharedInstance.start as! Date
                    }
                }
            }.displayTextFromDate(String.mediumDateShortTime)
        
        let allDayRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = "All-day"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.switchButton.onTintColor = MAIN_COLOR
            }.onSwitchChanged { on in
                Event.sharedInstance.allDay = on
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
        let repeatRow = InlinePickerRowFormer<FormInlinePickerCell, Repeat>() {
            $0.titleLabel.text = "Repeat"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.displayLabel.textColor = .formerSubColor()
            $0.displayLabel.font = .systemFont(ofSize: 15)
            }.configure {
                let never = Repeat.Never
                $0.pickerItems.append(
                    InlinePickerItem(title: never.title(),
                        displayTitle: NSAttributedString(string: never.title(),
                            attributes: [NSForegroundColorAttributeName: UIColor.lightGray]),
                        value: never)
                )
                $0.pickerItems += Repeat.values().map {
                    InlinePickerItem(title: $0.title(), value: $0)
                }
        }
        /*
        let alertRow = InlinePickerRowFormer<FormInlinePickerCell, Alert>() {
            $0.titleLabel.text = "Alert"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFontOfSize(15)
            $0.displayLabel.textColor = .formerSubColor()
            $0.displayLabel.font = .systemFontOfSize(15)
            }.configure {
                let none = Alert.None
                $0.pickerItems.append(
                    InlinePickerItem(title: none.title(),
                        displayTitle: NSAttributedString(string: none.title(),
                            attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()]),
                        value: none)
                )
                $0.pickerItems += Alert.values().map {
                    InlinePickerItem(title: $0.title(), value: $0)
                }
        }
        */
        
        let urlRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.textField.textColor = UIColor.black
            $0.textField.font = .systemFont(ofSize: 15)
            $0.textField.keyboardType = .alphabet
            }.configure {
                $0.placeholder = "URL"
            }.onTextChanged {
                Event.sharedInstance.url = $0
        }
        let noteRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = UIColor.black
            $0.textView.font = .systemFont(ofSize: 15)
            }.configure {
                $0.placeholder = "Notes"
                $0.rowHeight = 250
            }.onTextChanged {
                Event.sharedInstance.info = $0
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
        
        let titleSection = SectionFormer(rowFormer: titleRow, locationRow, locationPickerRow)
        let dateSection = SectionFormer(rowFormer: allDayRow, startRow, endRow)
        let _ = SectionFormer(rowFormer: repeatRow)
        let noteSection = SectionFormer(rowFormer: urlRow, noteRow)
        
        former.append(sectionFormer: titleSection, SectionFormer(rowFormer: zeroRow), SectionFormer(rowFormer: inviteRow), dateSection, noteSection).onCellSelected { [weak self] _ in
            self?.formerInputAccessoryView.update()
        }

    }
    
    // MARK: User actions
    func cancelButtonPressed(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createButtonPressed(sender: AnyObject) {
        Event.sharedInstance.create(completion: {
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func didSelectMultipleUsers(selectedUsers: [PFUser]!) {
        
        // Returns current user in selectedUsers so they must be removed
        var inviteUsers = selectedUsers
        let index = inviteUsers?.index(of: PFUser.current()!)
        inviteUsers?.remove(at: index!)
        self.former.remove(section: 1)
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
        self.former.insert(sectionFormer: SectionFormer(rowFormer: userRow), toSection: 1)
        self.former.reload()
    }

}
