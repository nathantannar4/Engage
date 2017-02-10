//
//  TabBarController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit

class TabBarController: UITabBarController {
    
    override func viewWillLayoutSubviews() {
        var tabFrame = self.tabBar.frame
        tabFrame.size.height = 44
        tabFrame.origin.y = self.view.frame.size.height - 44
        self.tabBar.frame = tabFrame
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let activityFeedVC = ActivityFeedViewController()
        activityFeedVC.tabBarItem = UITabBarItem(title: "Activity Feed", image: Icon.Apple.feed, selectedImage: Icon.Apple.feedFilled)
        
        let profileVC = ProfileViewController(user: User.current())
        profileVC.tabBarItem = UITabBarItem(title: "Profile", image: Icon.Apple.profile, selectedImage: Icon.Apple.profileFilled)
        
        let engagementVC = EngagementViewController(engagement: Engagement.current())
        engagementVC.tabBarItem = UITabBarItem(title: Engagement.current().name, image: Icon.Apple.hub, selectedImage: Icon.Apple.hubFilled)
        
        let teamVC = JoinTeamViewController(engagement: Engagement.current())
        teamVC.tabBarItem = UITabBarItem(title: User.current().userExtension?.team?.name ?? "Join a Team", image: Icon.Apple.team, selectedImage: Icon.Apple.teamFilled)
        
        let messagesVC = MessagesViewController()
        messagesVC.tabBarItem = UITabBarItem(title: "Messages", image: Icon.Apple.inbox, selectedImage: Icon.Apple.inboxFilled)
        
        var viewControllers = [UIViewController]()
        for controller in [activityFeedVC, profileVC, engagementVC, teamVC, messagesVC] {
            viewControllers.append(UINavigationController(rootViewController: controller))
        }
        self.viewControllers = viewControllers
        self.tabBar.isTranslucent = false
        self.tabBar.tintColor = Color.defaultNavbarTint
        self.tabBar.backgroundColor = Color.defaultNavbarBackground
    }
}

extension UITabBarController {
    func setTabBar(hidden:Bool, animated:Bool) {
        
        if self.tabBar.isHidden == hidden {
            return
        }
        
        guard let frame = self.tabBarController?.tabBar.frame else {
            return
        }
        let height = frame.size.height
        let offsetY = hidden ? height : -height
        
        UIView.animate(withDuration: 0.3) {
            self.tabBarController?.tabBar.frame = CGRect(x: frame.origin.x, y: frame.origin.y + offsetY, width: frame.width, height: frame.height)
        }
    }
}
