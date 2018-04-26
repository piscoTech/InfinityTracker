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
	
	private(set) var route: [MKPolyline] = []
	
	init?(raw: HKWorkout) {
		if !HealthKitManager.workoutTypes.contains(raw.workoutActivityType) {
			return nil
		}
		
		self.raw = raw
	}
	
}
