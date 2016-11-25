//
//  SponsorDetailViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 10/15/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import Parse
import Former
import Agrume
import SVProgressHUD
import MessageUI
import JSQWebViewController
import Material

class SponsorDetailViewController: FormViewController, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate  {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI and Table Properties
        title = EngagementSubGroup.sharedInstance.name!
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 120
        if Engagement.sharedInstance.admins.contains(PFUser.current()!.objectId!) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings"), style: .plain, target: self, action: #selector(settingsButtonPressed))
        }
        
        configure()
    }
    
    private func configure() {
        let websiteRow = createMenu("View Sponsors Website") { [weak self] in
            if EngagementSubGroup.sharedInstance.url != "" {
                let controller = WebViewController(url: NSURL(string: "http://\(EngagementSubGroup.sharedInstance.url!)")! as URL)
                self?.present(controller, animated: true, completion: nil)

            }
        }
        self.former.append(sectionFormer: SectionFormer(rowFormer: onlyImageRow, infoRow, websiteRow))
        self.former.reload()
    }
    
    // MARK: - Table Rows
    
    private lazy var onlyImageRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {
            $0.displayImage.file = EngagementSubGroup.sharedInstance.subgroup![PF_SUBGROUP_COVER_PHOTO] as? PFFile
            $0.displayImage.loadInBackground()
            $0.displayImage.contentMode = UIViewContentMode.scaleAspectFill
            }.configure {
                $0.rowHeight = 200
            }.onSelected({ _ in
                if EngagementSubGroup.sharedInstance.coverPhoto != nil {
                    let agrume = Agrume(image: EngagementSubGroup.sharedInstance.coverPhoto!)
                    agrume.showFrom(self)
                }
            })
    }()
    
    private lazy var infoRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Info"
            $0.body = EngagementSubGroup.sharedInstance.info!
            $0.titleLabel.font = RobotoFont.medium(with: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = RobotoFont.regular(with: 15)
            $0.date = ""
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }
    }()
    
    private lazy var urlRow: CustomRowFormer<DynamicHeightCell> = {
        CustomRowFormer<DynamicHeightCell>(instantiateType: .Nib(nibName: "DynamicHeightCell")) {
            $0.selectionStyle = .none
            $0.title = "Website"
            $0.body = EngagementSubGroup.sharedInstance.url
            $0.date = ""
            $0.bodyColor = UIColor.black
            $0.titleLabel.font = RobotoFont.medium(with: 15)
            $0.titleLabel.textColor = MAIN_COLOR
            $0.bodyLabel.font = RobotoFont.regular(with: 15)
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
            }.onSelected { _ in
                if EngagementSubGroup.sharedInstance.url != "" {
                    let controller = WebViewController(url: NSURL(string: "http://\(EngagementSubGroup.sharedInstance.url!)")! as URL)
                    let nav = UINavigationController(rootViewController: controller)
                    nav.navigationBar.barTintColor = MAIN_COLOR
                    self.present(nav, animated: true, completion: nil)
                }
        }
    }()
    
    // MARK: - User actions
    
    func settingsButtonPressed(sender: UIBarButtonItem) {
        self.navigationController?.pushViewController(EditSubGroupViewController(), animated: true)
    }
    
    // Update Rows after editing
    
    func updateRows() {
        EngagementSubGroup.sharedInstance.unpack()
        infoRow.cellUpdate {
            $0.bodyLabel.text = EngagementSubGroup.sharedInstance.info
        }
        self.former.reload()
    }
    
    let createMenu: ((String, (() -> Void)?) -> RowFormer) = { text, onSelected in
        return LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 16)
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}


