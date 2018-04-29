//
//  Activity.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 26/04/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import HealthKit

enum Activity: Double {
	case running = 8, walking = 3.6
	
	/// Reference speed for MET correction, in m/s
	var referenceSpeed: Double {
		switch self {
		case .running:
			return 100/36
		case .walking:
			return 55/36
		}
	}
	
	var healthKitEquivalent: HKWorkoutActivityType {
		switch self {
		case .running:
			return .running
		case .walking:
			return .walking
		}
	}
	
	var met: Double {
		return self.rawValue
	}
	
	/// Calculate the number of calories for the activity.
	/// - parameter time: The duraction in seconds
	/// - parameter distance: The distance in kilometers
	/// - parameter weight: The weight in kilograms
	func caloriesFor(time: TimeInterval, distance: Double, weight: Double) -> Double {
		let speed = distance * 1000 / time
		let factor = speed - self.referenceSpeed
		return (self.met + factor * 0.5) * weight * time / 3600
	}
	
}