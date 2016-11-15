//
//  SubGroupsViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-13.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse
import Agrume
import SVProgressHUD
import Material

class SubGroupsViewController: FormViewController {
        var firstLoad = true
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 50
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        prepareToolbar()
        EngagementSubGroup.sharedInstance.clear()
        appMenuController.menu.views.first?.isHidden = true
        if firstLoad {
            SVProgressHUD.show(withStatus: "Loading")
            firstLoad = false
        } else {
            SVProgressHUD.show(withStatus: "Refreshing")
            self.refresh(sender: self)
        }
    }
    
    private func prepareToolbar() {
        guard let tc = toolbarController else {
            return
        }
        if Engagement.sharedInstance.subGroupName != "" {
            tc.toolbar.title = Engagement.sharedInstance.subGroupName
        } else {
            tc.toolbar.title = "Subgroups"
        }
        tc.toolbar.detail = ""
        tc.toolbar.backgroundColor = MAIN_COLOR
        let addButton = IconButton(image: Icon.cm.add)
        addButton.tintColor = UIColor.white
        addButton.addTarget(self, action: #selector(createSubGroup), for: .touchUpInside)
        appToolbarController.prepareToolbarMenu(right: [addButton])
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
    
    func refresh(sender:AnyObject) {
        // Updating your data here...
        if self.former.sectionFormers.count > 0 {
            self.former.removeAll()
            configure()
        }
    }
    
    // MARK: Private
    
    private func configure() {
        
        var subGroupRows = [RowFormer]()
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        let subGroupQuery = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_\(PF_SUBGROUP_CLASS_NAME)")
        subGroupQuery.order(byAscending: PF_SUBGROUP_NAME)
        subGroupQuery.findObjectsInBackground { (subGroups: [PFObject]?, error: Error?) in
            UIApplication.shared.endIgnoringInteractionEvents()
            if error == nil {
                for subGroup in subGroups! {
                    subGroupRows.append(self.createMenu(subGroup[PF_SUBGROUP_NAME] as! String) { [weak self] in
                        self?.former.deselect(animated: true)
                        // Transition to SubGroup page
                        EngagementSubGroup.sharedInstance.clear()
                        EngagementSubGroup.sharedInstance.subgroup = subGroup
                        EngagementSubGroup.sharedInstance.unpack()
                        appToolbarController.push(from: self!, to: SubGroupDetailViewController())
                    })
                }
                if Engagement.sharedInstance.subGroupName != "" {
                    self.former.append(sectionFormer: SectionFormer(rowFormers: subGroupRows).set(headerViewFormer: TableFunctions.createHeader(text: "\(Engagement.sharedInstance.name!) \(Engagement.sharedInstance.subGroupName!)")))
                } else {
                    self.former.append(sectionFormer: SectionFormer(rowFormers: subGroupRows).set(headerViewFormer: TableFunctions.createHeader(text: "\(Engagement.sharedInstance.name!) Sub Groups")))
                }
                self.former.reload()
                SVProgressHUD.dismiss()
            } else {
                print(error.debugDescription)
                SVProgressHUD.showError(withStatus: "Network Error")
            }
        }
    }
    
    // MARK: User Actions
    
    func createSubGroup() {
        let navVC = UINavigationController(rootViewController: CreateSubGroupViewController())
        navVC.navigationBar.barTintColor = MAIN_COLOR!
        appToolbarController.present(navVC, animated: true, completion: nil)
    }
}
