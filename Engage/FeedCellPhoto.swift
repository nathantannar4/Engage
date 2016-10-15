//
//  FeedCellPhoto.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-08-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import ParseUI
import Former

final class FeedCellPhoto: UITableViewCell, LabelFormableRow {
    
    @IBOutlet weak var postPhoto: PFImageView!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var userPhoto: PFImageView!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var replies: UILabel!
    var likes: [String]!
    
    // MARK: Public
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .gray
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
    }
    
    func formTextLabel() -> UILabel? {
        return nil
    }
    
    func formSubTextLabel() -> UILabel? {
        return nil
    }
    
    func updateWithRowFormer(_ rowFormer: RowFormer) {}
    
    // MARK: Private
    
    fileprivate var iconViewColor: UIColor?
    
}
