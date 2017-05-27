//
//  UserHeaderCell.swift
//  Engage
//
//  Created by Nathan Tannar on 5/22/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

open class UserHeaderCell: NTCollectionViewCell {
    
    open override var datasourceItem: Any? {
        didSet {
            guard let user = datasourceItem as? User else {
                return
            }
            coverImageView.image = user.coverImage
            titleLabel.text = user.fullname
            subtitleLabel.text = user.email
            profileImageView.image = user.image
        }
    }
    
    open let coverImageView: NTImageView = {
        let imageView = NTImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = Color.Default.Background.ViewController
        imageView.clipsToBounds = true
        return imageView
    }()
    
    open let profileImageView: NTImageView = {
        let imageView = NTImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = Color.Default.Background.ViewController
        imageView.layer.cornerRadius = 5
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.clipsToBounds = true
        return imageView
    }()
    
    open let titleLabel: NTLabel = {
        let label = NTLabel(style: .title)
        return label
    }()
    
    open let subtitleLabel: NTLabel = {
        let label = NTLabel(style: .subtitle)
        return label
    }()
    
    override open func setupViews() {
        super.setupViews()
        
        backgroundColor = .white
        
        separatorLineView.isHidden = false
        separatorLineView.backgroundColor = Color.Gray.P500
        
        addSubview(coverImageView)
        
        let view = UIView()
        view.addSubview(profileImageView)
        view.setDefaultShadow()
        
        addSubview(view)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        coverImageView.anchor(topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 200)
        
        view.anchor(coverImageView.topAnchor, left: nil, bottom: nil, right: nil, topConstant: 125, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 125, heightConstant: 125)
        view.anchorCenterXToSuperview()
        profileImageView.fillSuperview()
        
        titleLabel.anchor(view.bottomAnchor, left: nil, bottom: nil, right: nil, topConstant: 8, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 20)
        titleLabel.anchorCenterXToSuperview()
        
        subtitleLabel.anchor(titleLabel.bottomAnchor, left: nil, bottom: nil, right: nil, topConstant: 6, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 15)
        subtitleLabel.anchorCenterXToSuperview()
    }
}

