//
//  RegisterViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 9/30/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import TextFieldEffects
import Parse
import SVProgressHUD
import JSQWebViewController

class RegisterViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: YoshikoTextField!
    @IBOutlet weak var passwordTextField: YoshikoTextField!
    @IBOutlet weak var passwordAgainTextField: YoshikoTextField!
    @IBOutlet weak var nameTextField: YoshikoTextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    
    internal var validEmail = false
    internal var validPassword = false
    internal var validPasswordAgain = false
    internal var validName = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prepare Form
        self.prepareForm()
    }
    
    // MARK: - User Actions
    @IBAction func registerButtonPressed(_ sender: AnyObject) {
        self.dismissKeyboard()
        
        // Freeze user interaction
        SVProgressHUD.show(withStatus: "Registering")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // Create new user
        let user = PFUser()
        user.username = emailTextField.text!
        user.email = emailTextField.text!
        user.password = passwordTextField.text!
        user[PF_USER_FULLNAME] = nameTextField.text!
        user[PF_USER_FULLNAME_LOWER] = nameTextField.text!.lowercased()
        user[PF_USER_BLOCKED] = []
        user[PF_USER_ENGAGEMENTS] = []
        user[PF_USER_PHONE] = ""
        
        // Save new user
        user.signUpInBackground { (succeeded, error) -> Void in
            UIApplication.shared.endIgnoringInteractionEvents()
            if error == nil {
                
                SVProgressHUD.showSuccess(withStatus: "Success")
                
                // Cache user
                Profile.sharedInstance.user = user
                Profile.sharedInstance.loadUser()
                
                // Visual representation of a successful login
                self.textFieldsTo(color: UIColor.flatGreen())
                
                // Add a deley before showing next view for design purposes
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    
                    if !isWESST {
                        Utilities.userLoggedIn(self)
                    } else {
                        let engagementsQuery = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
                        engagementsQuery.whereKey(PF_ENGAGEMENTS_NAME, equalTo: "WESST")
                        engagementsQuery.findObjectsInBackground { (engagements: [PFObject]?, error: Error?) in
                            if error == nil {
                                let engagement = engagements?.first
                                // Send to Group
                                Engagement.sharedInstance.engagement = engagement
                                Engagement.sharedInstance.unpack()
                                if !Engagement.sharedInstance.members.contains(PFUser.current()!.objectId!) {
                                    Engagement.sharedInstance.join(newUser: PFUser.current()!)
                                }
                                Utilities.showEngagement(self, animated: false)
                            }
                        }
                    }
                }
            } else {
                SVProgressHUD.showError(withStatus: "Error")
                print(error.debugDescription)
            }
        }
    }
    
    @IBAction func showTerms(_ sender: AnyObject) {
        // Create HTML based text view controller for the EULA agreement
        let vc = EULAViewController()
        vc.view.backgroundColor = self.tableView.backgroundColor
        let label = UITextView(frame: vc.view.frame)
        vc.view.addSubview(label)
        if let filepath = Bundle.main.path(forResource: "EULA", ofType: "html") {
            do {
                let str = try NSAttributedString(data: String(contentsOfFile: filepath)
                    .data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType], documentAttributes: nil)
                label.textColor = MAIN_COLOR
                label.attributedText = str
                let navVC = UINavigationController(rootViewController: vc)
                navVC.navigationBar.barTintColor = MAIN_COLOR
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "icn_arrow_down"), style: .plain, target: vc, action: #selector(vc.dismissView(sender:)))
                self.present(navVC, animated: true, completion: nil)
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        self.navigationController!.popToRootViewController(animated: true)
    }
    
    // MARK: - UITextFieldDelegate methods
    
    internal func textFieldDidChange(sender: AnyObject) {
        
        // Highlight text field colors based on valid entries
        let textField = sender as! UITextField
        if textField.placeholder == "Email" {
            if isValidEmail(testStr: emailTextField.text!) {
                self.validEmail = false
                let emailQuery = PFQuery(className: PF_USER_CLASS_NAME)
                emailQuery.whereKey(PF_USER_EMAIL, equalTo: emailTextField.text!)
                emailQuery.findObjectsInBackground(block: { (users, error) in
                    if users?.count == 0 {
                        self.validEmail = true
                        self.textFieldTo(color: UIColor.flatGreen(), textField: self.emailTextField)
                    } else {
                        self.textFieldTo(color: UIColor.flatRed(), textField: self.emailTextField)
                    }
                })
            } else {
                self.textFieldTo(color: MAIN_COLOR!, textField: self.emailTextField)
            }
        }
        if textField.placeholder == "Password" {
            if passwordTextField.text!.characters.count >= 6 {
                validPassword = true
            } else {
                validPassword = false
            }
            self.textFieldTo(color: MAIN_COLOR!, textField: self.passwordAgainTextField)
            if passwordAgainTextField.text != "" {
                passwordAgainTextField.text = ""
            }
        }
        if textField.placeholder == "Password Again" {
            if passwordTextField.text! == passwordAgainTextField.text! {
                validPasswordAgain = true
                self.textFieldTo(color: UIColor.flatGreen(), textField: self.passwordAgainTextField)
            } else if passwordTextField.text! == "" {
                validPasswordAgain = false
                self.textFieldTo(color: MAIN_COLOR!, textField: self.passwordAgainTextField)
            } else {
                validPasswordAgain = false
                self.textFieldTo(color: UIColor.flatRed(), textField: self.passwordAgainTextField)
            }
        }
        if textField.placeholder == "Name" {
            if nameTextField.text!.characters.count >= 2 {
                validName = true
            } else {
                validName = false
            }
        }
        if (validEmail && validPassword && validPasswordAgain && validName) {
            // Activate button when both login fields have possible valid strings
            self.registerButton.setTitleColor(MAIN_COLOR, for: .normal)
            self.registerButton.layer.borderColor = MAIN_COLOR?.cgColor
            self.registerButton.layer.borderWidth = 1.0
            self.registerButton.isEnabled = true
        } else {
            // Disable login button to prevent useless login calls
            self.registerButton.setTitleColor(UIColor.darkGray, for: .normal)
            self.registerButton.layer.borderWidth = 0.0
            self.registerButton.isEnabled = false
        }
    }
    
    private func addToolBar(textField: UITextField){
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = MAIN_COLOR
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(dismissKeyboard))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        toolBar.sizeToFit()
        textField.delegate = self
        textField.inputAccessoryView = toolBar
    }
    
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.dismissKeyboard()
        return true
    }
    
    // MARK: - Form Functions
    private func prepareForm() {
        
        self.prepareTextFields()
        
        registerButton.setTitleColor(UIColor.darkGray, for: .normal)
        registerButton.isEnabled = false
        
        cancelButton.setTitleColor(MAIN_COLOR, for: .normal)
        cancelButton.layer.borderColor = MAIN_COLOR?.cgColor
        cancelButton.layer.borderWidth = 1.0
        
        termsButton.setTitleColor(MAIN_COLOR, for: .normal)
        termsButton.setSubstituteFontName("Avenir Next")
    }
    
    private func prepareTextFields() {
        for textField in [self.emailTextField, self.passwordTextField, self.passwordAgainTextField, self.nameTextField] {
            textField!.addTarget(self, action: #selector(RegisterViewController.textFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
            self.textFieldTo(color: MAIN_COLOR!, textField: textField!)
        }
    }
    
    private func textFieldsTo(color: UIColor) {
        self.emailTextField.activeBorderColor = color
        self.emailTextField.textColor = color
        self.passwordTextField.activeBorderColor = color
        self.passwordTextField.textColor = color
        self.passwordAgainTextField.activeBorderColor = color
        self.passwordAgainTextField.textColor = color
        self.nameTextField.activeBorderColor = color
        self.nameTextField.textColor = color
    }
    
    private func textFieldTo(color: UIColor, textField: YoshikoTextField) {
        textField.activeBorderColor = color
        textField.textColor = color
    }
    
    // MARK: - Validation Functions
    
    private func isValidEmail(testStr:String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: testStr)
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func dismiss(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

class EULAViewController: UIViewController {
    
    func dismissView(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}
