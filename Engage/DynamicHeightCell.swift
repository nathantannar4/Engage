//
//  DynamicHeightCell.swift
//  Former-Demo
//
//  Created by Ryo Aoyama on 11/7/15.
//  Copyright © 2015 Ryo Aoyama. All rights reserved.
//

import UIKit
import Former

final class DynamicHeightCell: UITableViewCell {
    
    var title: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    var body: String? {
        get { return bodyLabel.text }
        set { bodyLabel.text = newValue }
    }
    var bodyColor: UIColor? {
        get { return bodyLabel.textColor }
        set { bodyLabel.textColor = newValue }
    }
    
    var titleColor: UIColor? {
        get { return titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }
    
    var date: String? {
        get { return dateLabel.text }
        set { dateLabel.text = newValue }
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
        titleLabel.textColor = .formerColor()
    }
    
    // MARK: Private
    
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
}