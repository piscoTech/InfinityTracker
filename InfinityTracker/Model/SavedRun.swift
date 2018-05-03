//
//  SavedRun.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 26/04/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import HealthKit
import MapKit

class SavedRun: Run {
	
	private let raw: HKWorkout
	var healthKitWorkout: HKWorkout? {
		return raw
	}
	
	let type: Activity
	
	var totalCalories: Double {
		return raw.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
	}
	
	var totalDistance: Double {
		return raw.totalDistance?.doubleValue(for: .meter()) ?? 0
	}
	
	var start: Date {
		return raw.startDate
	}
	
	var end: Date {
		return raw.endDate
	}
	
	var duration: TimeInterval {
		return raw.duration
	}
	
	private var rawRoute: HKWorkoutRoute?
	private(set) var route: [MKPolyline] = []
	
	private(set) var startPosition: MKPointAnnotation?
	private(set) var endPosition: MKPointAnnotation?
	
	init?(raw: HKWorkout) {
		guard let type = Activity.fromHealthKitEquivalent(raw.workoutActivityType) else {
			return nil
		}
		
		self.raw = raw
		self.type = type
	}
	
	func loadAdditionalData(completion: @escaping (Bool) -> Void) {
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let filter = HKQuery.predicateForObjects(from: raw)
		let type = HealthKitManager.routeType
		let routeQuery = HKSampleQuery(sampleType: type, predicate: filter, limit: 1, sortDescriptors: [sortDescriptor]) { (_, r, err) in
			guard let route = r?.first as? HKWorkoutRoute else {
				completion(false)
				return
			}
			
			self.rawRoute = route
			self.route = []
			let locQuery = HKWorkoutRouteQuery(route: route) { (q, loc, isDone, _) in
				guard let locations = loc else {
					completion(false)
					HealthKitManager.healthStore.stop(q)
					return
				}
				
				if self.startPosition == nil, let start = locations.first {
					self.startPosition = self.annotation(for: start, isStart: true)
				}
				
				if isDone, let end = locations.last {
					self.endPosition = self.annotation(for: end, isStart: false)
				}
				
				self.route.append(MKPolyline(coordinates: locations.map { $0.coordinate }, count: locations.count))
				
				if isDone {
					completion(true)
				}
			}
			
			HealthKitManager.healthStore.execute(locQuery)
		}
		
		HealthKitManager.healthStore.execute(routeQuery)
	}
	
}
