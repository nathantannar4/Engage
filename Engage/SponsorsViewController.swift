//
//  SponsorsViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 10/15/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import Former
import Parse
import Agrume
import SVProgressHUD
import Material

class SponsorsViewController: FormViewController {
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        title = "Sponsors"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.cm.menu, style: .plain, target: self, action: #selector(leftDrawerButtonPressed))
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 50
        if Engagement.sharedInstance.admins.contains(PFUser.current()!.objectId!) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Plus"), style: .plain, target: self, action: #selector(createSubGroup))
        }
        
        SVProgressHUD.show(withStatus: "Loading")
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
        subGroupQuery.whereKey(PF_SUBGROUP_IS_SPONSOR, equalTo: true)
        subGroupQuery.findObjectsInBackground { (subGroups: [PFObject]?, error: Error?) in
            UIApplication.shared.endIgnoringInteractionEvents()
            if error == nil {
                for subGroup in subGroups! {
                    subGroupRows.append(LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
                        $0.displayImage.file = subGroup[PF_SUBGROUP_COVER_PHOTO] as? PFFile
                        $0.displayImage.loadInBackground()
                        $0.displayImage.contentMode = UIViewContentMode.scaleAspectFill
                        }.configure {
                            $0.rowHeight = 200
                        })
                    subGroupRows.append(self.createMenu(subGroup[PF_SUBGROUP_NAME] as! String) { [weak self] in
                        self?.former.deselect(animated: true)
                        // Transition to SubGroup page
                        EngagementSubGroup.sharedInstance.clear()
                        EngagementSubGroup.sharedInstance.subgroup = subGroup
                        EngagementSubGroup.sharedInstance.unpack()
                        self!.navigationController?.pushViewController(SponsorDetailViewController(), animated: true)
                    })
                }
                if Engagement.sharedInstance.subGroupName != "" {
                    self.former.append(sectionFormer: SectionFormer(rowFormers: subGroupRows).set(headerViewFormer: TableFunctions.createHeader(text: "\(Engagement.sharedInstance.name!) Sponsors")))
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
    
    func createSubGroup(sender: UIBarButtonItem) {
        let vc = CreateSubGroupViewController()
        vc.isSponsor = true
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.barTintColor = MAIN_COLOR!
        self.present(navVC, animated: true, completion: nil)
    }
    
    func leftDrawerButtonPressed() {
        self.evo_drawerController?.toggleDrawerSide(.left, animated: true, completion: nil)
    }
}
