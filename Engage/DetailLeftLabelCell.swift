//
//  DetailLeftLabelCell.swift
//  Engage
//
//  Created by Nathan Tannar on 10/1/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import UIKit
import Former
import ParseUI

final class DetailLeftLabelCell: UITableViewCell {
    
    // MARK: Public
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.textColor = .formerColor()
    }
}

