//
//  GettingStartedViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/19/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

class GettingStartedViewController: UIViewController {
    
    open let titleLabel: NTLabel = {
        let label = NTLabel(style: .title)
        label.font = Font.Default.Headline.withSize(44)
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .white
        label.text = "Welcome to Engage"
        return label
    }()
    
    open let subtitleLabel: NTLabel = {
        let label = NTLabel()
        label.font = Font.Default.Body.withSize(22)
        label.adjustsFontSizeToFitWidth = true
        label.textColor = Color.Gray.P100
        label.text = "Create your own private or public group to for student societies, clubs, organizations and any other group you want your own social space for."
        return label
    }()
    
    open let getStartedLabel: NTLabel = {
        let label = NTLabel()
        label.font = Font.Default.Subtitle
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .white
        label.text = "Get started by creating a or joining an Engagement"
        return label
    }()

    open let searchButton: NTButton = {
        let button = NTButton()
        button.trackTouchLocation = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.image = Icon.Search?.scale(to: 50)
        button.setDefaultShadow()
        button.addTarget(self, action: #selector(searchButtonPressed), for: .touchUpInside)
        return button
    }()
    
    open let createButton: NTButton = {
        let button = NTButton()
        button.trackTouchLocation = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.image = Icon.Create?.scale(to: 50)
        button.setDefaultShadow()
        button.addTarget(self, action: #selector(createButtonPressed), for: .touchUpInside)
        return button
    }()
    
    open let signOutButton: NTButton = {
        let button = NTButton()
        button.trackTouchLocation = false
        button.title = "Sign Out"
        button.ripplePercent = 1
        button.layer.cornerRadius = 16
        button.backgroundColor = .white
        button.setDefaultShadow()
        button.addTarget(self, action: #selector(logout), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.applyGradient(colours: [Color.Default.Tint.View.darker(by: 10), Color.Default.Tint.View.darker(by: 5), Color.Default.Tint.View, Color.Default.Tint.View.lighter(by: 5)], locations: [0.0, 0.1, 0.3, 1.0])
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(getStartedLabel)
        
        let referenceView = UIView()
        view.addSubview(referenceView)
        referenceView.anchorCenterSuperview()
        
        view.addSubview(searchButton)
        view.addSubview(createButton)
        
        titleLabel.anchor(view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, topConstant: 64, leftConstant: 16, bottomConstant: 0, rightConstant: 16, widthConstant: 0, heightConstant: 40)
        subtitleLabel.anchor(titleLabel.bottomAnchor, left: titleLabel.leftAnchor, bottom: nil, right: titleLabel.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        getStartedLabel.anchor(subtitleLabel.bottomAnchor, left: subtitleLabel.leftAnchor, bottom: referenceView.bottomAnchor, right: subtitleLabel.rightAnchor, topConstant: 20, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 20)
        
        searchButton.anchor(referenceView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, topConstant: 16, leftConstant: 16, bottomConstant: 0, rightConstant: 0, widthConstant: 100, heightConstant: 100)
        createButton.anchor(searchButton.topAnchor, left: searchButton.rightAnchor, bottom: nil, right: nil, topConstant: 0, leftConstant: 32, bottomConstant: 0, rightConstant: 0, widthConstant: 100, heightConstant: 100)
        
        
        view.addSubview(signOutButton)
        signOutButton.anchor(nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: nil, topConstant: 0, leftConstant: 16, bottomConstant: 16, rightConstant: 0, widthConstant: 100, heightConstant: 32)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
    func searchButtonPressed() {
        let searchVC = EngagementSearchViewController()
        presentViewController(searchVC, from: .right, completion: nil)
    }
    
    func createButtonPressed() {
        let searchVC = CreateGroupViewController(asEngagement: true)
        presentViewController(searchVC, from: .right, completion: nil)
    }
    
    func logout() {
        User.current()?.logout()
    }
}
