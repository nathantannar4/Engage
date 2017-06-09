//
//  Engagement.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import NTComponents

public class Engagement: Group {
    
    private static var _current: Engagement?
    
    public var queryName: String? {
        get {
            guard let name = self.name?.replacingOccurrences(of: " ", with: "_") else {
                return String()
            }
            return name
        }
    }
    public var altTeamName: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_TEAM_NAME) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_TEAM_NAME] = newValue
        }
    }
    public var color: UIColor? {
        get {
            guard let colorHex = self.object.value(forKey: PF_ENGAGEMENTS_COLOR) as? String else {
                return Color.Default.Tint.View
            }
            return UIColor(hexString: colorHex)
        }
    }
    public var colorHex: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_COLOR) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_COLOR] = newValue
        }
    }
    
    // MARK: - Initialization
    
    convenience init() {
        self.init(PFObject(className: PF_ENGAGEMENTS_CLASS_NAME))
        self.members.add(User.current()!.object)
        self.admins.add(User.current()!.object)
        self.positions = []
        self.profileFields = []
    }

    // MARK: - Public Functions
    
    public static func current() -> Engagement? {
        guard let engagement = self._current else {
            Log.write(.error, "The current engagement was nil")
            return nil
        }
        return engagement
    }
    
    public func upload(image: UIImage?, forKey key: String, completion: (() -> Void)?) {
        
        guard let image = image else {
            completion?()
            return
        }
        
        NTToast(text: "Uploading Image...").show(duration: 1.0)
        if let pictureFile = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(image, 0.6)!) {
            pictureFile.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
                if error != nil {
                    Log.write(.error, error.debugDescription)
                    NTPing(type: .isDanger, title: error?.localizedDescription.capitalized).show()
                } else {
                    NTToast(text: "Image Uploaded").show(duration: 1)
                    self.object[key] = pictureFile
                    completion?()
                }
            }
            
        }
    }
    
    public func create(completion: ((_ success: Bool) -> Void)?) {
        upload(image: coverImage, forKey: PF_ENGAGEMENTS_COVER_PHOTO) { 
            upload(image: image, forKey: PF_ENGAGEMENTS_LOGO, completion: {
                self.members.add(User.current()!.object)
                self.admins.add(User.current()!.object)
                self.memberCount = 1
                self.save { (success) in
                    if success {
                        User.current()?.engagements?.add(self.object)
                        User.current()?.save(completion: { (success) in
                            completion?(success)
                        })
                    }
                }
            })
        }
    }
    
    public class func select(_ engagement: Engagement) {
        Engagement._current = engagement
        User.current()?.loadExtension(completion: {
            let tabVC = NTScrollableTabBarController(viewControllers: [UserViewController(), GroupViewController(forGroup: engagement)])
            tabVC.title = engagement.name
//            let menuNav = NTNavigationController(rootViewController: SideBarMenuViewController())
//            let navVC = NTNavigationContainer(centerView: tabVC, leftView: menuNav)
            let navVC = NTNavigationContainer(centerView: tabVC)
            navVC.makeKeyAndVisible()
        })
    }
}
