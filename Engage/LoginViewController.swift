//
//  ViewController.swift
//  EngageLoginViewController
//
//  Created by Nathan Tannar on 9/29/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import TextFieldEffects
import Parse
import SVProgressHUD
import ParseFacebookUtilsV4

class LoginViewController: UITableViewController, UITextFieldDelegate, BWWalkthroughViewControllerDelegate {
    
    @IBOutlet weak var emailTextField: YoshikoTextField!
    @IBOutlet weak var passwordTextField: YoshikoTextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var facebookButton: UIButton!
    
    internal var firstLoad = true
    internal var validEmail = false
    internal var validPassword = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !(UserDefaults.standard.value(forKey: "walkthroughPresented") != nil) && !isWESST {
            self.showWalkthrough()
        }
        
        // Check if session token already exists
        if PFUser.current() != nil {
            
            // A session token already exists
            Profile.sharedInstance.user = PFUser.current()
            Profile.sharedInstance.loadUser()
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
        
        // Prepare Form
        self.prepareForm()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if PFUser.current() == nil {
            titleLabel.isHidden = false
            emailTextField.isHidden = false
            passwordTextField.isHidden = false
            loginButton.isHidden = false
            registerButton.isHidden = false
            logo.isHidden = false
            facebookButton.isHidden = false
        } else {
            emailTextField.isHidden = true
            passwordTextField.isHidden = true
            loginButton.isHidden = true
            registerButton.isHidden = true
            logo.isHidden = true
            facebookButton.isHidden = true
        }
    }
    
    // MARK: - User Actions
    @IBAction func loginButtonPressed(_ sender: AnyObject) {
        self.dismissKeyboard()
        
        // Freeze user interaction
        UIApplication.shared.beginIgnoringInteractionEvents()
        SVProgressHUD.show(withStatus: "Logging In")
        
        // Send login data to server to request session token
        PFUser.logInWithUsername(inBackground: emailTextField.text!, password: passwordTextField.text!) { (user, error) -> Void in
            UIApplication.shared.endIgnoringInteractionEvents()
            if user != nil {
                // Login Successful
                SVProgressHUD.showSuccess(withStatus: "Success")
                
                // Fetch user profile data in backgroun and cache results
                Profile.sharedInstance.user = PFUser.current()
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
                    self.resetForm()
                }
            } else {
                // Login Error
                SVProgressHUD.showError(withStatus: "Invalid Login")
                print(error.debugDescription)
            }
        }
    }
    
    @IBAction func facebookLogin(_ sender: Any) {
        PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile", "email", "user_friends"]) { (user, error) in
            
            if user != nil {
                Profile.sharedInstance.user = user
                Profile.sharedInstance.loadUser()
                let request = FBSDKGraphRequest(graphPath:"me", parameters: ["fields": "id, email, first_name, last_name"])
                request!.start(completionHandler: { (connection, result, error) in
                    if let userData = result as? NSDictionary {
                        Profile.sharedInstance.email = userData["email"] as? String
                        Profile.sharedInstance.name = (userData["first_name"] as! String) + " " + (userData["last_name"] as! String)
                        Profile.sharedInstance.saveUser()
                    }
                })
                DispatchQueue.main.async {
                    Utilities.userLoggedIn(self)
                    self.resetForm()
                }
            } else {
                print(error.debugDescription)
                SVProgressHUD.showError(withStatus: "Oops, something went wrong")
            }
        }
    }
    
 
    @IBAction func registerButtonPressed(_ sender: AnyObject) {
        self.dismissKeyboard()
        self.resetForm()
    }
    
    // MARK: - UITextFieldDelegate methods
    internal func textFieldDidChange(sender: AnyObject) {
        
        // Highlight text field colors based on valid entries
        let textField = sender as! UITextField
        if textField.placeholder == "Email" {
            if isValidEmail(emailTextField.text!) {
                validEmail = true
            } else {
                validEmail = false
            }
        }
        if textField.placeholder == "Password" {
            if passwordTextField.text!.characters.count >= 6 {
                validPassword = true
            } else {
                validPassword = false
            }
        }
        if (validEmail && validPassword) {
            // Activate button when both login fields have possible valid strings
            loginButton.setTitleColor(MAIN_COLOR, for: .normal)
            loginButton.layer.borderColor = MAIN_COLOR?.cgColor
            loginButton.layer.borderWidth = 1.0
            loginButton.isEnabled = true
        } else {
            // Disable login button to prevent useless login calls
            loginButton.setTitleColor(UIColor.darkGray, for: .normal)
            loginButton.layer.borderWidth = 0.0
            loginButton.isEnabled = false
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
        self.addToolBar(textField: self.emailTextField)
        self.addToolBar(textField: self.passwordTextField)
        self.resetForm()
        
        // Configure form title
        if !isWESST {
            self.titleLabel.text = "Engage"
        } else {
            self.titleLabel.text = "Western Engineering Students' Socities Team"
            self.titleLabel.adjustsFontSizeToFitWidth = true
        }
        self.titleLabel.textColor = MAIN_COLOR!
        
        // Configure form logo
        if isWESST {
            logo.image = UIImage(named: "WESST-Logo.png")
        } else {
            logo.image = UIImage(named: "Engage-Logo.png")
        }
        
        // Add observers to text fields
        self.emailTextField.addTarget(self, action: #selector(LoginViewController.textFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
        self.passwordTextField.addTarget(self, action: #selector(LoginViewController.textFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
    }
    
    private func resetForm() {
        // Reset login form
        self.emailTextField.text = ""
        self.passwordTextField.text = ""
        self.validEmail = false
        self.validPassword = false
        self.loginButton.setTitleColor(UIColor.darkGray, for: .normal)
        self.loginButton.layer.borderWidth = 0.0
        self.loginButton.isEnabled = false
        self.emailTextField.activeBorderColor = MAIN_COLOR!
        self.emailTextField.textColor = MAIN_COLOR!
        self.passwordTextField.activeBorderColor = MAIN_COLOR!
        self.passwordTextField.textColor = MAIN_COLOR!
        self.registerButton.setTitleColor(MAIN_COLOR, for: .normal)
        self.registerButton.layer.borderColor = MAIN_COLOR?.cgColor
        self.registerButton.layer.borderWidth = 1.0
    }
    
    private func textFieldsTo(color: UIColor) {
        self.emailTextField.activeBorderColor = color
        self.emailTextField.textColor = color
        self.passwordTextField.activeBorderColor = color
        self.passwordTextField.textColor = color
    }
    
    // MARK: - Validation Functions
    
    private func isValidEmail(_ testStr:String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: testStr)
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    // MARK: - Walkthough
    
    private func showWalkthrough() {
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
        
        self.present(walkthrough, animated: false, completion: nil)
        
        let dict:[String:Bool] = ["walkthroughPresented":true]
        UserDefaults.standard.set(dict, forKey: "walkthroughPresented")
    }
    
    internal func walkthroughCloseButtonPressed() {
        self.dismiss(animated: true, completion: {
            if PFUser.current() != nil {
                print("User Logged In")
                // A session token already exists
                Profile.sharedInstance.user = PFUser.current()
                Profile.sharedInstance.loadUser()
                Utilities.userLoggedIn(self)
            }
        })
    }
}
