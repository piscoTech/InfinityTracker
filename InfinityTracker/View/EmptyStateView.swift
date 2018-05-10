//
//  EmptyStateView.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit

class EmptyStateView: UIView {
    
    lazy var imageView: UIImageView = {
        var imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = Appearance.emptyState
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        return imageView
    }()
    
    lazy var descriptionTextView: UITextView = {
        var descriptionTextView = UITextView()
		descriptionTextView.text = NSLocalizedString("MOTIVATIONAL_TEXT", comment: "Start moving :)")
        descriptionTextView.backgroundColor = UIColor.clear
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.textAlignment = .center
        descriptionTextView.isEditable = false
        descriptionTextView.isSelectable = false
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        descriptionTextView.layer.cornerRadius = 5
        descriptionTextView.layer.masksToBounds = true
        descriptionTextView.textContainer.maximumNumberOfLines = 4
        descriptionTextView.textColor = UIColor.lightGray
        descriptionTextView.font = UIFont.systemFont(ofSize: 17)
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(descriptionTextView)
        return descriptionTextView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    func setupLayout() {
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -125).isActive = true
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        descriptionTextView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        descriptionTextView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5).isActive = true
        descriptionTextView.leftAnchor.constraint(equalTo: leftAnchor, constant: 25).isActive = true
        descriptionTextView.rightAnchor.constraint(equalTo: rightAnchor, constant: -25).isActive = true
    }
    
}
