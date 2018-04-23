//
//  Double+Helper.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit

extension Double {
    
    func rounded(to value: Int) -> Double {
        let divisor = pow(10.0, Double(value))
        return (self * divisor).rounded() / divisor
    }
    
    func metersToKilometers() -> Double {
        return self/1000
    }
    
    func secondsToMinutes() -> Double {
        return self/60
    }
}
