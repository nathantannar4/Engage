//
//  FeedViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-12.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse
import Agrume
import SVProgressHUD
import Photos

class FeedViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var refreshControl: UIRefreshControl!
    var editorViewable = false
    var querySkip = 0
    let button = UIButton(type: .custom)
    var rowCounter = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UI
        title = "Activity Feed"
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 50
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(FeedViewController.refresh(sender:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
        addButton()
        buttonToImage()
        self.navigationController?.navigationBar.barTintColor = MAIN_COLOR!
        
        
        
        Profile.sharedInstance.user = PFUser.current()
        Profile.sharedInstance.loadUser()
        Post.new.clear()
        
        let zeroRow = LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")).configure {
            $0.rowHeight = 0
        }
        
        let zeroSection = SectionFormer(rowFormer: zeroRow)
        self.former.append(sectionFormer: zeroSection)
        self.former.reload()
        
        insertPosts()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.revealViewController().frontViewPosition.rawValue == 4 {
            self.revealViewController().revealToggle(self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        button.backgroundColor = MAIN_COLOR
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
    
    func refresh(sender:AnyObject)
    {
        // Updating your data here...
        UIApplication.shared.beginIgnoringInteractionEvents()
        former.removeAllUpdate(rowAnimation: .fade)
        self.refreshControl?.endRefreshing()
        rowCounter = 0
        querySkip = 0
        let zeroRow = LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")).configure {
            $0.rowHeight = 0
        }
        
        let zeroSection = SectionFormer(rowFormer: zeroRow)
        self.former.append(sectionFormer: zeroSection)
        self.former.reload()
        insertPosts()
        Post.new.clear()
        buttonToImage()
        imageRow.cellUpdate {
            $0.iconView.image = nil
        }
    }
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        Post.new.clear()
        self.former.remove(section: 0)
        self.former.reload()
        
        imageRow.cellUpdate {
            $0.iconView.image = nil
        }
        buttonToImage()
    }
    
    func postButtonPressed(sender: UIBarButtonItem) {
        
        if !editorViewable {
            buttonToText()
            Post.new.clear()
            tableViewScrollToTop(animated: true)
            let infoRow = TextViewRowFormer<FormTextViewCell>() { [weak self] in
                $0.textView.textColor = .formerSubColor()
                $0.textView.font = .systemFont(ofSize: 15)
                $0.textView.inputAccessoryView = self?.formerInputAccessoryView
                }.configure {
                    $0.placeholder = "What's new?"
                    $0.text = Post.new.info
                }.onTextChanged {
                    Post.new.info = $0
            }
            
            let newPostSection = SectionFormer(rowFormer: infoRow, imageRow).set(headerViewFormer: TableFunctions.createHeader(text: "Create Post"))
            
            self.former.insert(sectionFormer: newPostSection, toSection: 0)
                .onCellSelected { [weak self] _ in
                    self?.formerInputAccessoryView.update()
            }
            self.former.reload()
            
        } else if Post.new.info != ""{
            Post.new.createPost(object: nil, completion: {
                self.former.remove(section: 0)
                self.former.reload()
                self.buttonToImage()
                self.imageRow.cellUpdate {
                    $0.iconView.image = nil
                }
                self.refresh(sender: self)
            })
        }
    }
    
    // MARK: Private
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private lazy var imageRow: LabelRowFormer<ProfileImageCell> = {
        LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
            $0.iconView.image = Post.new.image
            }.configure {
                $0.text = "Add image to post"
                $0.rowHeight = 60
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                self?.presentImagePicker()
        }
    }()
    
    private lazy var loadMoreSection: SectionFormer = {
        let loadMoreRow = CustomRowFormer<TitleCell>(instantiateType: .Nib(nibName: "TitleCell")) {
            $0.titleLabel.text = "Load More"
            $0.titleLabel.textAlignment = .center
            $0.titleLabel.textColor = MAIN_COLOR
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            }.onSelected { [weak self] _ in
                self?.former.deselect(animated: true)
                self!.querySkip += 10
                self!.insertPosts()
        }
        return SectionFormer(rowFormer: loadMoreRow)
    }()
    
    private func insertPosts() {
        
        SVProgressHUD.show(withStatus: "Loading")
        let query = PFQuery(className: "\(Engagement.sharedInstance.name!.replacingOccurrences(of: " ", with: "_"))_Posts")
        query.limit = 10
        query.skip = self.querySkip
        query.order(byDescending: "createdAt")
        query.includeKey(PF_POST_USER)
        query.includeKey(PF_POST_TO_OBJECT)
        query.includeKey(PF_POST_TO_USER)
        query.findObjectsInBackground { (posts: [PFObject]?, error: Error?) in
            UIApplication.shared.endIgnoringInteractionEvents()
            SVProgressHUD.dismiss()
            if error == nil && (posts?.count)! > 0 {
                for post in posts! {
                    if (post[PF_POST_HAS_IMAGE] as? Bool) == true {
                        self.former.insertUpdate(rowFormer: TableFunctions.createFeedCellPhoto(user: post[PF_POST_USER] as! PFUser, post: post, nav: self.navigationController!), toIndexPath: IndexPath(row: self.rowCounter, section: 0), rowAnimation: .fade)
                        self.rowCounter += 1
                    } else {
                        self.former.insertUpdate(rowFormer: TableFunctions.createFeedCell(user: post[PF_POST_USER] as! PFUser, post: post, nav: self.navigationController!), toIndexPath: IndexPath(row: self.rowCounter, section: 0), rowAnimation: .fade)
                        self.rowCounter += 1
                    }
                }
                if self.querySkip == 0 {
                    self.former.insertUpdate(sectionFormer: self.loadMoreSection.set(footerViewFormer: TableFunctions.createFooter(text: "Engage - Version: \(VERSION)")), toSection: 1)
                } else {
                    self.tableView.scrollToRow(at: IndexPath(row: self.querySkip, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
                }
            } else {
                print(error)
                SVProgressHUD.showError(withStatus: "Network Error")
            }
        }
    }
    
    // MARK: - UITableView functions
    
    func tableViewScrollToTop(animated: Bool) {
        
        let numberOfSections = self.tableView.numberOfSections
        let numberOfRows = self.tableView.numberOfRows(inSection: numberOfSections-1)
        
        if numberOfRows > 0 {
            let indexPath = NSIndexPath(row: 0, section: 0) as IndexPath
            self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: animated)
        }
    }
    
    // MARK: - UIImagePickerDelegate
    
    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            Post.new.image = image
            Post.new.hasImage = true
            imageRow.cellUpdate {
                $0.iconView.image = image
            }
        } else{
            print("Something went wrong")
            SVProgressHUD.showError(withStatus: "An Error Occurred")
        }
    }
    
    func addButton() {
        button.frame = CGRect(x: self.view.frame.width - 100, y: self.view.frame.height - 175, width: 65, height: 65)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.backgroundColor = MAIN_COLOR
        buttonToImage()
        button.addTarget(self, action: #selector(postButtonPressed), for: .touchUpInside)
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOpacity = 1.0
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 4
        view.addSubview(button)
    }
    
    func buttonToImage() {
        editorViewable = false
        let tintedImage = Images.resizeImage(image: UIImage(named:"Plus-512.png")!, width: 60, height: 60)!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        button.tintColor = UIColor.white
        button.setImage(tintedImage, for: .normal)
        button.setTitle("", for: .normal)
        self.navigationItem.rightBarButtonItem = nil
    }
    
    func buttonToText() {
        editorViewable = true
        button.setImage(UIImage(), for: .normal)
        button.setTitle("Post", for: .normal)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonPressed))
    }
}
