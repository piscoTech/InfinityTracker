//
//  Counter+Helper.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit

func setupCounter(duration: Int) -> String {
    
    let timeBoard = duration.secondsToHoursMinutesSeconds()
    
    let h = timeBoard.0
    let m = timeBoard.1
    let s = timeBoard.2
    
    var hours = "\(h)"
    var minutes = "\(m)"
    var seconds = "\(s)"
    
    if h < 10 {
        hours = "0\(timeBoard.0)"
    }
    
    if m < 10 {
        minutes = "0\(timeBoard.1)"
    }
    
    if s < 10 {
        seconds = "0\(timeBoard.2)"
    }
    
    return "\(hours):\(minutes):\(seconds)"
}

