//
//  EditEventViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-09-19.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse
import SVProgressHUD

final class EditEventViewController: FormViewController {
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        title = "Edit Event"
        tableView.contentInset.top = 10
        tableView.contentInset.bottom = 50
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveButtonPressed))
        
        Event.sharedInstance.unpack()
        configure()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
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
    
    private lazy var deleteSection: SectionFormer = {
        let removePhotoRow = CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.text = "Delete Post"
            $0.titleLabel.textAlignment = .center
            }.onSelected { _ in
                self.former.deselect(animated: true)
                let actionSheetController: UIAlertController = UIAlertController(title: "Delete Event?", message: nil, preferredStyle: .actionSheet)
                actionSheetController.view.tintColor = MAIN_COLOR
                
                let cancelAction: UIAlertAction = UIAlertAction(title: "No", style: .cancel) { action -> Void in
                    //Just dismiss the action sheet
                }
                actionSheetController.addAction(cancelAction)
                
                let yesAction: UIAlertAction = UIAlertAction(title: "Yes", style: .default) { action -> Void in
                    Event.sharedInstance.object!.deleteInBackground { (success: Bool, error: Error?) in
                        if success {
                            SVProgressHUD.showSuccess(withStatus: "Event Deleted")
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            SVProgressHUD.showError(withStatus: "Network Error")
                        }
                    }
                }
                actionSheetController.addAction(yesAction)
                
                //Present the AlertController
                self.present(actionSheetController, animated: true, completion: nil)

        }
        return SectionFormer(rowFormer: removePhotoRow)
    }()
    
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
                $0.text = Event.sharedInstance.title
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
                $0.date = Event.sharedInstance.end! as Date
            }.inlineCellSetup {
                $0.datePicker.datePickerMode = .dateAndTime
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
                $0.date = Event.sharedInstance.end! as Date
            }.inlineCellSetup {
                $0.datePicker.datePickerMode = .dateAndTime
            }.onDateChanged {
                Event.sharedInstance.start = $0 as NSDate!
            }.displayTextFromDate(String.mediumDateShortTime)
        
        let allDayRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = "All-day"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.switchButton.onTintColor = MAIN_COLOR
            }.configure {
                $0.switched = Event.sharedInstance.allDay
                if Event.sharedInstance.allDay {
                    startRow.update {
                        $0.displayTextFromDate(
                            String.mediumDateNoTime
                        )
                    }
                    startRow.inlineCellUpdate {
                        $0.datePicker.datePickerMode = .date
                    }
                    endRow.update {
                        $0.displayTextFromDate(
                            String.mediumDateNoTime
                        )
                    }
                    endRow.inlineCellUpdate {
                        $0.datePicker.datePickerMode = .date
                    }
                }
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
                $0.text = Event.sharedInstance.url
            }.onTextChanged {
                Event.sharedInstance.url = $0
        }
        let noteRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = UIColor.black
            $0.textView.font = .systemFont(ofSize: 15)
            }.configure {
                $0.placeholder = "Notes"
                $0.rowHeight = 250
                $0.text = Event.sharedInstance.info
            }.onTextChanged {
                Event.sharedInstance.info = $0
        }
        
        // Create SectionFormers
        
        let titleSection = SectionFormer(rowFormer: titleRow, locationRow, locationPickerRow)
        let dateSection = SectionFormer(rowFormer: allDayRow, startRow, endRow)
        let _ = SectionFormer(rowFormer: repeatRow)
        let noteSection = SectionFormer(rowFormer: urlRow, noteRow)
        
        former.append(sectionFormer: titleSection, SectionFormer(rowFormer: zeroRow), dateSection, noteSection, deleteSection).onCellSelected { [weak self] _ in
            self?.formerInputAccessoryView.update()
        }
        former.reload()
    }
    
    // MARK: User actions
    
    func saveButtonPressed(sender: AnyObject) {
        Event.sharedInstance.save()
    }
}
