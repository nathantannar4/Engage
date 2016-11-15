//
//  AppToolbarController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-09-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Material

class AppToolbarController: ToolbarController {
    private var menuButton: IconButton!
    private var bellButton: IconButton!
    private var lastView: UIViewController!
    private var secondLastView: UIViewController!
    
    override func prepare() {
        super.prepare()
        prepareMenuButton()
        prepareBellButton()
        prepareStatusBar()
        prepareToolbarMenu(right: [])
        toolbar.shadowOpacity = 0.0
    }
    
    @objc
    internal func handleMenuButton() {
        navigationDrawerController?.toggleLeftView()
    }
    
    @objc
    internal func handleMoreButton() {
        navigationDrawerController?.toggleRightView()
    }
    
    private func prepareMenuButton() {
        menuButton = IconButton(image: Icon.cm.menu)
        menuButton.tintColor = UIColor.white
        menuButton.addTarget(self, action: #selector(handleMenuButton), for: .touchUpInside)
    }
    
    func prepareBellButton() {
        bellButton = IconButton(image: Icon.cm.bell)
        bellButton.tintColor = UIColor.white
        bellButton.addTarget(self, action: #selector(handleMoreButton), for: .touchUpInside)
        toolbar.rightViews = [bellButton]
    }
    
    private func prepareStatusBar() {
        statusBarStyle = .lightContent
        statusBar.backgroundColor = MAIN_COLOR
    }
    
    func prepareToolbarMenu(right: [IconButton]) {
        toolbar.leftViews = [menuButton]
        toolbar.rightViews = right
    }
    
    func prepareToolbarCustom(left: [IconButton], right: [IconButton]) {
        toolbar.leftViews = left
        toolbar.rightViews = right
    }
    
    func push(from: UIViewController, to: UIViewController) {
        secondLastView = lastView
        lastView = from
        appToolbarController.transition(to: to, duration: 0.01, options: .curveEaseOut, animations: nil , completion: nil)
    }
    
    func rotateRight(from: UIViewController, to: UIViewController) {
        secondLastView = lastView
        lastView = from
        appToolbarController.transition(to: to, duration: 0.4, options: .transitionFlipFromRight, animations: nil , completion: nil)
    }
    
    func rotateLeft(from: UIViewController) {
        appToolbarController.transition(to: lastView, duration: 0.4, options: .transitionFlipFromLeft, animations: nil , completion: nil)
        lastView = secondLastView
    }
    
    func pull(from: UIViewController) {
        appToolbarController.transition(to: lastView, duration: 0.01, options: .curveEaseOut, animations: nil , completion: nil)
        lastView = secondLastView
    }
    
}

