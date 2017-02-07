//
//  Message.swift
//  Engage
//
//  Created by Nathan Tannar on 2/3/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTUIKit
import Parse

public class Message {
    
    public var user: User
    public var text: String
    public var date: Date
    public var image: UIImage?
    
    public init(user: User, text: String, date: Date, file: PFFile?) {
        self.user = user
        self.text = text
        self.date = date
        
        file?.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.image = UIImage(data: imageData)
        }
    }
}
