//
//  GradientButton.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit

@IBDesignable class GradientButton : UIButton {
    
    // MARK: Properties
    
    @IBInspectable var startColor: UIColor = Appearance.orangeDark {
        didSet{
            setupView()
        }
    }
    
    @IBInspectable var endColor: UIColor = Appearance.orangeLight {
        didSet{
            setupView()
        }
    }
    
    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    // MARK: LifeCycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupView()
    }
    
    // MARK: Setup View
    
    private func setupView(){
        let colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        self.setNeedsDisplay()
    }
    
}
