//
//  EngagementSearchViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/20/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

class EngagementSearchViewController: NTSelfNavigatedViewController, UITableViewDataSource, UITableViewDelegate {
    
    let searchField: NTAnimatedTextField = {
        let textField = NTAnimatedTextField()
        textField.placeholder = "Search by Name"
        return textField
    }()
    
    let searchView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.setDefaultShadow()
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        return view
    }()
    
    open var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    fileprivate var bottomAnchor: NSLayoutConstraint?
    
    fileprivate var keyboardActive: (Bool, CGRect) = (false, .zero) {
        didSet {
            self.searchView.layoutIfNeeded()
            self.view.layoutIfNeeded()
            if keyboardActive.0 {
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.bottomAnchor?.constant = -self.keyboardActive.1.height + 10
                    self.searchView.layoutIfNeeded()
                    self.view.layoutIfNeeded()
                })

            } else {
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.bottomAnchor?.constant = 5
                    self.searchView.layoutIfNeeded()
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Search Engagements"
        backButton.image = Icon.Delete
        nextButton.image = Icon.Search?.scale(to: 30)
        
        view.addSubview(searchView)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.anchor(navBarView.bottomAnchor, left: view.leftAnchor, bottom: searchView.topAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: -5, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        
        nextButton.removeFromSuperview()
        nextButton.removeAllConstraints()
        
        searchView.addSubview(searchField)
        searchView.addSubview(nextButton)
        bottomAnchor = searchView.anchorWithReturnAnchors(nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: -5, rightConstant: 0, widthConstant: 0, heightConstant: 64)[1]
        
        searchField.anchor(nil, left: searchView.leftAnchor, bottom: searchView.bottomAnchor, right: nextButton.leftAnchor, topConstant: 0, leftConstant: 16, bottomConstant: 16, rightConstant: 8, widthConstant: 0, heightConstant: 30)
        nextButton.anchor(nil, left: nil, bottom: searchView.bottomAnchor, right: searchView.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 16, rightConstant: 16, widthConstant: 50, heightConstant: 50)
        
        NotificationCenter.default.addObserver(self, selector: #selector(EngagementSearchViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EngagementSearchViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EngagementSearchViewController.keyboardDidChangeFrame), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
        
        view.bringSubview(toFront: navBarView)
        view.bringSubview(toFront: searchView)
    }
    
    override func nextButtonPressed() {
        if searchField.isFirstResponder {
            searchField.resignFirstResponder()
        } else {
            searchField.becomeFirstResponder()
        }
    }
    
    // MARK: - Keyboard Observer
    
    func keyboardDidChangeFrame(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardActive = (keyboardActive.0, keyboardSize)
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardActive = (true, keyboardSize)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardActive = (false, keyboardSize)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = NTTableViewCell()
        cell.textLabel?.text = String.random(ofLength: 16)
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchField.resignFirstResponder()
    }
}
