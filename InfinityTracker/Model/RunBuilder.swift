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
	
	static let averageWeight = HKQuantity(unit: .pound(), doubleValue: 132)
	
	private let run: CompletedRun
	private let activityType = HKWorkoutActivityType.walking
	private(set) var completed = false
	private(set) var invalidated = false
	
	private let weight: HKQuantity?
	
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
	/// - parameter weight: The weight to use to calculate calories
	init(start: Date, weight: HKQuantity? = nil) {
		run = CompletedRun(start: start)
		self.weight = weight
		// TODO: Add parameter for activity type: run/walk
//		self.activityType = ...
	}
	
	func add(locations: [CLLocation]) -> [MKPolyline] {
		precondition(!invalidated, "This run builder has completed his job")
		
		var polylines = [MKPolyline]()
		for l in locations {
			if let prev = previousLocation {
				// FIXME: Move here the filtering algorithm
				let deltaD = l.distance(from: prev)
				let deltaC = deltaD.metersToKilometers() * 1.6*0.72 * (weight ?? RunBuilder.averageWeight).doubleValue(for: .pound()).rounded(to: 0)
				run.totalDistance += deltaD
				run.totalCalories += deltaC
				
				distance.append(HKQuantitySample(type: HealthKitManager.distanceType, quantity: HKQuantity(unit: .meter(), doubleValue: deltaD), start: prev.timestamp, end: l.timestamp))
				calories.append(HKQuantitySample(type: HealthKitManager.calorieType, quantity: HKQuantity(unit: .kilocalorie(), doubleValue: deltaC), start: prev.timestamp, end: l.timestamp))
				
				do {
					var coord = [prev, l].map { $0.coordinate }
					polylines.append(MKPolyline(coordinates: &coord, count: 2))
				}
				previousLocation = l
			}
		}
		
		run.route += polylines
		DispatchQueue.main.async {
			self.pendingLocationInsertion += 1
			self.route.insertRouteData(locations) { res, _ in
				DispatchQueue.main.async {
					self.pendingLocationInsertion -= 1
				}
			}
		}
		
		return polylines
	}
	
	func finishRun(end: Date, completion: @escaping (Run?) -> Void) {
		precondition(!invalidated, "This run builder has completed his job")
		
		run.end = end
		// If the run has a single position create a dot polyline
		if run.route.isEmpty, let prev = previousLocation {
			var coord = [prev.coordinate]
			run.route.append(MKPolyline(coordinates: &coord, count: 1))
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
				let workout = HKWorkout(activityType: self.activityType,
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
							var linkData = [HKSample]()
							HealthKitManager.healthStore.save(self.calories) { success, _ in
								if success {
									linkData.append(contentsOf: self.calories)
								}
								HealthKitManager.healthStore.save(self.distance) { success, _ in
									if success {
										linkData.append(contentsOf: self.distance)
									}
									
									if linkData.isEmpty {
										completion(self.run)
									} else {
										HealthKitManager.healthStore.add(linkData, to: workout) { _, _ in
											completion(self.run)
										}
									}
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
	
	var totalCalories: Double = 0
	var totalDistance: Double = 0
	var start: Date
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
	
	private(set) var realEnd: Date?
	
	fileprivate init(start: Date) {
		self.start = start
	}
	
}
