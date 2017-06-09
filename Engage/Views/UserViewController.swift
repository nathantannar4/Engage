//
//  UserViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/19/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

class UserViewController: NTCollectionViewController {
    
    // MARK: - Standard Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        title = User.current()?.fullname
        datasource = UserDatasource(fromUser: User.current()!)
        collectionView?.refreshControl = refreshControl()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let menuButton = UIBarButtonItem(image: Icon.MoreVertical.scale(to: 25), style: .plain, target: self, action: #selector(handleMore))
        navigationContainer?.centerView.navigationItem.rightBarButtonItem = menuButton
    }
    
    func handleMore() {
        var items = [NTActionSheetItem]()
        if User.current()!.id == (datasource as? UserDatasource)?.user.id {
            items.append(
                NTActionSheetItem(title: "Edit", icon: nil, action: {
                    self.navigationController?.pushViewController(EditUserViewController(), animated: true)
                })
            )
        } else {
            items.append(
                NTActionSheetItem(title: "Block", icon: nil, action: {
                    
                })
            )
            items.append(
                NTActionSheetItem(title: "Report", icon: nil, action: {
                    
                })
            )
            items.append(
                NTActionSheetItem(title: "Make Engagement Admin", icon: nil, action: {
                    
                })
            )
        }
        let actionSheet = NTActionSheetViewController(actions: items)
        actionSheet.addDismissAction(withText: "Dismiss", icon: nil)
        present(actionSheet, animated: false, completion: nil)
    }
    
    override func handleRefresh() {
        collectionView?.refreshControl?.beginRefreshing()
        datasource = UserDatasource(fromUser: User.current()!)
        collectionView?.reloadData()
        collectionView?.refreshControl?.endRefreshing()
        
        if let parent = parent as? NTScrollableTabBarController {
            parent.setupTabView()
        }
    }
    
    // MARK: - UICollectionViewDataSource Methods
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == 3 {
            return 10
        }
        return .leastNonzeroMagnitude
    }
    
    override open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            return CGSize(width: view.frame.width, height: 310)
        }
        
        return CGSize(width: view.frame.width, height: 44)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 10)
    }
}

