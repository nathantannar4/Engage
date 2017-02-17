//
//  EventFeedCell.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-09.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former

final class EventFeedCell: UITableViewCell, LabelFormableRow {
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var time: UILabel!
    
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var organizer: UILabel!
    
    @IBOutlet weak var attendence: UILabel!
    // MARK: Public
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
