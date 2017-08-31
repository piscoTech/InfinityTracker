//
//  CurvedView.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit

@IBDesignable
class CurvedView: UIView {
    
    // MARK: Properties
    
    @IBInspectable var curvingY: CGFloat = 30 {
        didSet{
            setNeedsDisplay()
        }
    }
    
    // MARK: LifeCycle
    
    override func draw(_ rect: CGRect) {
        setupView(rect)
    }
    
    // MARK: Setup View
    
    private func setupView(_ frame: CGRect) {
        
        let myBezier = UIBezierPath()
        myBezier.move(to: CGPoint(x: 0, y: 0))
        myBezier.addQuadCurve(to: CGPoint(x: frame.width, y: 0), controlPoint: CGPoint(x: frame.width / 2, y: curvingY))
        myBezier.addLine(to: CGPoint(x: frame.width, y: frame.height))
        myBezier.addLine(to: CGPoint(x: 0, y: frame.height))
        myBezier.close()
        
        UIColor.white.setFill()
        myBezier.fill()
        
        self.setNeedsDisplay()
    }
    
}
