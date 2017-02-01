//
//  NewPostViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/15/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import ParseUI

class NewPostViewController: NTTableViewController, NTTableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    var image: UIImage?
    var text: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Create Post"
        self.subtitle = "To Everyone"
        self.dataSource = self
        self.tableView.emptyHeaderHeight = 30
        self.tableView.cellSeperationHeight = 10
        self.tableView.contentInset.top = 70
        self.tableView.contentInset.bottom = 100
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.Google.check, style: .plain, target: self, action: #selector(saveButtonPressed(sender:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Google.close, style: .plain, target: self, action: #selector(cancelButtonPressed(sender:)))
    }
    
    func saveButtonPressed(sender: UIBarButtonItem) {
        let post = Post(text: self.text, image: self.image)
        post.upload { (success) in
            if success {
                Cache.add(post)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: User Actions
    
    func addImageToPost(sender: UIButton) {
        let picker = UIImagePickerController()
        picker.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
        picker.navigationBar.tintColor = self.navigationController?.navigationBar.tintColor
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        self.present(picker, animated: true, completion: nil)
    }
    
    func removeImageFromPost(sender: UIButton) {
        self.image = nil
        self.reloadData()
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.image = image
            self.reloadData()
        } else{
            Toast.genericErrorMessage()
        }
    }
    
    // MARK: NTTableViewDataSource
    
    func tableView(_ tableView: NTTableView, cellForHeaderInSection section: Int) -> NTHeaderCell? {
        let header = NTHeaderCell.initFromNib()
        header.titleLabel.removeFromSuperview()
        if self.image == nil {
            header.actionButton.setTitle("Add Image", for: .normal)
            header.actionButton.addTarget(self, action: #selector(addImageToPost(sender:)), for: .touchUpInside)
        } else {
            header.actionButton.setTitle("Remove Image", for: .normal)
            header.actionButton.addTarget(self, action: #selector(removeImageFromPost(sender:)), for: .touchUpInside)
        }
        header.actionButton.sizeToFit()
        header.bounds = header.actionButton.bounds
        return header
    }
    
    func numberOfSections(in tableView: NTTableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        return 1 + (self.image != nil ? 1 : 0)
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        if indexPath.row == 0 {
            let cell = NTTextViewCell.initFromNib()
            cell.setDefaults()
            cell.placeholder = "What's new \(User.current().fullname!)?"
            if self.text != nil {
                cell.text = self.text
            }
            cell.textView.delegate = self
            return cell
        } else if indexPath.row == 1 {
            let cell = NTImageCell.initFromNib()
            cell.setDefaults()
            cell.contentImageView.layer.borderWidth = 2
            cell.contentImageView.layer.borderColor = UIColor.white.cgColor
            cell.contentImageView.layer.cornerRadius = 5
            cell.image = self.image
            return cell
        } else {
            return NTTableViewCell()
        }
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = String()
        textView.textColor = UIColor.black
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            self.text = nil
            textView.text = "What's new \(User.current().fullname!)?"
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.text = textView.text
    }
}
