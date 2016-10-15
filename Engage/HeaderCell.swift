//
//  HeaderCell.swift
//  Count on Us
//
//  Created by Tannar, Nathan on 2016-08-07.
//  Copyright © 2016 NathanTannar. All rights reserved.
//


import UIKit
import Former

final class HeaderCell: UITableViewCell {
    
    // MARK: Public
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var backgroundLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
}
