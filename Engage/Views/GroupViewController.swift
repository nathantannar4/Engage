//
//  GroupViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/19/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

class GroupViewController: NTCollectionViewController {
    
    var group: Group!
    
    convenience init(forGroup group: Group) {
        self.init()
        self.group = group
        datasource = GroupDatasource(forGroup: group)
        collectionView?.refreshControl = refreshControl()
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Group"
    }
    
    override func handleRefresh() {
        super.handleRefresh()
        datasource = GroupDatasource(forGroup: group)
        collectionView?.refreshControl?.endRefreshing()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let menuButton = UIBarButtonItem(image: Icon.MoreVertical.scale(to: 25), style: .plain, target: self, action: #selector(handleMore))
        drawerController?.rootViewController?.navigationItem.setRightBarButton(menuButton, animated: true)
    }
    
    func handleMore() {
        var items = [NTActionSheetItem]()
        let group = (self.datasource as! GroupDatasource).group
        let query = group.admins.query()
        query.findObjectsInBackground { (objects, error) in
            guard let users = objects else {
                return
            }
            if users.contains(where: { (user) -> Bool in
                if user.objectId == User.current()?.id {
                    return true
                }
                return false
            }) {
                items.append(
                    NTActionSheetItem(title: "Edit", icon: nil, action: {
                        let vc = EditGroupViewController(fromGroup: group)
                        let navVC = NTNavigationViewController(rootViewController: vc)
                        self.present(navVC, animated: true, completion: nil)
                    })
                )
            }
            items.append(
                NTActionSheetItem(title: "Leave \(group.name!)", icon: nil, action: {
                    group.leave(user: User.current()!, completion: { (success) in
                        if success {
                            self.drawerController?.removeViewController(forSide: .left)
                            self.drawerController?.setViewController(NTNavigationController(rootViewController: SideBarMenuViewController()), forSide: .center)
                        }
                    })
                })
            )
            let actionSheet = NTActionSheetViewController(actions: items)
            actionSheet.addDismissAction(withText: "Dismiss", icon: nil)
            self.present(actionSheet, animated: false, completion: nil)
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
