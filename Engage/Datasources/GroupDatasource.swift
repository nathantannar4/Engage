//
//  GroupDatasource.swift
//  Engage
//
//  Created by Nathan Tannar on 5/23/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

open class GroupDatasource: NTCollectionDatasource {
    
    var group: Group
    
    public init(forGroup group: Group) {
        self.group = group
    }
    
    open override func item(_ indexPath: IndexPath) -> Any? {
        return group
    }
    
    open override func numberOfItems(_ section: Int) -> Int {
        return 1
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
        return [GroupHeaderCell.self]
    }
}
