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
	
	static func fromHealthKitEquivalent(_ workoutType: HKWorkoutActivityType) -> Activity? {
		switch workoutType {
		case .running:
			return .running
		case .walking:
			return .walking
		default:
			return nil
		}
	}
	
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
	
	var localizable: String {
		switch self {
		case .running:
			return "RUN"
		case .walking:
			return "WALK"
		}
	}
	
	/// Calculate the number of calories for the activity.
	/// - parameter time: The duration in seconds
	/// - parameter distance: The distance in meters
	/// - parameter weight: The weight in kilograms
	func caloriesFor(time: TimeInterval, distance: Double, weight: Double) -> Double {
		let speed = distance / time
		let factor = speed - self.referenceSpeed
		return (self.met + factor * 0.5) * weight * time / 3600
	}
	
	var nextActivity: Activity {
		return self == .running ? .walking : .running
	}
	
}
