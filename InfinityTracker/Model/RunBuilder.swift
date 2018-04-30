//
//  RunBuilder.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 26/04/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import MapKit
import HealthKit

class RunBuilder {
	
	/// Distance under which to drop the position.
	let dropThreshold = 6.0
	/// Ranges in which move location point closer to the origin, the weight of the origin must be between 0 and 1 inclusive.
	let moveCloserThreshold: [(range: ClosedRange<Double>, originWeight: Double)] = [(7.5 ... 15.0, 0.875), (15.0 ... 30.0, 0.7)]
	/// Maximum allowed speed, in m/s.
	let thresholdSpeed = 6.5
	/// The percentage of horizontal accuracy to subtract from the distance between two points.
	let accuracyInfluence = 0.6
	
	private let run: CompletedRun
	private let activityType: Activity
	private(set) var completed = false
	private(set) var invalidated = false
	
	/// Weight for calories calculation, in kg.
	private let weight: Double
	
	private var previousLocation: CLLocation?
	private var distance: [HKQuantitySample] = []
	private var calories: [HKQuantitySample] = []
	
	private var pendingLocationInsertion = 0 {
		didSet {
			if pendingLocationInsertion == 0, let end = run.realEnd, let compl = pendingSavingCompletion {
				finishRun(end: end, completion: compl)
			}
		}
	}
	/// The callback for the pending saving operation, when set saving will resume as soon as `pendingLocationInsertion` reaches 0.
	private var pendingSavingCompletion: ((Run?) -> Void)?
	private var route = HKWorkoutRouteBuilder(healthStore: HealthKitManager.healthStore, device: nil)
	
	var duration: TimeInterval {
		return run.duration
	}
	
	var totalDistance: Double {
		return run.totalDistance
	}
	
	/// Begin the construction of a new run.
	/// - parameter start: The start time of the run
	/// - parameter activityType: The type of activity being tracked
	/// - parameter weight: The weight to use to calculate calories
	init(start: Date, activityType: Activity, weight: HKQuantity) {
		run = CompletedRun(type: activityType, start: start)
		self.weight = weight.doubleValue(for: .gramUnit(with: .kilo))
		self.activityType = activityType
	}
	
	func add(locations: [CLLocation]) -> [MKPolyline] {
		precondition(!invalidated, "This run builder has completed his job")
		
		var polylines = [MKPolyline]()
		var smoothLocations: [CLLocation] = []
		
		for loc in locations {
			/// The logical position after location smoothing.
			let smoothLoc: CLLocation
			
			if let prev = previousLocation {
				/// Distance reduction considering accuracy, in meters.
				let deltaAcc = loc.horizontalAccuracy * accuracyInfluence
				/// Real distance between the points, in meters.
				let deltaD = loc.distance(from: prev)
				/// Logical distance between the points before location smoothing, in meters.
				let delta = deltaD - deltaAcc
				/// Temporal distance between the points, in seconds.
				let deltaT = loc.timestamp.timeIntervalSince(prev.timestamp)
				/// The weight of the previous point in the weighted average between the points, percentage.
				var smoothWeight: Double?
				/// Logical speed of the movement between the points before location smoothing, in m/s.
				let speed = delta / deltaT
				if speed > thresholdSpeed || delta < dropThreshold {
					continue
				} else if let (_, locAvgWeight) = moveCloserThreshold.first(where: { $0.range.contains(delta) }) {
					smoothWeight = locAvgWeight
				}
				
				// Correct the weight of the origin to move the other point closer by deltaAcc
				let locAvgWeight = 1 - (1 - (smoothWeight ?? 0)) * (1 - deltaAcc / deltaD)
				smoothLoc = prev.moveCloser(loc, withOriginWeight: locAvgWeight)
				/// Logical distance between the points after location smoothing, in meters.
				let smoothDelta = smoothLoc.distance(from: prev)
				
				run.totalDistance += smoothDelta
				distance.append(HKQuantitySample(type: HealthKitManager.distanceType, quantity: HKQuantity(unit: .meter(), doubleValue: smoothDelta), start: prev.timestamp, end: loc.timestamp))
				if smoothDelta > 0 {
					let deltaC = activityType.caloriesFor(time: deltaT, distance: smoothDelta, weight: weight)
					run.totalCalories += deltaC
					calories.append(HKQuantitySample(type: HealthKitManager.calorieType, quantity: HKQuantity(unit: .kilocalorie(), doubleValue: deltaC), start: prev.timestamp, end: loc.timestamp))
				}
				
				do {
					var coord = [prev, loc].map { $0.coordinate }
					polylines.append(MKPolyline(coordinates: &coord, count: 2))
				}
			} else {
				// Saving the first location
				markPosition(loc, isStart: true)
				smoothLoc = loc
			}
			
			smoothLocations.append(smoothLoc)
			previousLocation = smoothLoc
		}
		
		run.route += polylines
		if !smoothLocations.isEmpty {
			DispatchQueue.main.async {
				self.pendingLocationInsertion += 1
				self.route.insertRouteData(locations) { res, _ in
					DispatchQueue.main.async {
						self.pendingLocationInsertion -= 1
					}
				}
			}
		}
		
		return polylines
	}
	
