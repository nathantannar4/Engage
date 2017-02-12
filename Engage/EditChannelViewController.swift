//
//  EditChannelViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2/9/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import Former
import Agrume


class EditChannelViewController: NTTableViewController, UserSelectionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var channel: Channel!
    private var isEditingChannel = false
    
    // MARK: - Initializers
    public convenience init(channel: Channel) {
        self.init()
        self.channel = channel
    }
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.channel.isPrivate! ? self.channel.name : "#" + self.channel.name!
        
        if let admins = self.channel.admins {
            if admins.contains(User.current().id) && self.channel.isPrivate! {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleEditing))
            }
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Google.close, style: .plain, target: self, action: #selector(cancelButtonPressed(sender:)))
        
        self.tableView.separatorStyle = .singleLine
        self.tableView.contentInset.bottom = 100
    }
    
    // MARK: User Actions
    
    func toggleEditing() {
        self.isEditingChannel = !self.isEditingChannel
        if self.isEditingChannel {
            self.subtitle = "Edit"
            self.navigationItem.setRightBarButton(UIBarButtonItem(image: Icon.Google.check, style: .plain, target: self, action: #selector(saveButtonPressed(sender:))), animated: true)
        } else {
            self.subtitle = nil
            self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleEditing)), animated: true)
        }
    }
    
    func saveButtonPressed(sender: UIBarButtonItem) {
        Log.write(.status, "Save button pressed")
        self.channel.save { (success) in
            if success {
                let toast = Toast(text: "Group Updated", button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 2.0)
                self.toggleEditing()
            }
        }
    }
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        if self.isEditingChannel {
            self.channel.undoModifications()
            self.toggleEditing()
            self.tableView.reloadData()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 1 {
            return UITableViewAutomaticDimension
        }
        return 50
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && !self.channel.isPrivate! {
            return 0
        }
        return 30
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.textLabel?.textColor = UIColor.black
        if section == 0 && self.channel.isPrivate! {
            header.textLabel?.text = "Customization"
            return header
        } else if section == 1 {
            header.textLabel?.text = "Members"
            return header
        } else {
            return nil
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // Customization
            return self.channel.isPrivate! ? 2 : 0
        } else if section == 1 {
            // Members
            return self.channel.members?.count ?? 0
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = UITableViewCell()
                cell.textLabel?.text = "Select group icon from library"
                cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
                cell.textLabel?.textColor = Color.defaultNavbarTint
                cell.imageView?.image = self.channel.image?.cropToSquare()
                cell.imageView?.contentMode = .scaleAspectFit
                cell.imageView?.layer.cornerRadius = 25
                cell.imageView?.layer.borderWidth = 1
                cell.imageView?.layer.borderColor = Color.defaultNavbarTint.cgColor
                cell.imageView?.layer.masksToBounds = true
                return cell
            } else if indexPath.row == 1 {
                let cell = UITableViewCell()
                cell.textLabel?.text = "Change group name"
                cell.textLabel?.textColor = Color.defaultNavbarTint
                cell.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightMedium)
                return cell
            }
        } else if indexPath.section == 1 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.accessoryType = .disclosureIndicator
            cell.tintColor = Color.defaultNavbarTint
            
            let user = Cache.retrieveUser(self.channel.members![indexPath.row])
            
            cell.textLabel?.text = user?.fullname
            if self.channel.admins!.contains(user!.id) {
                cell.detailTextLabel?.text = "Admin"
                cell.detailTextLabel?.textColor = Color.darkGray
            }
            cell.imageView?.image = user?.image?.cropToSquare()
            cell.imageView?.contentMode = .scaleAspectFit
            cell.imageView?.layer.cornerRadius = 25
            cell.imageView?.layer.borderWidth = 1
            cell.imageView?.layer.borderColor = Color.defaultNavbarTint.cgColor
            cell.imageView?.layer.masksToBounds = true
            return cell
        }
        return UITableViewCell()
    }
    
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 {
            if self.channel.admins!.contains(User.current().id) {
                if self.channel.members![indexPath.row] !=  User.current().id {
                    return self.isEditingChannel
                }
            }
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                self.presentImagePicker()
            } else if indexPath.row == 1 {
                let actionSheetController: UIAlertController = UIAlertController(title: "Rename Group", message: "", preferredStyle: .alert)
                actionSheetController.view.tintColor = Color.defaultNavbarTint
                
                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
                actionSheetController.addAction(cancelAction)
                
                let nextAction: UIAlertAction = UIAlertAction(title: "Rename", style: .default) { action -> Void in
                    
                    let textField = actionSheetController.textFields![0]
                    if let text = textField.text {
                        self.channel.name = text
                        self.channel.save(completion: { (success) in
                            if success {
                                self.title = self.channel.isPrivate! ? self.channel.name : "#" + self.channel.name!
                            }
                        })
                    } else {
                        let toast = Toast(text: "Cancelled", button: nil, color: Color.darkGray, height: 44)
                        toast.show(duration: 1.0)
                    }
                }
                actionSheetController.addAction(nextAction)
                
                actionSheetController.addTextField { textField -> Void in
                    textField.placeholder = self.channel.name
                }
                actionSheetController.popoverPresentationController?.sourceView = self.view
                
                self.present(actionSheetController, animated: true, completion: nil)
            }
        }
        
        if indexPath.section == 1 {
            if let user = Cache.retrieveUser(self.channel.members![indexPath.row]) {
                let vc = ProfileViewController(user: user)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: .normal, title: "Remove") { action, index in
            if let user = Cache.retrieveUser(self.channel.members![index.row]) {
                self.channel.leave(user: user, completion: { (success) in
                    if success {
                        self.tableView.deleteRows(at: [index], with: .fade)
                    }
                })
            }
        }
        remove.backgroundColor = UIColor.red
        
        if indexPath.section == 1 {
            return [remove]
        }
        return nil
    }
    
    // MARK: UserSelectionDelegate
    
    func didMakeSelection(ofUsers users: [User]) {
        
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        self.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            var imageToBeSaved = image
            picker.dismiss(animated: true, completion: nil)
            
            if image.size.width > 500 {
                let resizeFactor = 500 / image.size.width
                imageToBeSaved = image.resizeImage(width: resizeFactor * image.size.width, height: resizeFactor * image.size.height, renderingMode: .alwaysOriginal)
            }
            
            let toast = Toast(text: "Uploading Image...", button: nil, color: Color.darkGray, height: 44)
            toast.show(duration: 1.0)
            let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(imageToBeSaved, 0.6)!)
            pictureFile!.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error != nil {
                    Log.write(.error, error.debugDescription)
                    Toast.genericErrorMessage()
                }
            }
            
            let channel = self.channel.object
            channel[PF_CHANNEL_IMAGE] = pictureFile
            channel.saveInBackground { (succeeded: Bool, error:
                Error?) -> Void in
                if error != nil {
                    Log.write(.error, error.debugDescription)
                    Toast.genericErrorMessage()
                }
                else {
                    let toast = Toast(text: "Image Uploaded", button: nil, color: Color.darkGray, height: 44)
                    toast.dismissOnTap = true
                    toast.show(duration: 1.0)
                    
                    self.channel.image = imageToBeSaved
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                }
            }
            
        } else{
            Log.write(.error, "Could not present image picker")
            Toast.genericErrorMessage()
        }
    }
}


