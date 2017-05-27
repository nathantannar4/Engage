//
//  SideBarMenuViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/19/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents
import Parse

class SideBarMenuViewController: NTCollectionViewController {
    
    // MARK: - Standard Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        Service.sharedInstance.fetchEngagementDatasource(forUser: User.current(), completion: { (datasource) in
            self.datasource = datasource
        })
        
        let rc = refreshControl()
        rc?.tintColor = .white
        rc?.attributedTitle = NSAttributedString(string: "Pull to Refresh", attributes: [NSForegroundColorAttributeName: UIColor.white])
        collectionView?.refreshControl = rc
        
        // Change View Background
        view.backgroundColor = .clear
        view.applyGradient(colours: [Color.Default.Tint.View.darker(by: 10), Color.Default.Tint.View.darker(by: 5), Color.Default.Tint.View, Color.Default.Tint.View.lighter(by: 5)], locations: [0.0, 0.1, 0.3, 1.0])
        
        // Add navigation items
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Help?.scale(to: 25), style: .plain, target: self, action: #selector(helpButtonPressed))
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createEngagement)), UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchEngagements))]
        
        // Add toolbar
        navigationController?.setToolbarHidden(false, animated: false)
        navigationController?.toolbar.isTranslucent = false
        navigationController?.toolbar.tintColor = Color.Default.Tint.Toolbar
        let items = [UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(logout)), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)]
        setToolbarItems(items, animated: false)
    }
    
    func createEngagement() {
        let vc = CreateGroupViewController(asEngagement: true)
        UIViewController.topController()?.presentViewController(vc, from: .right, completion: nil)
    }
    
    func searchEngagements() {
        let vc = EngagementSearchViewController()
        UIViewController.topController()?.presentViewController(vc, from: .right, completion: nil)
    }
    
    func helpButtonPressed() {
        
    }
    
    func logout() {
        User.current()?.logout()
    }
    
    override func handleRefresh() {
        collectionView?.refreshControl?.beginRefreshing()
        Service.sharedInstance.fetchEngagementDatasource(forUser: User.current(), completion: { (datasource) in
            DispatchQueue.main.async(execute: {
                self.datasource = datasource
                self.collectionView?.refreshControl?.endRefreshing()
            })
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let engagement = (datasource as? EngagementDatasource)?.engagements[indexPath.section] {
            getNTNavigationContainer?.toggleLeftPanel()
            DispatchQueue.executeAfter(0.4, closure: {
                Engagement.didSelect(with: engagement)
            })
        }
    }
    
    
    // MARK: - UICollectionViewDataSource Methods
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: view.frame.width, height: 160)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
}
