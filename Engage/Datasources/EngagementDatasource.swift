//
//  EngagementDatasource.swift
//  Engage
//
//  Created by Nathan Tannar on 5/23/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

open class EngagementDatasource: NTCollectionDatasource {
    
    var engagements: [Engagement]
    
    public init(forEngagements engagements: [Engagement]) {
        self.engagements = engagements
    }
    
    open override func item(_ indexPath: IndexPath) -> Any? {
        return engagements[indexPath.section]
    }
    
    open override func numberOfItems(_ section: Int) -> Int {
        return 1
    }
    
    open override func numberOfSections() -> Int {
        return engagements.count
    }
    
    open override func footerClasses() -> [NTCollectionViewCell.Type]? {
        return [NTCollectionViewCell.self]
    }
    
    open override func headerClasses() -> [NTCollectionViewCell.Type]? {
        return [NTCollectionViewCell.self]
    }
    
    open override func cellClasses() -> [NTCollectionViewCell.Type] {
        return [EngagementPreviewCell.self]
    }
}
