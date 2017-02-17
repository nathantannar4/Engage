//
//  EventPreviewCell.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-29.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import NTUIKit
import Former

final class EventPreviewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var notesLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    
    var title: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    var note: String? {
        get { return notesLabel.text }
        set { notesLabel.text = newValue }
    }
    var noteColor: UIColor? {
        get { return notesLabel.textColor }
        set { notesLabel.textColor = newValue }
    }
    
    var titleColor: UIColor? {
        get { return titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.textColor = Color.defaultNavbarTint
    }
}
