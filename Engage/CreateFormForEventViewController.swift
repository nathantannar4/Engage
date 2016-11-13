//
//  CreateFormForEventViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-19.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse
import SVProgressHUD
import BRYXBanner

final class CreateFormForEventViewController: FormViewController {
    
    var templateName = ""
    var stringInputs = [String]()
    let templateNames = ["", "Name", "Contact Info", "Birthday", "Gender", "Emergency Contact", "Yes/No Question", "Multiple Choice Question", "Multiple Selection Question", "Text Input", "Paragraph Input", "Number Input", "Date Input", "Image Attachment"]
    var rowCounter = 0
    var activeRows = [Bool]()
    var rowTitles = [String]()
    var rowSubTitles = [String]()
    var rowType = [Int]() // TextField, TextView, DateSelection, MultipleChoice, MultipleSelection, Image, Segment
    var rowDataType = [Int]() // String, Number, Date, Array, File
    //var selectionOptionsArray = [String]()[String]()
    
    private enum `Type` {
        case TextField, TextView, DateSelection, MultipleChoice, MultipleSelection, Image, Segment
        func code() -> Int {
            switch self {
            case .TextField: return 1
            case .TextView: return 2
            case .DateSelection: return 3
            case .MultipleChoice: return 4
            case .MultipleSelection: return 5
            case .Image: return 6
            case .Segment: return 7
            }
        }
    }
    
