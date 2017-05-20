//
//  TitleCell.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-25.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former

final class TitleCell: UITableViewCell {
    
    var title: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    /** Dynamic height row for iOS 7
     override func layoutSubviews() {
     super.layoutSubviews()
     titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.width
     bodyLabel.preferredMaxLayoutWidth = bodyLabel.bounds.width
     }
     **/
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: Private
    
    @IBOutlet var titleLabel: UILabel!
}
