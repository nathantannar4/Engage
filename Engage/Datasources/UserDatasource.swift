//
//  UserDatasource.swift
//  Engage
//
//  Created by Nathan Tannar on 5/22/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

open class UserDatasource: NTCollectionDatasource {
    
    var user: User
    
    public init(fromUser user: User) {
        self.user = user
    }
    
    open override func item(_ indexPath: IndexPath) -> Any? {
        if indexPath.section == 0 {
            return user
        }
        return nil
    }
    
    open override func numberOfItems(_ section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return 0
    }
    
    open override func numberOfSections() -> Int {
        return 1
    }
    
    open override func footerClasses() -> [NTCollectionViewCell.Type]? {
        return [NTCollectionViewCell.self]
    }
    
    open override func headerClasses() -> [NTCollectionViewCell.Type]? {
        return [NTCollectionViewCell.self]
    }
    
    open override func cellClasses() -> [NTCollectionViewCell.Type] {
        return [UserCell.self]
    }
}

