//
//  GettingStartedViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/19/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents
import Parse

class GettingStartedViewController: NTLandingViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.applyGradient(colours: [Color.Default.Background.NavigationBar.darker(by: 10), Color.Default.Background.NavigationBar.darker(by: 5), Color.Default.Background.NavigationBar, Color.Default.Background.NavigationBar.lighter(by: 5)], locations: [0.0, 0.1, 0.3, 1.0])
        
        titleLabel.text = "Welcome"
        subtitleLabel.text = "to Engage"
        detailLabel.text = "Create your own private or public group to for student societies, clubs, organizations and any other group you want your own social space for."
        UIApplication.shared.statusBarStyle = .lightContent
        
        buttonA.image = Icon.Create?.scale(to: 50)
        buttonB.image = Icon.Search
        signOutButton.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func buttonAAction() {
        let group = Engagement(PFObject(className: PF_ENGAGEMENTS_CLASS_NAME))
        let navVC = NTNavigationViewController(rootViewController: EditGroupViewController(fromGroup: group))
        present(navVC, animated: true, completion: nil)
    }
    
    override func buttonBAction() {
        let navVC = NTNavigationViewController(rootViewController: GroupSearchViewController())
        present(navVC, animated: true, completion: nil)
    }
    
    override func signoutAction() {
        User.current()?.logout()
    }
}
