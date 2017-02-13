//
//  TabBarController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit

class TabBarController: NTTabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let activityFeedVC = ActivityFeedViewController()
        activityFeedVC.tabBarItem = UITabBarItem(title: "Activity Feed", image: Icon.Apple.feed, selectedImage: Icon.Apple.feedFilled)
        
        let profileVC = ProfileViewController(user: User.current())
        profileVC.tabBarItem = UITabBarItem(title: User.current().fullname, image: Icon.Apple.profile, selectedImage: Icon.Apple.profileFilled)
        
        let engagementVC = EngagementViewController(engagement: Engagement.current())
        engagementVC.tabBarItem = UITabBarItem(title: Engagement.current().name, image: Icon.Apple.hub, selectedImage: Icon.Apple.hubFilled)
        
        let teamVC: UIViewController
        let userExtention = User.current().userExtension
       
        if let team = userExtention?.team {
            teamVC = TeamViewController(team: team)
        } else {
            teamVC = JoinTeamViewController()
        }
        teamVC.tabBarItem = UITabBarItem(title: userExtention?.team?.name ?? "Join a Team", image: Icon.Apple.team, selectedImage: Icon.Apple.teamFilled)
        
        let messagesVC = MessagesViewController()
        messagesVC.tabBarItem = UITabBarItem(title: "Messages", image: Icon.Apple.inbox, selectedImage: Icon.Apple.inboxFilled)
        
        var viewControllers = [UIViewController]()
        for controller in [activityFeedVC, profileVC, engagementVC, teamVC, messagesVC] {
            controller.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Apple.menu, style: .plain, target: self, action: #selector(toggleLeftPanel))
            viewControllers.append(UINavigationController(rootViewController: controller))
        }
        
        self.viewControllers = viewControllers
    }
    
    func toggleLeftPanel() {
        self.getNTNavigationContainer?.toggleLeftPanel()
    }
}
