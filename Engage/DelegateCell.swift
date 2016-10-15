//
//  DelegateCell.swift
//  Engage
//
//  Created by Nathan Tannar on 9/25/16.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import ParseUI

final class DelegateCell: UITableViewCell, LabelFormableRow {
    
    // MARK: Public
    
    @IBOutlet weak var iconView: PFImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var schoolLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        iconView.layer.borderWidth = 4
        iconView.layer.borderColor = UIColor.white.cgColor
        iconView.layer.cornerRadius = iconView.frame.height/2
    }
    
    func formTextLabel() -> UILabel? {
        return nameLabel
    }
    
    func formSubTextLabel() -> UILabel? {
        return schoolLabel
    }
    
    func updateWithRowFormer(_ rowFormer: RowFormer) {}
    
    // MARK: Private
    
    fileprivate var iconViewColor: UIColor?
}
