//
//  EngageInfoViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 2/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit

class EngageInfoViewController: NTTableViewController, NTTableViewDataSource {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.groupTableViewBackground
        self.reloadData()
    }
    
    //MARK: NTTableViewDataSource
    
    func numberOfSections(in tableView: NTTableView) -> Int {
        return 0
    }
    
    func tableView(_ tableView: NTTableView, rowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: NTTableView, cellForRowAt indexPath: IndexPath) -> NTTableViewCell {
        return NTTableViewCell()
    }
    
    func imageForStretchyView(in tableView: NTTableView) -> UIImage? {
        return UIImage(named: "header")
    }
}
