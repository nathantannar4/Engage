//
//  DetailPostCell.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-20.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former

final class DetailPostCell: UITableViewCell {
    
    // MARK: Public
    
    
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var username: UILabel!
    @IBOutlet var info: UILabel!
    @IBOutlet var school: UILabel!
    @IBOutlet var date: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: Private
    
    fileprivate var iconViewColor: UIColor?
    
}
