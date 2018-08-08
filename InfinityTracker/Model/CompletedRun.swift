//
//  CompletedRun.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 26/04/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import HealthKit
import MapKit

class CompletedRun: Run {
	
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
			var positions: [CLLocation] = []
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
				
				positions.append(contentsOf: locations)
				
				if isDone {
					var events = self.raw.workoutEvents ?? []
					// Remove any event at the beginning that's not a pause event
					if let pauseInd = events.index(where: { $0.type == .pause }) {
						events = Array(events.suffix(from: pauseInd))
					}
					var intervals: [DateInterval] = []
					var intervalStart = self.start
					var fullyScanned = false
					
					// Calculate the intervals when the workout was active
					while !events.isEmpty {
						let pause = events.removeFirst()
						intervals.append(DateInterval(start: intervalStart, end: pause.dateInterval.start))
						
						if let resume = events.index(where: { $0.type == .resume }) {
							intervalStart = events[resume].dateInterval.start
							let tmpEv = events.suffix(from: resume)
							if let pause = tmpEv.index(where: { $0.type == .pause }) {
								events = Array(tmpEv.suffix(from: pause))
							} else {
								// Empty the array as at the next cycle we expect the first element to be a pause
								events = []
							}
						} else {
							// Run ended while paused
							fullyScanned = true
							break
						}
					}
					if !fullyScanned {
						intervals.append(DateInterval(start: intervalStart, end: self.end))
					}
					
					// Isolate positions on active intervals
					for i in intervals {
						if let startPos = positions.lastIndex(where: { $0.timestamp <= i.start }) {
							var track = positions.suffix(from: startPos)
							if let afterEndPos = track.index(where: { $0.timestamp > i.end }) {
								track = track.prefix(upTo: afterEndPos)
							}
							
							self.route.append(MKPolyline(coordinates: track.map { $0.coordinate }, count: track.count))
						}
					}
					
					completion(true)
				}
			}
			
			HealthKitManager.healthStore.execute(locQuery)
		}
		
		HealthKitManager.healthStore.execute(routeQuery)
	}
	
}
