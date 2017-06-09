//
//  EditGroupViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 6/8/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents
import Agrume

class EditGroupViewController: NTFormViewController, NTNavigationViewControllerDelegate {
    
    var group: Group
    
    // MARK: - Cells 
    
    lazy var nameCell: NTFormCell = { [weak self] in
        let cell = NTFormAnimatedInputCell()
        cell.textField.font = Font.Default.Subtitle.withSize(24)
        cell.textField.textFieldInsets = CGPoint(x: 0, y: -4)
        cell.onTextFieldUpdate({ (textField) in
            self?.group.name = textField.text
        })
        return cell
        }()
    
    lazy var infoCell: NTFormCell = { [weak self] in
        let cell = NTFormLongInputCell()
        cell.title = "Info"
        cell.text = self?.group.info
        cell.onTextViewUpdate({ (textView) in
            self?.group.info = textView.text
        })
        return cell
    }()
    
    lazy var urlCell: NTFormCell = { [weak self] in
        let cell = NTFormInputCell()
        cell.title = "URL"
        cell.text = self?.group.url
        cell.onTextFieldUpdate({ (textField) in
            self?.group.url = textField.text
        })
        return cell
    }()
    
    lazy var emailCell: NTFormCell = { [weak self] in
        let cell = NTFormInputCell()
        cell.title = "Email"
        cell.text = self?.group.email
        cell.onTextFieldUpdate({ (textField) in
            self?.group.email = textField.text
        })
        return cell
    }()
    
    lazy var logoPhotoCell: NTFormCell = { [weak self] in
        let cell = NTFormImageSelectorCell()
        cell.actionButton.title = "Select Logo from Photo Library"
        cell.image = self?.group.image
        cell.onImageViewTap({ (imageView) in
            guard let image = imageView.image, let this = self else { return }
            Agrume(image: image, backgroundBlurStyle: UIBlurEffectStyle.dark, backgroundColor: Color.Gray.P800.withAlpha(newAlpha: 0.3)).showFrom(this)
        })
        cell.onTouchUpInsideActionButton({ (button) in
            cell.presentImagePicker(completion: { (image) in
                self?.group.image = image
            })
        })
        return cell
    }()
    
    lazy var coverPhotoCell: NTFormCell = { [weak self] in
        let cell = NTFormImageViewCell()
        cell.actionButton.isHidden = false
        cell.image = self?.group.coverImage
        cell.actionButton.backgroundColor = Color.Default.Background.Button
        cell.actionButton.tintColor = .white
        cell.actionButton.alpha = 1
        cell.separatorLineView.isHidden = false
        cell.onImageViewTap({ (imageView) in
            guard let image = imageView.image, let this = self else { return }
            Agrume(image: image, backgroundBlurStyle: UIBlurEffectStyle.dark, backgroundColor: Color.Gray.P800.withAlpha(newAlpha: 0.3)).showFrom(this)
        })
        cell.onTouchUpInsideActionButton({ (button) in
            cell.presentImagePicker(completion: { (image) in
                self?.group.coverImage = image
            })
        })
        return cell
    }()
    
    func save() {
        guard let name = group.name else {
            NTPing(type: .isInfo, title: "Please enter a name for your group").show()
            return
        }
        if name.isEmpty {
            NTPing(type: .isInfo, title: "Please enter a name for your group").show()
            return
        }
        let progress = NTProgressHUD()
        if group.createdAt == nil {
            // New Group
            let action = NTActionSheetItem(title: "Create \(group.name!)", icon: Icon.Check, iconTint: .white, color: Color.Default.Tint.View, action: {
                progress.show(withTitle: "Creating")
                if self.group is Engagement {
                    (self.group as! Engagement).create(completion: { (success) in
                        if success {
                            DispatchQueue.executeAfter(2, closure: {
                                NTPing(type: .isSuccess, title: "Group Created").show()
                                progress.dismiss()
                                self.dismiss(animated: true, completion: nil)
                            })
                        }
                    })
                } 
            })
            let actionSheet = NTActionSheetViewController(title: nil, subtitle: nil, actions: [action])
            actionSheet.addDismissAction(withText: "Cancel", icon: Icon.Delete, color: Color.Gray.P100)
            actionSheet.show(self, sender: nil)
        } else {
            progress.show(withTitle: "Saving")
            group.save(completion: { (success) in
                if success {
                    NTPing(type: .isSuccess, title: "Group Updated").show()
                    progress.dismiss()
                    self.dismiss(animated: true, completion: nil)
                }
            })
        }
    }
    
    
    // MARK: - Initialization
    
    init(fromGroup grp: Group) {
        group = grp
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Standard Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = group.name != nil ? "Edit \(group.name!)" : "Create Group"
        navigationViewController?.delegate = self
        navigationViewController?.nextButton.image = Icon.Check
        
        let photoSection = NTFormSection(fromRows: [coverPhotoCell, logoPhotoCell], withHeaderTitle: "Images", withFooterTitle: nil)
        let infoSection = NTFormSection(fromRows: [infoCell, urlCell, emailCell], withHeaderTitle: "Info", withFooterTitle: nil)
        appendSections([photoSection, infoSection])
        
        if group.createdAt == nil {
            // New Group
            insertSection(NTFormSection(fromRows: [nameCell], withHeaderTitle: "Name", withFooterTitle: nil), atIndex: 1)
        }
        
        reloadForm()
    }
    
    // MARK: - NTNavigationViewControllerDelegate
    
    func nextViewController(_ navigationViewController: NTNavigationViewController) -> UIViewController? {
        return UIViewController()
    }
    
    func navigationViewController(_ navigationViewController: NTNavigationViewController, shouldMoveTo viewController: UIViewController) -> Bool {
        save()
        return false
    }
}
