//
//  SideBarMenuViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 5/19/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents
import Parse

class SideBarMenuViewController: NTCollectionViewController {
    
    // MARK: - Standard Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setTitleView(title: "Engagements")
        view.backgroundColor = .clear
        view.applyGradient(colours: [Color.Default.Tint.View.darker(by: 10), Color.Default.Tint.View.darker(by: 5), Color.Default.Tint.View, Color.Default.Tint.View.lighter(by: 5)], locations: [0.0, 0.1, 0.3, 1.0])
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Help?.scale(to: 25), style: .plain, target: self, action: #selector(helpButtonPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createEngagement))
        
        navigationController?.setToolbarHidden(false, animated: false)
        navigationController?.toolbar.isTranslucent = false
        navigationController?.toolbar.tintColor = Color.Default.Tint.Toolbar
    
        let items = [UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(logout)), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)]
        setToolbarItems(items, animated: false)
    }
    
    
    func createEngagement() {
        let searchVC = CreateGroupViewController(asEngagement: true)
        if var topController = UIViewController.topWindow()?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.presentViewController(searchVC, from: .right, completion: nil)
        }
    }
    
    func helpButtonPressed() {
        
    }
    
    func logout() {
        User.current()?.logout()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let engagement = User.current()?.engagements?[indexPath.section] {
            getNTNavigationContainer?.toggleLeftPanel()
            DispatchQueue.executeAfter(0.4, closure: {
                Engagement.didSelect(with: engagement)
            })
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return User.current()?.engagements?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NTCollectionViewCell", for: indexPath) as! NTCollectionViewCell
        cell.backgroundColor = .clear
        
        let contentView = NTAnimatedView()
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        cell.addSubview(contentView)
        contentView.anchorCenterSuperview()
        contentView.widthAnchor.constraint(equalToConstant: (view.frame.width * 2 / 5) - 24).isActive = true
        contentView.heightAnchor.constraint(equalToConstant: (view.frame.width * 2 / 5) - 24).isActive = true
        
        let imageView = NTImageView()
        imageView.backgroundColor = Color.Gray.P200
        contentView.addSubview(imageView)
        imageView.image = User.current()?.engagements?[indexPath.section].image
        imageView.anchor(contentView.topAnchor, left: nil, bottom: nil, right: nil, topConstant: 8, leftConstant: 8, bottomConstant: 0, rightConstant: 8, widthConstant: ((view.frame.width * 2 / 5) - 24) * 3 / 5, heightConstant: ((view.frame.width * 2 / 5) - 24) * 3 / 5)
        imageView.anchorCenterXToSuperview()
        imageView.layer.cornerRadius = 16
        
        let titleLabel = NTLabel(style: .headline)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textAlignment = .center
        titleLabel.text = User.current()?.engagements?[indexPath.section].name
        contentView.addSubview(titleLabel)
        titleLabel.anchor(imageView.bottomAnchor, left: contentView.leftAnchor, bottom: contentView.bottomAnchor, right: contentView.rightAnchor, topConstant: 0, leftConstant: 8, bottomConstant: 0, rightConstant: 8, widthConstant: 0, heightConstant: 0)
        
        return cell
    }
    
    // MARK: - UICollectionViewDataSource Methods
    
    override open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: view.frame.width, height: view.frame.width * 2 / 5)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
}
