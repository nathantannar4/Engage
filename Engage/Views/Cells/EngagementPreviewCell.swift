//
//  EngagementPreviewCell.swift
//  Engage
//
//  Created by Nathan Tannar on 5/23/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

open class EngagementPreviewCell: NTCollectionViewCell {
    
    open override var datasourceItem: Any? {
        didSet {
            guard let engagement = datasourceItem as? Engagement else {
                return
            }
            titleLabel.text = engagement.name
            imageView.image = engagement.image
        }
    }
    
    let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        return view
    }()
    
    let imageView: NTImageView = {
        let imageView = NTImageView()
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 10
        return imageView
    }()
    
    let titleLabel: NTLabel = {
        let label = NTLabel(style: .headline)
        label.font = Font.Default.Headline.withSize(22)
        label.textAlignment = .center
        return label
    }()
    
    override open func setupViews() {
        super.setupViews()
        
        backgroundColor = .clear
        
        addSubview(iconView)
        iconView.anchorCenterSuperview()
        iconView.widthAnchor.constraint(equalToConstant: 136).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 136).isActive = true
      
        iconView.addSubview(titleLabel)
        titleLabel.anchor(iconView.topAnchor, left: iconView.leftAnchor, bottom: iconView.bottomAnchor, right: iconView.rightAnchor, topConstant: 6, leftConstant: 6, bottomConstant: 6, rightConstant: 6, widthConstant: 0, heightConstant: 0)
        
        iconView.addSubview(imageView)
        imageView.anchor(iconView.topAnchor, left: iconView.leftAnchor, bottom: iconView.bottomAnchor, right: iconView.rightAnchor, topConstant: 6, leftConstant: 6, bottomConstant: 6, rightConstant: 6, widthConstant: 0, heightConstant: 0)
        imageView.anchorCenterXToSuperview()
    }
}
