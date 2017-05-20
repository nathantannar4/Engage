//
//  ProfileFieldCell.swift
//  Former-Demo
//
//  Created by Ryo Aoyama on 10/31/15.
//  Copyright © 2015 Ryo Aoyama. All rights reserved.
//

import UIKit
import NTComponents
import Former

final class ProfileFieldCell: UITableViewCell, TextFieldFormableRow {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = Font.Default.Callout
        titleLabel.textColor = Color.Default.Text.Callout
        textField.textColor = UIColor.black
    }
    
    func formTextField() -> UITextField {
        return textField
    }
    
    func formTitleLabel() -> UILabel? {
        return titleLabel
    }
    
    func updateWithRowFormer(_ rowFormer: RowFormer) {}
}
