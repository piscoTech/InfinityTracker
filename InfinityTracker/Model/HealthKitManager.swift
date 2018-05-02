//
//  HealthKitManager.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 26/04/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import HealthKit

enum HealthWritePermission {
	case none, partial, full
}

class HealthKitManager {
	
	static let healthStore = HKHealthStore()
	
	static let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
	static let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
	static let routeType = HKQuantityType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)!
	static let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
	
	// https://en.wikipedia.org/wiki/Human_body_weight @ 29/04/2018
	static let averageWeight = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: 62)
	
	///Keep track of the version of health authorization required, increase this number to automatically display an authorization request.
	static private let authRequired = 1
	///List of health data to require read access to.
	static private let healthReadData: Set<HKObjectType> = [.workoutType(), distanceType, calorieType, routeType, weightType]
	///List of health data to require write access to.
	static private let healthWriteData: Set<HKSampleType> = [.workoutType(), distanceType, calorieType, routeType]
	
	static func requestAuthorization() {
		guard HKHealthStore.isHealthDataAvailable() else {
			return
		}
		
		if !Preferences.authorized || Preferences.authVersion < authRequired {
			healthStore.requestAuthorization(toShare: healthWriteData, read: healthReadData) { success, _ in
				if success {
					Preferences.authorized = true
					Preferences.authVersion = authRequired
				}
			}
		}
	}
	
	static func canSaveWorkout() -> HealthWritePermission {
		if HKHealthStore.isHealthDataAvailable() && healthStore.authorizationStatus(for: .workoutType()) == .sharingAuthorized && healthStore.authorizationStatus(for: routeType) == .sharingAuthorized {
			if healthStore.authorizationStatus(for: distanceType) == .sharingAuthorized && healthStore.authorizationStatus(for: calorieType) == .sharingAuthorized {
				return .full
			} else {
				return .partial
			}
		} else {
			return .none
		}
	}
	
	static func getWeight(completion: (HKQuantity) -> Void) {
		// FIXME: Implement me :(
		completion(averageWeight)
	}
	
	/// Get the total distance (in meters) and calories burned (in kilocalories) saved by the app.
	public static func getStatistics(completion: @escaping (Double, Double) -> Void) {
		let filter = HKQuery.predicateForObjects(from: HKSource.default())
		let type = HKObjectType.workoutType()
		let workoutQuery = HKSampleQuery(sampleType: type, predicate: filter, limit: HKObjectQueryNoLimit, sortDescriptors: []) { (_, r, err) in
			let stats = (r as? [HKWorkout] ?? []).reduce((distance: 0.0, calories: 0.0)) { (res, wrkt) in
				let d = res.distance + (wrkt.totalDistance?.doubleValue(for: .meter()) ?? 0)
				let c = res.calories + (wrkt.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)
				
				return (d, c)
			}
			
			completion(stats.distance, stats.calories)
		}
		
		HealthKitManager.healthStore.execute(workoutQuery)
	}
	
}
