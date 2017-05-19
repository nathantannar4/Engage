//
//  Service.swift
//  Engage
//
//  Created by Nathan Tannar on 2/21/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import NTComponents

struct Service {
    
    static let sharedInstance = Service()
    static var queryHome: String {
        get {
            return "dev" //Engagement.current()?.queryName ?? "nil"
        }
    }
    /*
    func fetchHomeDatasource(completion: @escaping (HomeDatasource) -> ()) {
        let engagementQuery = User.current().engagements?.query()
        engagementQuery?.findObjectsInBackground { (objects, error) in
            guard let objects = objects else {
                Log.write(.error, error.debugDescription)
                let toast = NTToast(text: error?.localizedDescription)
                toast.show(duration: 1.5)
                return
            }
            let engagements = objects.map({ (object) -> Engagement in
                return Engagement(object)
            })
            let datasource = HomeDatasource(engagements: engagements)
            completion(datasource)
        }

    }
    
    func fetchOpenEngagements(completion: @escaping ([Engagement]) -> ()) {
        let engagementQuery = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
        engagementQuery.whereKey(PF_ENGAGEMENTS_HIDDEN, equalTo: false)
        engagementQuery.findObjectsInBackground { (objects, error) in
            guard let objects = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            let engagements = objects.map({ (object) -> Engagement in
                return Engagement(object)
            })
            completion(engagements)
        }
    }
    
    func fetchFeedDatasource(completion: @escaping (FeedDatasource) -> ()) {
        let postQuery = PFQuery(className: Service.queryHome + PF_POST_CLASSNAME)
        //postQuery.cachePolicy = .networkElseCache
        postQuery.addDescendingOrder(PF_POST_CREATED_AT)
        postQuery.includeKey(PF_POST_USER)
        postQuery.findObjectsInBackground { (objects, error) in
            guard let objects = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            let posts = objects.map({ (object) -> Post in
                return Post(object)
            })
            let datasource = FeedDatasource(posts: posts)
            completion(datasource)
        }
    }
    
    func fetchUserDatasource(_ user: User, completion: @escaping (UserDatasource) -> ()) {
        let postQuery = PFQuery(className: Service.queryHome + PF_POST_CLASSNAME)
        postQuery.whereKey(PF_POST_USER, equalTo: user.object)
        postQuery.addDescendingOrder(PF_POST_CREATED_AT)
        postQuery.includeKey(PF_POST_USER)
        postQuery.findObjectsInBackground { (objects, error) in
            guard let objects = objects else {
                Log.write(.error, error.debugDescription)
                let datasource = UserDatasource(user, posts: [])
                completion(datasource)
                return
            }
            let posts = objects.map({ (object) -> Post in
                return Post(object)
            })
            let datasource = UserDatasource(user, posts: posts)
            completion(datasource)
        }
    }
    
    func fetchGroupDatasource(_ group: Group, completion: @escaping (GroupDatasource) -> ()) {
        let postQuery = PFQuery(className: Service.queryHome + PF_POST_CLASSNAME)
        postQuery.addDescendingOrder(PF_POST_CREATED_AT)
        postQuery.includeKey(PF_POST_USER)
        postQuery.findObjectsInBackground { (objects, error) in
            guard let objects = objects else {
                Log.write(.error, error.debugDescription)
                let datasource = GroupDatasource(group, posts: [])
                completion(datasource)
                return
            }
            let posts = objects.map({ (object) -> Post in
                return Post(object)
            })
            let datasource = GroupDatasource(group, posts: posts)
            completion(datasource)
        }
    }
    */
}
