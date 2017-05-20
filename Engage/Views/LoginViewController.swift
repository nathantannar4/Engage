 //
//  LoginViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents
import Parse
import ParseFacebookUtilsV4

class LoginViewController: NTLoginViewController, NTEmailAuthDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        logo = UIImage(named: "connection-map")?.withRenderingMode(.alwaysTemplate)
        logoView.contentMode = .scaleAspectFill
        loginMethods = [.email, .facebook]
        subtitleLabel.text = "Create your own Social Network"
        
        if PFUser.current() != nil {
            PFUser.current()?.fetchInBackground(block: { (object, error) in
                guard let user = object as? PFUser else {
                    return
                }
                User(user).login()
            })
        }
    }
    
    override func loginLogic(sender: NTLoginButton) {
        
        let method = sender.loginMethod
    
        if method == .facebook {
            loginWithFacebook()
        } else if method == .email {
            let vc = NTEmailAuthViewController()
            vc.delegate = self
            present(vc, animated: true, completion: nil)
        }
    }
    
    func loginWithFacebook() {
        PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile", "email", "user_friends"]) { (object, error) in
            guard let user = object else {
                Log.write(.error, error.debugDescription)
                NTToast(text: "Facebook Login Cancelled").show(duration: 1)
                return
            }
            Log.write(.status, "Facebook Login Successful")
            
            let request = FBSDKGraphRequest(graphPath:"me", parameters: ["fields": "id, email, first_name, last_name"])
            request!.start(completionHandler: { (connection, result, error) in
                guard let userData = result as? NSDictionary else {
                    Log.write(.error, "Could not request user data from Facebook")
                    NTPing(type: .isDanger, title: error?.localizedDescription).show()
                    return
                }
                user.email = userData["email"] as? String
                let firstName = userData["first_name"] as! String
                let lastName = userData["last_name"] as! String
                user[PF_USER_FULLNAME] = firstName + " " + lastName
                user.saveInBackground(block: { (success, error) in
                    if success {
                        User(user).login()
                        NTPing(type: .isSuccess, title: "Login Successful").show()
                    } else {
                        Log.write(.error, error.debugDescription)
                        NTPing.genericErrorMessage()
                        PFUser.logOut()
                    }
                })
            })
        }
    }
    
    func authorize(_ controller: NTEmailAuthViewController, email: String, password: String) {
        
        controller.showActivityIndicator = true
        
        PFUser.logInWithUsername(inBackground: email, password: password) { (object, error) -> Void in
            
            controller.showActivityIndicator = false
            
            guard let user = object else {
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: "Authorization Failed").show()
                NTToast(text: error?.localizedDescription.capitalized ?? "Please check your credentials.", height: 52).show()
                return
            }
            Log.write(.status, "Email Sign In Successful")
            controller.dismiss(animated: true, completion: {
                NTPing(type: .isSuccess, title: "Authorization Success").show()
                User(user).login()
            })
        }
    }
    
    func register(_ controller: NTEmailAuthViewController, email: String, password: String) {
        
        let alert = NTAlertViewController(title: "EULA", subtitle: "By registering with Engage you accept the End-User License Agreement", type: .isSuccess)
        alert.cancelButton.title = "View"
        alert.confirmButton.title = "Accept"
        alert.onCancel = {
            let vc = NTEULAController()
            vc.eula = Bundle.main.path(forResource: "EULA", ofType: "html")
            controller.present(vc, animated: true, completion: nil)
        }
        alert.onConfirm = {
            
            controller.showActivityIndicator = true
            
            let index = email.characters.index(of: "@")!
            let user = PFUser()
            user.username = email
            user.email = email
            user.password = password
            user[PF_USER_FULLNAME] = email.substring(to: index)
            user[PF_USER_FULLNAME_LOWER] = email.substring(to: index).lowercased()
            user.signUpInBackground { (success, error) -> Void in
                
                controller.showActivityIndicator = false
                
                if success {
                    Log.write(.status, "Email Sign Up Successful")
                    controller.dismiss(animated: true, completion: {
                        NTPing(type: .isSuccess, title: "Authorization Success").show()
                        User(user).login()
                    })
                } else {
                    Log.write(.error, error.debugDescription)
                    NTPing(type: .isDanger, title: "Sign Up Failed").show()
                    NTToast(text: error?.localizedDescription.capitalized ?? "Please check your network connection.", height: 52).show()
                }
            }
        }
        controller.present(alert, animated: true, completion: nil)
    }
}
