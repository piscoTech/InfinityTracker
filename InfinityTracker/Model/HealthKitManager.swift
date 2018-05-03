//
//  HealthKitManager.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 26/04/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import HealthKit
import UIKit
import MBLibrary

enum HealthWritePermission {
	case none, partial, full
}

class HealthKitManager {
	
	static let healthStore = HKHealthStore()
	
	static let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
	static let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
	static let routeType = HKQuantityType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)!
	static let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
	
	// https://en.wikipedia.org/wiki/Human_body_weight on 29/04/2018
	static let averageWeight = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: 62)
	
	///Keep track of the version of health authorization required, increase this number to automatically display an authorization request.
	static private let authRequired = 2
	///List of health data to require read access to.
	static private let healthReadData: Set<HKObjectType> = [.workoutType(), distanceType, calorieType, routeType, weightType]
	///List of health data to require write access to.
	static private let healthWriteData: Set<HKSampleType> = [.workoutType(), distanceType, calorieType, routeType, weightType]
	
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
	
	/// Get the weight to use in calories computation.
	static func getWeight(completion: @escaping (HKQuantity) -> Void) {
		getRealWeight { completion($0 ?? averageWeight) }
	}
	
	/// Get the real weight of the user.
	static func getRealWeight(completion: @escaping (HKQuantity?) -> Void) {
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let type = weightType
		let weightQuery = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (_, r, err) in
			completion((r?.first as? HKQuantitySample)?.quantity)
		}
		
		HealthKitManager.healthStore.execute(weightQuery)
	}
	
	/// Get the total distance (in meters) and calories burned (in kilocalories) saved by the app.
	static func getStatistics(completion: @escaping (Double, Double) -> Void) {
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
	
	static var healthPermissionAlert: UIAlertController {
		return UIAlertController(simpleAlert: NSLocalizedString("WARN_HEALTH_ACCESS_MISSING", comment: "Missing health access"), message: NSLocalizedString("WARN_HEALTH_ACCESS_MISSING_BODY", comment: "Missing health access"))
	}
	
}