    private enum DataType {
        case String, Number, Date, Array, File
        func code() -> Int {
            switch self {
            case .String: return 1
            case .Number: return 2
            case .Date: return 3
            case .Array: return 4
            case .File: return 5
            }
        }
    }
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        title = "New Form"
        tableView.contentInset.top = 10
        tableView.contentInset.bottom = 50
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextButtonPressed))
        
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
    
    private func configure() {
        
        // Create RowFomers
        let tipsRow = CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = "Entry Examples"
            $0.date = ""
            $0.body = "Common entries for registration forms include: preferred names, birthday, email, gender, emergency contact and/or survey questions. Choose what kind of entries you wish to include from the templates below or create your own."
            $0.titleColor = MAIN_COLOR
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }
        
        let templateSelectionRow = InlinePickerRowFormer<FormInlinePickerCell, Any>(){
            $0.titleLabel.text = "Entries"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.displayLabel.textColor = .formerSubColor()
            $0.displayLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.pickerItems = templateNames.map {
                    InlinePickerItem(title: $0)
                }
                $0.selectedRow = 0
            }.onValueChanged {
                self.templateName = $0.title
        }
        let addTemplateRow = CustomRowFormer<TitleCell>() {
            $0.titleLabel.text = "Add Selected Entry"
            $0.titleLabel.textAlignment = .center
            
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                let templateSelected = self!.templateName
                if templateSelected != "" {
                    let index = self!.templateNames.index(of: templateSelected)!
                    switch index {
                    case 1:
                        // Name
                        self!.former.insertUpdate(sectionFormer: self!.createEntrySection(rows: self!.createTextEntry(inputLabels: ["First", "Last"]), name: templateSelected), toSection: self!.former.sectionFormers.count, rowAnimation: .fade)
                    case 2:
                        // Contact Info
                        self!.former.insertUpdate(sectionFormer: self!.createEntrySection(rows: self!.createTextEntry(inputLabels: ["Email", "Phone"]), name: templateSelected), toSection: self!.former.sectionFormers.count, rowAnimation: .fade)
                    case 3:
                        // Birthday
                        self!.former.insertUpdate(sectionFormer: self!.createEntrySection(rows: self!.createDateEntry(inputLabels: ["Birthday"]), name: templateSelected), toSection: self!.former.sectionFormers.count, rowAnimation: .fade)
                    case 4:
                        // Gender
                        self!.former.insertUpdate(sectionFormer: self!.createEntrySection(rows: self!.createMultipleChoiceEntry(question: "Gender", info: "", options: ["Male", "Female", "Neither"]), name: templateSelected), toSection: self!.former.sectionFormers.count, rowAnimation: .fade)
                    case 5:
                        // Emergency Contact
                        var rows = self!.createTextEntry(inputLabels: ["First", "Last", "Relationship"])
                        rows.append(self!.createNumberEntry(inputLabel: "Phone"))
                        self!.former.insertUpdate(sectionFormer: self!.createEntrySection(rows: rows, name: templateSelected), toSection: self!.former.sectionFormers.count, rowAnimation: .fade)
                    case 6:
                        // Yes/No Question
                        self!.createQuestion(templateSelected: templateSelected)
                    case 7:
                        // Multiple Choice Question
                        self!.createQuestion(templateSelected: templateSelected)
                    case 8:
                        // Multiple Selection Question
                        self!.createQuestion(templateSelected: templateSelected)
                    case 9:
                        // Text Input
                        self!.createInput(templateSelected: templateSelected)
                    case 10:
                        // Paragraph Input
                        self!.createInput(templateSelected: templateSelected)
                    case 11:
                        // Number Input
                        self!.createInput(templateSelected: templateSelected)
                    case 12:
                        // Date Input
                        self!.createInput(templateSelected: templateSelected)
                    case 13:
                        // Image Attachment
                        self!.createInput(templateSelected: templateSelected)
                    default: break
                    }
                }
        }
        
        // Create SectionFormers
        let tipsSection = SectionFormer(rowFormer: tipsRow)
        let entrySelectionSection = SectionFormer(rowFormer: templateSelectionRow, addTemplateRow)
        
        self.former.append(sectionFormer: tipsSection, entrySelectionSection)
    }
    
    private func createTextEntry(inputLabels: [String]) -> [RowFormer] {
        var rows = [TextFieldRowFormer<ProfileFieldCell>]()
        for label in inputLabels {
            rowTitles.append(label)
            rowSubTitles.append("")
            rowType.append(Type.TextField.code())
            rowDataType.append(DataType.String.code())
            rows.append(TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) {
                $0.titleLabel.text = label
                })
        }
        return rows
    }
    
    private func createParagraphEntry(inputLabel: String) -> RowFormer {
        rowTitles.append(inputLabel)
        rowSubTitles.append("")
        rowType.append(Type.TextView.code())
        rowDataType.append(DataType.String.code())
        rowCounter += 1
        return TextViewRowFormer<FormTextViewCell>() { [weak self] in
            $0.titleLabel.textColor = MAIN_COLOR
            $0.textView.font = .systemFont(ofSize: 15)
            $0.textView.inputAccessoryView = self?.formerInputAccessoryView
            }.configure {
                $0.placeholder = inputLabel
                $0.rowHeight = 300
        }
    }
    
    private func createNumberEntry(inputLabel: String) -> RowFormer {
        rowTitles.append(inputLabel)
        rowSubTitles.append("")
        rowType.append(Type.TextField.code())
        rowDataType.append(DataType.Number.code())
        rowCounter += 1
        return(TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = inputLabel
            $0.textField.keyboardType = .numberPad
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            })
    }
    
    private func createDateEntry(inputLabels: [String]) -> [RowFormer] {
        var rows = [InlineDatePickerRowFormer<FormInlineDatePickerCell>]()
        for label in inputLabels {
            rowTitles.append(label)
            rowSubTitles.append("")
            rowType.append(Type.DateSelection.code())
            rowDataType.append(DataType.Date.code())
            rowCounter += 1
            rows.append(InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
                $0.titleLabel.text = label
                $0.titleLabel.font = .boldSystemFont(ofSize: 15)
                $0.titleLabel.textColor = MAIN_COLOR
                $0.displayLabel.textColor = .formerSubColor()
                $0.displayLabel.font = .systemFont(ofSize: 15)
                }.inlineCellSetup {
                    $0.datePicker.datePickerMode = .date
                }.displayTextFromDate(String.mediumDateNoTime))
        }
        return rows
    }
    
    private func createMultipleChoiceEntry(question: String, info: String, options: [String]) -> [RowFormer] {
        var rows = [RowFormer]()
        rowTitles.append(question)
        rowSubTitles.append(info)
        rowType.append(Type.MultipleChoice.code())
        rowDataType.append(DataType.Array.code())
        // SAVE options
        rowCounter += 1
        rows.append(CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = question
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.date = ""
            $0.body = info
            $0.titleColor = MAIN_COLOR
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected({_ in
                self.former.deselect(animated: true)
            }))
        rows.append(InlinePickerRowFormer<FormInlinePickerCell, Any>() {
            $0.titleLabel.text = "Response"
            $0.titleLabel.textColor = MAIN_COLOR
            $0.displayLabel.textColor = .formerSubColor()
            $0.displayLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.pickerItems = options.map {
                    InlinePickerItem(title: $0)
                }
                $0.selectedRow = 0
            })
        return rows
    }
    
    private func createMultipleSelectionEntry(question: String, info: String, options: [String]) -> [RowFormer] {
        var rows = [RowFormer]()
        rowTitles.append(question)
        rowSubTitles.append(info)
        rowType.append(Type.MultipleSelection.code())
        rowDataType.append(DataType.Array.code())
        // SAVE options
        rowCounter += 1
        rows.append(CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = question
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.date = ""
            $0.body = info
            $0.titleColor = MAIN_COLOR
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            })
        for option in options {
            rows.append(CheckRowFormer<FormCheckCell>{
                $0.titleLabel.text = option
                })
        }
        return rows
    }
    
    private func createYesNoEntry(question: String, info: String, options: [String]) -> [RowFormer] {
        var rows = [RowFormer]()
        rowTitles.append(question)
        rowSubTitles.append(info)
        rowType.append(Type.Segment.code())
        rowDataType.append(DataType.Array.code())
        // SAVE options
        rowCounter += 1
        rows.append(CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.title = question
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.date = ""
            $0.body = info
            $0.titleColor = MAIN_COLOR
            $0.selectionStyle = .none
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            })
        rows.append(SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Response"
            $0.titleLabel.font = .systemFont(ofSize: 15)
            $0.titleLabel.textColor = UIColor.gray
            $0.segmentedControl.tintColor = MAIN_COLOR
            }.configure {
                $0.segmentTitles = options
                $0.selectedIndex = UISegmentedControlNoSegment
            })
        return rows
    }
    
    private func createImageAttachment(inputLabel: String) -> RowFormer {
        rowTitles.append(inputLabel)
        rowSubTitles.append("")
        rowType.append(Type.Image.code())
        rowDataType.append(DataType.File.code())
        rowCounter += 1
        return LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
            $0.iconView.backgroundColor = MAIN_COLOR
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .systemFont(ofSize: 15)
            }.configure {
                $0.text = inputLabel
                $0.rowHeight = 60
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                let banner = Banner(title: nil, subtitle: "Image selection will be available when the form is live.", image: nil, backgroundColor: MAIN_COLOR!)
                banner.dismissesOnTap = true
                banner.show(duration: 1.0)
        }
    }
    
    private func createEntrySection(rows: [RowFormer], name: String) -> SectionFormer {
        let section = SectionFormer(rowFormers: rows).set(headerViewFormer: TableFunctions.createHeader(text: name))
        let deleteEntry = CustomRowFormer<TitleCell>() {
            $0.titleLabel.text = "Delete Entry"
            $0.titleLabel.textAlignment = .center
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                // Create range of data removal
                
                /*
                var rowsToRemove = 1
                if (name == "Name") || (name == "Contact Info") {
                    rowsToRemove = 2
                } else if name == "Emergency Contact" {
                    rowsToRemove = 4
                }
                
                for row in 0...rowsToRemove {
                    self!.rowTitles.removeAtIndex(row)
                }
                
                
                var rowIndex = -1
                for sectionIndex in 2...(self!.former.sectionFormers.count - 1) {
                    rowIndex += self!.former.sectionFormers[sectionIndex].numberOfRows
                }
                print(rowIndex)
                 */
                
                self?.former.removeUpdate(sectionFormer: section)
        }
        section.append(rowFormer: deleteEntry)
        return section
    }
    
    private func createQuestion(templateSelected: String) {
        let actionSheetController: UIAlertController = UIAlertController(title: "", message: nil, preferredStyle: .alert)
        actionSheetController.view.tintColor = MAIN_COLOR
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Do some stuff
        }
        actionSheetController.addAction(cancelAction)
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "Add", style: .default) { action -> Void in
            var input = actionSheetController.textFields![0].text!
            if input != "" {
                input = input.lowercased()
                input = input.capitalized
                if !input.contains("?") {
                    input.append("?")
                }
                if templateSelected == "Yes/No Question" {
                    self.former.insertUpdate(sectionFormer: self.createEntrySection(rows: self.createYesNoEntry(question: input, info: actionSheetController.textFields![1].text!, options: ["Yes", "No"]), name: templateSelected), toSection: self.former.sectionFormers.count, rowAnimation: .fade)
                } else {
                    var responses = actionSheetController.textFields![2].text!
                    var responseArray = [""]
                    if templateSelected == "Multiple Selection Question" {
                        responseArray.removeAll()
                    }
                    while responses.contains(",") {
                        while responses[responses.startIndex] == " " {
                            // Remove leading spaces
                            responses.remove(at: responses.startIndex)
                        }
                        // Find comma
                        let index = responses.characters.index(of: ",")
                        // Create string to comma
                        let stringToAdd = responses.substring(to: index!).capitalized
                        print("Adding: \(stringToAdd)")
                        if stringToAdd != "" {
                            // Ignore double commas example: one,,three
                            responseArray.append(stringToAdd)
                        }
                        responses = responses.replacingOccurrences(of: stringToAdd + ",", with: "")
                        print(responses)
                    }
                    while responses[responses.startIndex] == " " {
                        // Remove leading spaces
                        responses.remove(at: responses.startIndex)
                    }
                    if responses != "" {
                        // Ignore double commas example: one,,three
                        responseArray.append(responses)
                    }
                    if templateSelected == "Multiple Selection Question" {
                        self.former.insertUpdate(sectionFormer: self.createEntrySection(rows: self.createMultipleSelectionEntry(question: input, info: actionSheetController.textFields![1].text!, options: responseArray), name: templateSelected), toSection: self.former.sectionFormers.count, rowAnimation: .fade)
                    } else if templateSelected == "Multiple Choice Question" {
                        self.former.insertUpdate(sectionFormer: self.createEntrySection(rows: self.createMultipleChoiceEntry(question: input, info: actionSheetController.textFields![1].text!, options: responseArray), name: templateSelected), toSection: self.former.sectionFormers.count, rowAnimation: .fade)
                    }
                    
                }
            } else {
                SVProgressHUD.showError(withStatus: "Invalid Entry")
                
            }
        }
        actionSheetController.addAction(nextAction)
        //Add a text field
        actionSheetController.addTextField { textField -> Void in
            //TextField configuration
            textField.placeholder = "Question"
        }
        actionSheetController.addTextField { textField -> Void in
            //TextField configuration
            textField.placeholder = "Extra Info (Optional)"
        }
        if templateSelected != "Yes/No Question" {
            actionSheetController.addTextField { textField -> Void in
                //TextField configuration
                textField.placeholder = "Responses separated with a comma"
            }
        }
        actionSheetController.popoverPresentationController?.sourceView = self.view
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    private func createInput(templateSelected: String) {
        let actionSheetController: UIAlertController = UIAlertController(title: "", message: nil, preferredStyle: .alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Do some stuff
        }
        actionSheetController.addAction(cancelAction)
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "Add", style: .default) { action -> Void in
            var input = actionSheetController.textFields![0].text!
            if input != "" {
                input = input.lowercased()
                input = input.capitalized
                if templateSelected == "Text Input" {
                    self.former.insertUpdate(sectionFormer: self.createEntrySection(rows: self.createTextEntry(inputLabels: [input]), name: templateSelected), toSection: self.former.sectionFormers.count, rowAnimation: .fade)
                } else if templateSelected == "Paragraph Input" {
                    self.former.insertUpdate(sectionFormer: self.createEntrySection(rows: [self.createParagraphEntry(inputLabel: input)], name: templateSelected), toSection: self.former.sectionFormers.count, rowAnimation: .fade)
                } else if templateSelected == "Number Input" {
                    self.former.insertUpdate(sectionFormer: self.createEntrySection(rows: [self.createNumberEntry(inputLabel: input)], name: templateSelected), toSection: self.former.sectionFormers.count, rowAnimation: .fade)
                } else if templateSelected == "Date Input" {
                    self.former.insertUpdate(sectionFormer: self.createEntrySection(rows: self.createDateEntry(inputLabels: [input]), name: templateSelected), toSection: self.former.sectionFormers.count, rowAnimation: .fade)
                } else if templateSelected == "Image Attachment" {
                    self.former.insertUpdate(sectionFormer: self.createEntrySection(rows: [self.createImageAttachment(inputLabel: input)], name: templateSelected), toSection: self.former.sectionFormers.count, rowAnimation: .fade)
                }
            } else {
                SVProgressHUD.showError(withStatus: "Invalid Entry")
            }
        }
        actionSheetController.addAction(nextAction)
        //Add a text field
        actionSheetController.addTextField { textField -> Void in
            //TextField configuration
            textField.placeholder = "Title"
        }
        actionSheetController.popoverPresentationController?.sourceView = self.view
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    // MARK: User actions
    
    func nextButtonPressed(sender: AnyObject) {
        if rowTitles.count > 0 {
            for i in 0...(rowTitles.count - 1) {
                print(rowTitles[i])
                print(rowSubTitles[i])
                print(rowType[i])
                print(rowDataType[i])
            }

        }
    }
}
