//
//  ImageCell.swift
//  Engage
//
//  Created by Nathan Tannar on 2016-06-18.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import ParseUI

final class ImageCell: UITableViewCell, LabelFormableRow {
    
    // MARK: Public
    
    @IBOutlet var displayImage: PFImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if iconViewColor == nil {
            iconViewColor = displayImage.backgroundColor
        }
        super.setSelected(selected, animated: animated)
        if let color = iconViewColor {
            displayImage.backgroundColor = color
        }
    }
    
    func formTextLabel() -> UILabel? {
        return UILabel()
    }
    
    func formSubTextLabel() -> UILabel? {
        return nil
    }
    
    func updateWithRowFormer(_ rowFormer: RowFormer) {}
    
    // MARK: Private
    
    fileprivate var iconViewColor: UIColor?
    
}
