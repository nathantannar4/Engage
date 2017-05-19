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

class LoginViewController: NTLoginViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        logo = #imageLiteral(resourceName: "Engage_Logo")
        loginMethods = [.email, .facebook]
    }
    
    override func loginLogic(sender: NTLoginButton) {
        
        let method = sender.loginMethod
        
        if method == .facebook {
            loginWithFacebook()
        }
    }
    
    func loginWithFacebook() {
        PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile", "email", "user_friends"]) { (object, error) in
            guard let user = object else {
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription).show()
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
                        //User.didLogin(with: user)
                        NTPing(type: .isSuccess, title: "Login Successful").show()
                    } else {
                        Log.write(.error, error.debugDescription)
                        NTPing(type: .isDanger, title: error?.localizedDescription).show()
                        PFUser.logOut()
                    }
                })
            })
        }

    }
}
