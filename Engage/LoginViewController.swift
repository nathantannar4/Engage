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
import Former

class LoginViewController: UITableViewController, UITextFieldDelegate, BWWalkthroughViewControllerDelegate {
    
    @IBOutlet weak var emailTextField: YoshikoTextField!
    @IBOutlet weak var passwordTextField: YoshikoTextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logo: UIImageView!
    var firstLoad = true
    
    var validEmail = false
    var validPassword = false
    
    override func viewDidAppear(_ animated: Bool) {
        if PFUser.current() == nil {
            titleLabel.isHidden = false
            emailTextField.isHidden = false
            passwordTextField.isHidden = false
            loginButton.isHidden = false
            registerButton.isHidden = false
            logo.isHidden = false
        } else {
            emailTextField.isHidden = true
            passwordTextField.isHidden = true
            loginButton.isHidden = true
            registerButton.isHidden = true
            logo.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if !(UserDefaults.standard.value(forKey: "walkthroughPresented") != nil) {
            
            showWalkthrough()
            
            let dict:[String:Bool] = ["walkthroughPresented":true]
            UserDefaults.standard.set(dict, forKey: "walkthroughPresented")
        }
            
        if PFUser.current() != nil {
            
            // A session token already exists
            Profile.sharedInstance.user = PFUser.current()
            Profile.sharedInstance.loadUser()
            Utilities.userLoggedIn(self)
        }
        
        // Configure Title
        titleLabel.text = "Engage"
        titleLabel.textColor = MAIN_COLOR!
        
        // Configure Colors
        resetForm()
        registerButton.setTitleColor(MAIN_COLOR, for: .normal)
        registerButton.layer.borderColor = MAIN_COLOR?.cgColor
        registerButton.layer.borderWidth = 1.0
        
        // Add observers to text fields
        emailTextField.addTarget(self, action: #selector(LoginViewController.textFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
        passwordTextField.addTarget(self, action: #selector(LoginViewController.textFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
        
        // Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func loginButtonPressed(_ sender: AnyObject) {
        dismissKeyboard()
        print("Logging In")
        UIApplication.shared.beginIgnoringInteractionEvents()
        SVProgressHUD.show(withStatus: "Logging In")
        PFUser.logInWithUsername(inBackground: emailTextField.text!, password: passwordTextField.text!) { (user, error) -> Void in
            UIApplication.shared.endIgnoringInteractionEvents()
            if user != nil {
                SVProgressHUD.showSuccess(withStatus: "Success")
                print("Success")
                Profile.sharedInstance.user = PFUser.current()
                Profile.sharedInstance.loadUser()
                
                self.emailTextField.activeBorderColor = UIColor.flatGreen()
                self.emailTextField.textColor = UIColor.flatGreen()
                
                self.passwordTextField.activeBorderColor = UIColor.flatGreen()
                
                self.passwordTextField.textColor = UIColor.flatGreen()
                
                // Add a deley before showing next view for design purposes
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    
                    Utilities.userLoggedIn(self)
                    self.resetForm()
                }
            } else {
                SVProgressHUD.showError(withStatus: "Invalid Login")
                print(error)
                
            }
        }
    }
 
    @IBAction func registerButtonPressed(_ sender: AnyObject) {
        dismissKeyboard()
        resetForm()
    }
    
    // MARK - UITextFieldDelegate methods
    
    func textFieldDidChange(sender: AnyObject) {
        
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
        print(validEmail)
        print(validPassword)
        print("-------")
        if (validEmail && validPassword) {
            loginButton.setTitleColor(MAIN_COLOR, for: .normal)
            loginButton.layer.borderColor = MAIN_COLOR?.cgColor
            loginButton.layer.borderWidth = 1.0
            loginButton.isEnabled = true
        } else {
            loginButton.setTitleColor(UIColor.darkGray, for: .normal)
            loginButton.layer.borderWidth = 0.0
            loginButton.isEnabled = false
        }
    }
    
    // MARK - Other Functions
    
    func resetForm() {
        // Reset login form
        emailTextField.text = ""
        passwordTextField.text = ""
        validEmail = false
        validPassword = false
        loginButton.setTitleColor(UIColor.darkGray, for: .normal)
        loginButton.layer.borderWidth = 0.0
        loginButton.isEnabled = false
        emailTextField.activeBorderColor = MAIN_COLOR!
        emailTextField.textColor = MAIN_COLOR!
        passwordTextField.activeBorderColor = MAIN_COLOR!
        passwordTextField.textColor = MAIN_COLOR!
    }
    
    func isValidEmail(_ testStr:String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: testStr)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showWalkthrough() {
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
    }
    
    func walkthroughCloseButtonPressed() {
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
