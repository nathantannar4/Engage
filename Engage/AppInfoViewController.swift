//
//  AppInfoViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-11.
//  Copyright © 2016 NathanTannar. All rights reserved.
//


import UIKit
import Former
import Parse
import Agrume
import JSQWebViewController
import BWWalkthrough

final class AppInfoViewController: FormViewController, BWWalkthroughViewControllerDelegate {
    
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset.top = 10
        tableView.contentInset.bottom = 100
        
        configure()
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
        title = "About Engage"
        tableView.contentInset.top = 10
        tableView.contentInset.bottom = 100
        
        // Create RowFomers
        
        
        let githubRow = createMenu("View Code on GitHub") { [weak self] in
            self?.former.deselect(animated: true)
            let controller = WebViewController(url: NSURL(string: "https://github.com/nathantannar4/Engage")! as URL)
            let nav = UINavigationController(rootViewController: controller)
            nav.navigationBar.barTintColor = MAIN_COLOR
            self!.present(nav, animated: true, completion: nil)
        }
        let walkthroughRow = createMenu("View Walkthrough") { [weak self] in
            self?.former.deselect(animated: true)
            let stb = UIStoryboard(name: "Walkthrough", bundle: nil)
            let walkthrough = stb.instantiateViewController(withIdentifier: "walk") as! BWWalkthroughViewController
            let page_zero = stb.instantiateViewController(withIdentifier: "walk0")
            let page_one = stb.instantiateViewController(withIdentifier: "walk1")
            let page_two = stb.instantiateViewController(withIdentifier: "walk2")
            let page_three = stb.instantiateViewController(withIdentifier: "walk3")
            
            // Attach the pages to the master
            walkthrough.delegate = self
            walkthrough.addViewController(page_one)
            walkthrough.addViewController(page_two)
            walkthrough.addViewController(page_three)
            walkthrough.addViewController(page_zero)
            
            self?.present(walkthrough, animated: true, completion: nil)
        }
        
        let licenseRow = createMenu("View Licenses/Acknowledgements") { [weak self] in
            self?.former.deselect(animated: true)
            let licensingViewController = LicensingViewController()
            
            licensingViewController.title = ""
            
            let parseItem = LicensingItem(
                title: "Parse",
                license: License.mit(owner: "Parse", years: "2016")
            )
            
            let formerItem = LicensingItem(
                title: "Former",
                license: License.mit(owner: "Ryo Aoyama (https://github.com/ra1028/Former)", years: "2015")
            )
            
            let messagesItem = LicensingItem(
                title: "JSQMessagesController",
                license: License.mit(owner: "Jessie Squires (https://github.com/jessesquires/JSQMessagesViewController)", years: "2015")
            )
            
            let webItem = LicensingItem(
                title: "JSQWebViewController",
                license: License.mit(owner: "Jessie Squires (https://github.com/jessesquires/JSQWebViewController)", years: "2016")
            )
            
            let bannerItem = LicensingItem(
                title: "BRYX Banner",
                license: License.mit(owner: "Harlan Haskins (https://github.com/bryx-inc/BRYXBanner)", years: "2015")
            )
            
            let agrumeItem = LicensingItem(
                title: "Agrume",
                license: License.mit(owner: "Jan Gorman (https://github.com/JanGorman/Agrume)", years: "2015")
            )
            
            let progressItem = LicensingItem(
                title: "SVProgressHUD",
                license: License.mit(owner: "Sam Vermette (https://github.com/SVProgressHUD/SVProgressHUD)", years: "2016")
            )
            
            let walkthroughItem = LicensingItem(
                title: "BWWalkthrough",
                license: License.mit(owner: "Yari D'areglia (https://github.com/ariok/BWWalkthrough)", years: "2016")
            )
            
            let colorItem = LicensingItem(
                title: "Chameleon",
                license: License.mit(owner: "Vicc Alexander (https://github.com/ViccAlexander/Chameleon)", years: "2016")
            )
            
            let textItem = LicensingItem(
                title: "TextFieldEffects",
                license: License.mit(owner: "Raul Riera (https://github.com/raulriera/TextFieldEffects)", years: "2016")
            )
            
            
            
            licensingViewController.items = [parseItem, formerItem, messagesItem, webItem, bannerItem, agrumeItem, progressItem, walkthroughItem, colorItem, textItem]
            self?.navigationController?.pushViewController(licensingViewController, animated: true)
        }
        
        
        // Create SectionFormers
        
        self.former.append(sectionFormer: SectionFormer(rowFormer: githubRow, walkthroughRow, licenseRow).set(footerViewFormer: TableFunctions.createFooter(text: "Engage - Version: \(VERSION)")))
        self.former.reload()
    }
    
    func walkthroughCloseButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }

}
