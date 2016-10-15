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

class SubGroupsViewController: FormViewController {
        var firstLoad = true
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 50
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Plus"), style: .plain, target: self, action: #selector(createSubGroup))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Plus"), style: .plain, target: self, action: #selector(createSubGroup))
        
        configure()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.revealViewController().frontViewPosition.rawValue == 4 {
            self.revealViewController().revealToggle(self)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if revealViewController() != nil {
            let menuButton = UIBarButtonItem()
            menuButton.image = UIImage(named: "ic_menu_black_24dp")
            menuButton.target = revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.navigationItem.leftBarButtonItem = menuButton
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            tableView.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        if Engagement.sharedInstance.subGroupName != "" {
            title = Engagement.sharedInstance.subGroupName
        } else {
            title = "Subgroups"
        }
        
        EngagementSubGroup.sharedInstance.clear()
        if firstLoad {
            SVProgressHUD.show(withStatus: "Loading")
            firstLoad = false
        } else {
            SVProgressHUD.show(withStatus: "Refreshing")
            self.refresh(sender: self)
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
                        let subGroupVC = SubGroupDetailViewController()
                        self!.navigationController?.pushViewController(subGroupVC, animated: true)
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
                print(error)
                SVProgressHUD.showError(withStatus: "Network Error")
            }
        }
    }
    
    // MARK: User Actions
    
    func createSubGroup(sender: UIBarButtonItem) {
        let navVC = UINavigationController(rootViewController: CreateSubGroupViewController())
        navVC.navigationBar.barTintColor = MAIN_COLOR!
        self.present(navVC, animated: true, completion: nil)
    }
}
