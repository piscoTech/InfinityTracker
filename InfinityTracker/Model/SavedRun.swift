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
	
	private var cachedRoute: [MKPolyline]?
	var route: [MKPolyline] {
		return cachedRoute ?? updateRouteCache()
	}
	
	private(set) var startPosition: MKPointAnnotation?
	private(set) var endPosition: MKPointAnnotation?
	
	init?(raw: HKWorkout) {
		guard let type = Activity.fromHealthKitEquivalent(raw.workoutActivityType) else {
			return nil
		}
		
		self.raw = raw
		self.type = type
	}
	
	private func updateRouteCache() -> [MKPolyline] {
		let res: [MKPolyline] = []
		
		// FIXME: Implement me :(
		
		cachedRoute = res
		return res
	}
	
}