	private func markPosition(_ location: CLLocation, isStart: Bool) {
		precondition(!invalidated, "This run builder has completed his job")
		
		let ann = run.annotation(for: location, isStart: isStart)
		
		if isStart {
			run.startPosition = ann
		} else {
			run.endPosition = ann
		}
	}
	
	func finishRun(end: Date, completion: @escaping (Run?) -> Void) {
		precondition(!invalidated, "This run builder has completed his job")
		
		run.end = end
		if let prev = previousLocation {
			if run.route.isEmpty {
				// If the run has a single position create a dot polyline
				var coord = [prev.coordinate]
				run.route.append(MKPolyline(coordinates: &coord, count: 1))
				markPosition(prev, isStart: true)
			}
			
			markPosition(prev, isStart: false)
		}
		
		guard !run.route.isEmpty else {
			route.discard()
			completion(nil)
			return
		}
		DispatchQueue.main.async {
			guard self.pendingLocationInsertion == 0 else {
				self.pendingSavingCompletion = completion
				
				return
			}
			
			self.completed = true
			self.invalidated = true
			
			if HealthKitManager.canSaveWorkout() != .none {
				let totalCalories = HKQuantity(unit: .kilocalorie(), doubleValue: self.run.totalCalories)
				let totalDistance = HKQuantity(unit: .meter(), doubleValue: self.run.totalCalories)
				let workout = HKWorkout(activityType: self.activityType.healthKitEquivalent,
										start: self.run.start,
										end: self.run.end,
										duration: self.run.duration,
										totalEnergyBurned: totalCalories,
										totalDistance: totalDistance,
										device: HKDevice.local(),
										metadata: [HKMetadataKeyIndoorWorkout: false]
				)
				HealthKitManager.healthStore.save(workout) { success, _ in
					if success {
						// Save the route only if workout has been saved
						self.route.finishRoute(with: workout, metadata: nil) { route, _ in
							let linkData = self.calories + self.distance
							HealthKitManager.healthStore.save(linkData) { success, _ in
								if success {
									HealthKitManager.healthStore.add(linkData, to: workout) { _, _ in
										completion(self.run)
									}
								} else {
									completion(self.run)
								}
							}
						}
					} else {
						// Workout failed to save, discard other data
						self.route.discard()
						completion(self.run)
					}
				}
			} else {
				// Required data cannot be saved, return immediately
				self.route.discard()
				completion(self.run)
			}
		}
	}
	
	func discard() {
		route.discard()
		invalidated = true
	}
	
}

fileprivate class CompletedRun: Run {
	
	let type: Activity
	
	var totalCalories: Double = 0
	var totalDistance: Double = 0
	let start: Date
	var end: Date {
		get {
			return realEnd ?? Date()
		}
		set {
			realEnd = newValue
		}
	}
	var duration: TimeInterval {
		return end.timeIntervalSince(start)
	}
	
	var route: [MKPolyline] = []
	var startPosition: MKPointAnnotation?
	var endPosition: MKPointAnnotation?
	
	private(set) var realEnd: Date?
	
	fileprivate init(type: Activity, start: Date) {
		self.type = type
		self.start = start
	}
	
}
