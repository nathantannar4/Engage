//
//  File.swift
//  Engage
//
//  Created by Nathan Tannar on 5/22/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

open class UserCell: NTCollectionViewCell {
    
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
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    open let subtitleLabel: NTLabel = {
        let label = NTLabel(style: .subtitle)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    open let actionButton: NTButton = {
        let button = NTButton()
        button.ripplePercent = 1.2
        button.touchUpAnimationTime = 0.3
        button.trackTouchLocation = false
        button.backgroundColor = .white
        button.layer.borderColor = Color.Default.Background.Button.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.title = "Follow"
        button.titleColor = Color.Default.Background.Button
        button.titleFont = Font.Default.Callout.withSize(12)
        button.rippleColor = Color.Default.Background.Button
        button.setTitleColor(.white, for: .highlighted)
        return button
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
        //addSubview(actionButton)
        
        
        coverImageView.anchor(topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 200)
        
        view.anchor(topAnchor, left: leftAnchor, bottom: nil, right: nil, topConstant: 175, leftConstant: 16, bottomConstant: 0, rightConstant: 0, widthConstant: 75, heightConstant: 75)
        profileImageView.fillSuperview()
        
        //actionButton.anchor(coverImageView.bottomAnchor, left: nil, bottom: nil, right: rightAnchor, topConstant: 10, leftConstant: 0, bottomConstant: 0, rightConstant: 16, widthConstant: 64, heightConstant: 30)
        
        titleLabel.anchor(coverImageView.bottomAnchor, left: view.rightAnchor, bottom: nil, right: rightAnchor, topConstant: 0, leftConstant: 8, bottomConstant: 0, rightConstant: 16, widthConstant: 0, heightConstant: 35)
        
        subtitleLabel.anchor(titleLabel.bottomAnchor, left: titleLabel.leftAnchor, bottom: nil, right: titleLabel.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 15)
    }
}

