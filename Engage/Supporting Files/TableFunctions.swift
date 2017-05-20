//
//  TableFunctions.swift
//  Engage
//
//  Created by Nathan Tannar on 10/7/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import Foundation
import UIKit
import NTComponents
import Former
import Agrume
import Parse

class TableFunctions {
    
    class func createMenu(text: String, onSelected: (() -> Void)?) -> RowFormer {
        return LabelRowFormer<FormLabelCell>() {
            $0.titleLabel.textColor = Color.Default.Text.Title
            $0.titleLabel.font = Font.Default.Title
            $0.accessoryType = .disclosureIndicator
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
        }
    }
    
    class func createHeader(text: String) -> ViewFormer {
        return LabelViewFormer<FormLabelHeaderView>()
            .configure {
                $0.viewHeight = 40
                $0.text = text
        }
    }
    
    class func createFooter(text: String) -> ViewFormer {
        return LabelViewFormer<FormLabelFooterView>()
            .configure {
                $0.text = text
                $0.viewHeight = 40
        }
    }
}
