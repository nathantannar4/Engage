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
        
        if PFUser.current() != nil {
            User.didLogin(with: PFUser.current()!)
        }
    }
    
    override func registerButtonPressed() {
        
    }
    
    override func emailLoginLogic(email: String, password: String) {
        
        // Freeze user interaction
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // Send login data to server to request session token
        PFUser.logInWithUsername(inBackground: email, password: password) { (object, error) -> Void in
            UIApplication.shared.endIgnoringInteractionEvents()
            guard let user = object else {
                Log.write(.error, error.debugDescription)
                return
            }
            Log.write(.status, "Email Login Successful")
            User.didLogin(with: user)
        }
    }
    
    override func facebookLoginLogic() {
        PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile", "email", "user_friends"]) { (user, error) in
            
            guard user != nil else {
                Log.write(.error, error.debugDescription)
                return
            }
            Log.write(.status, "Facebook Login Successful")
            let request = FBSDKGraphRequest(graphPath:"me", parameters: ["fields": "id, email, first_name, last_name"])
            request!.start(completionHandler: { (connection, result, error) in
                guard let userData = result as? NSDictionary else {
                    Log.write(.error, "Could not request user data from Facebook")
                    return
                }
                //userData["email"] as? String
                //userData["first_name"] as! String
                //userData["last_name"] as! String
            })
        }
    }
}

