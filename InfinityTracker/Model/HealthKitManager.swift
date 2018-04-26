//
//  HealthKitManager.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 26/04/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import HealthKit

class HealthKitManager {
	
	static let healthStore = HKHealthStore()
	static let workoutTypes = [HKWorkoutActivityType.running, .walking]
	
	static func requestAuthorization() {
		
	}
	
	/// Get the total distance saved by the app in meters.
	public static func getDistanceTotal() -> Double {
		return 0
//
//		var totalDistance: Double = 0.0
//
//		let runs = fetchObjects(entity: Run.self, context: context)
//
//		for run in runs {
//			totalDistance += run.distance
//		}
//
//		return totalDistance
	}
	
	/// Get the total energy burned saved by the app in kilocalories.
	public static func getCaloriesTotal() -> Double {
		return 0
//
//		var caloriesTotal: Double = 0.0
//
//		let runs = fetchObjects(entity: Run.self, context: context)
//
//		for run in runs {
//			caloriesTotal += run.calories
//		}
//
//		return caloriesTotal
	}
	
}
