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

class RegisterViewController: UITableViewController {
    
    @IBOutlet weak var emailTextField: YoshikoTextField!
    @IBOutlet weak var passwordTextField: YoshikoTextField!
    @IBOutlet weak var passwordAgainTextField: YoshikoTextField!
    @IBOutlet weak var nameTextField: YoshikoTextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    
    var validEmail = false
    var validPassword = false
    var validPasswordAgain = false
    var validName = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Configure Colors
        emailTextField.activeBorderColor = MAIN_COLOR!
        emailTextField.textColor = MAIN_COLOR
        emailTextField.addTarget(self, action: #selector(RegisterViewController.textFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
        
        passwordTextField.activeBorderColor = MAIN_COLOR!
        passwordTextField.textColor = MAIN_COLOR
        passwordTextField.addTarget(self, action: #selector(RegisterViewController.textFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
        
        passwordAgainTextField.activeBorderColor = MAIN_COLOR!
        passwordAgainTextField.textColor = MAIN_COLOR
        passwordAgainTextField.addTarget(self, action: #selector(RegisterViewController.textFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
        
        nameTextField.activeBorderColor = MAIN_COLOR!
        nameTextField.textColor = MAIN_COLOR
        nameTextField.addTarget(self, action: #selector(RegisterViewController.textFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
        
        registerButton.setTitleColor(UIColor.darkGray, for: .normal)
        registerButton.isEnabled = false
        
        cancelButton.setTitleColor(MAIN_COLOR, for: .normal)
        cancelButton.layer.borderColor = MAIN_COLOR?.cgColor
        cancelButton.layer.borderWidth = 1.0
        
        termsButton.setTitleColor(MAIN_COLOR, for: .normal)
        termsButton.setSubstituteFontName("Avenir Next")
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(RegisterViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func registerButtonPressed(_ sender: AnyObject) {
        dismissKeyboard()
        print("Registering")
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
                print("Success")
                Profile.sharedInstance.loadUser()
                
                self.passwordTextField.activeBorderColor = UIColor.flatGreen()
                self.passwordTextField.textColor = UIColor.flatGreen()
                
                self.passwordAgainTextField.activeBorderColor = UIColor.flatGreen()
                self.passwordAgainTextField.textColor = UIColor.flatGreen()
                
                self.nameTextField.activeBorderColor = UIColor.flatGreen()
                self.nameTextField.textColor = UIColor.flatGreen()
                
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
                                Utilities.showEngagement(self)
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
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        // Cancel registration
        self.navigationController!.popToRootViewController(animated: true)
    }
    
    // MARK - UITextFieldDelegate methods
    
    func textFieldDidChange(sender: AnyObject) {
        
        // Highlight text field colors based on valid entries
        let textField = sender as! UITextField
        if textField.placeholder == "Email" {
            if isValidEmail(testStr: emailTextField.text!) {
                validEmail = true
                let emailQuery = PFQuery(className: PF_USER_CLASS_NAME)
                emailQuery.whereKey(PF_USER_EMAIL, equalTo: emailTextField.text!)
                emailQuery.findObjectsInBackground(block: { (users, error) in
                    if users?.count == 0 {
                        self.emailTextField.activeBorderColor = UIColor.flatGreen()
                        self.emailTextField.textColor = UIColor.flatGreen()
                    } else {
                        self.emailTextField.activeBorderColor = UIColor.flatRed()
                        self.emailTextField.textColor = UIColor.flatRed()
                        self.validEmail = false
                    }
                })
            } else {
                validEmail = false
                emailTextField.activeBorderColor = MAIN_COLOR!
                emailTextField.textColor = MAIN_COLOR
            }
        }
        if textField.placeholder == "Password" {
            if passwordTextField.text!.characters.count >= 6 {
                validPassword = true
            } else {
                validPassword = false
            }
            passwordAgainTextField.activeBorderColor = MAIN_COLOR!
            passwordAgainTextField.textColor = MAIN_COLOR
            if passwordAgainTextField.text != "" {
                passwordAgainTextField.text = ""
            }
        }
        if textField.placeholder == "Password Again" {
            if passwordTextField.text! == passwordAgainTextField.text! {
                validPasswordAgain = true
                passwordAgainTextField.activeBorderColor = UIColor.flatGreen()
                passwordAgainTextField.textColor = UIColor.flatGreen()
            } else if passwordTextField.text! == "" {
                validPasswordAgain = false
                passwordAgainTextField.activeBorderColor = MAIN_COLOR!
                passwordAgainTextField.textColor = MAIN_COLOR
            } else {
                validPasswordAgain = false
                passwordAgainTextField.activeBorderColor = UIColor.flatRed()
                passwordAgainTextField.textColor = UIColor.flatRed()
            }
        }
        if textField.placeholder == "Name" {
            if nameTextField.text!.characters.count >= 2 {
                validName = true
            } else {
                validName = false
            }
        }
        print(validEmail)
        print(validPassword)
        print(validPasswordAgain)
        print(validName)
        print("-------")
        if (validEmail && validPassword && validPasswordAgain && validName) {
            registerButton.setTitleColor(MAIN_COLOR, for: .normal)
            registerButton.layer.borderColor = MAIN_COLOR?.cgColor
            registerButton.layer.borderWidth = 1.0
            registerButton.isEnabled = true
        } else {
            registerButton.setTitleColor(UIColor.darkGray, for: .normal)
            registerButton.layer.borderWidth = 0.0
            registerButton.isEnabled = false
        }
    }
    
    @IBAction func showTerms(_ sender: AnyObject) {
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
    
    func dismiss(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK - Other Functions
    
    func isValidEmail(testStr:String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: testStr)
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}

class EULAViewController: UIViewController {
    
    func dismissView(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}
