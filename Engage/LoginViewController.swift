//
//  ViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/9/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import ParseFacebookUtilsV4

class LoginViewController: NTLoginViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loginOptions = [.facebook, .email]
        self.logo = UIImage(named: "Engage_Logo")
        
        self.tableView.isHidden = true
        if PFUser.current() != nil {
            let query = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
            query.getFirstObjectInBackground(block: { (object, error) in
                if error != nil {
                    let toast = Toast(text: error!.localizedDescription, button: nil, color: Color.darkGray, height: 44)
                    toast.show(duration: 2.0)
                    self.tableView.isHidden = false
                } else {
                    User.didLogin(with: PFUser.current()!)
                }
            })
        } else {
            self.tableView.isHidden = false
        }
    }
    
    override func emailRegisterLogic(email: String, password: String, name: String) {
        
        // Freeze user interaction
        self.view.endEditing(true)
        
        let alertController = UIAlertController(title: "EULA", message: "By registering with Engage you accept the End-User License Agreement", preferredStyle: .alert)
        
        let viewAction = UIAlertAction(title: "View", style: .default) { action in
            self.showEULA()
        }
        alertController.addAction(viewAction)
        
        let acceptAction = UIAlertAction(title: "Accept", style: .cancel) { action in
            UIApplication.shared.beginIgnoringInteractionEvents()
            
            // Create new user
            let user = PFUser()
            user.username = email
            user.email = email
            user.password = password
            user[PF_USER_FULLNAME] = name
            user[PF_USER_FULLNAME_LOWER] = name.lowercased()
            user[PF_USER_ENGAGEMENTS] = []
            
            // Save new user
            user.signUpInBackground { (success, error) -> Void in
                UIApplication.shared.endIgnoringInteractionEvents()
                if success {
                    User.didLogin(with: PFUser.current()!)
                } else {
                    Log.write(.error, error.debugDescription)
                    let toast = Toast(text: error?.localizedDescription, button: nil, color: Color.darkGray, height: 44)
                    toast.show(duration: 1.5)
                }
            }
        }
        alertController.addAction(acceptAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func emailLoginLogic(email: String, password: String) {
        
        // Freeze user interaction
        self.view.endEditing(true)
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // Send login data to server to request session token
        PFUser.logInWithUsername(inBackground: email, password: password) { (object, error) -> Void in
            UIApplication.shared.endIgnoringInteractionEvents()
            guard let user = object else {
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: error?.localizedDescription, button: nil, color: Color.darkGray, height: 44)
                toast.show(duration: 2.0)
                return
            }
            Log.write(.status, "Email Login Successful")
            User.didLogin(with: user)
        }
    }
    
    override func facebookLoginLogic() {
        PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile", "email", "user_friends"]) { (object, error) in
            guard let user = object else {
                Log.write(.error, error.debugDescription)
                Toast.genericErrorMessage()
                return
            }
            Log.write(.status, "Facebook Login Successful")
            User.didLogin(with: user)
            
            
            let request = FBSDKGraphRequest(graphPath:"me", parameters: ["fields": "id, email, first_name, last_name"])
            request!.start(completionHandler: { (connection, result, error) in
                guard let userData = result as? NSDictionary else {
                    Log.write(.error, "Could not request user data from Facebook")
                    Toast.genericErrorMessage()
                    return
                }
                User.current().email = userData["email"] as? String
                let firstName = userData["first_name"] as! String
                let lastName = userData["last_name"] as! String
                User.current().fullname = firstName + " " + lastName
                User.current().save(completion: nil)
            })
        }
    }
    
    func showEULA() {
        // Create HTML based text view controller for the EULA agreement
        let vc = NTViewController()
        vc.view.backgroundColor = UIColor.groupTableViewBackground
        vc.view.frame = vc.view.frame.insetBy(dx: 20, dy: 50)
        vc.view.layer.cornerRadius = 5
        vc.view.layer.borderWidth = 1
        vc.view.layer.borderColor = Color.darkGray.cgColor
        let label = UITextView()
        vc.view.addSubview(label)
        label.bindFrameToSuperviewBounds()
        if let filepath = Bundle.main.path(forResource: "EULA", ofType: "html") {
            do {
                let str = try NSAttributedString(data: String(contentsOfFile: filepath)
                    .data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType], documentAttributes: nil)
                label.textColor = Color.defaultTitle
                label.attributedText = str
                self.getNTNavigationContainer?.presentOverlay(vc, from: .bottom)
            } catch {
                print(error)
            }
        }
    }
}
