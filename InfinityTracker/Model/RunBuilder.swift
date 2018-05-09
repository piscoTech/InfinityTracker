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
	/// The maximum time interval between two points of the workout route.
	let routeTimeAccuracy: TimeInterval = 2
	/// The time interval covered by each details saved to HealthKit.
	let detailsTimePrecision: TimeInterval = 15
	/// The time interval before the last added position to use to calculate the current pace.
	let paceTimePrecision: TimeInterval = 45
	
	var run: Run {
		return rawRun
	}
	private let rawRun: InProgressRun
	private let activityType: Activity
	var paused: Bool {
		return rawRun.paused
	}
	private(set) var completed = false
	private(set) var invalidated = false
	
	/// Weight for calories calculation, in kg.
	private let weight: Double
	
	/// The previous logical location processed.
	private var previousLocation: CLLocation?
	/// Every other samples to provide additional details to the workout to be saved to HealthKit.
	private var details: [HKQuantitySample] = []
	/// Additional details for the workout. Each added position create a raw detail.
	private var rawDetails: [(distance: Double, calories: Double, start: Date, end: Date)] = []
	/// The number of raw details yet to be compacted. This details are lcoated at the end of `rawDetails`.
	private var uncompactedRawDetails = 0
	
	private var pendingLocationInsertion = 0 {
		didSet {
			if pendingLocationInsertion == 0, let end = rawRun.realEnd, let compl = pendingSavingCompletion {
				finishRun(end: end, completion: compl)
			}
		}
	}
	/// The callback for the pending saving operation, when set saving will resume as soon as `pendingLocationInsertion` reaches 0.
	private var pendingSavingCompletion: ((Run?) -> Void)?
	private var route = HKWorkoutRouteBuilder(healthStore: HealthKitManager.healthStore, device: nil)
	
	/// Begin the construction of a new run.
	/// - parameter start: The start time of the run
	/// - parameter activityType: The type of activity being tracked
	/// - parameter weight: The weight to use to calculate calories
	init(start: Date, activityType: Activity, weight: HKQuantity) {
		rawRun = InProgressRun(type: activityType, start: start)
		self.weight = weight.doubleValue(for: .gramUnit(with: .kilo))
		self.activityType = activityType
	}
	
	func pause(_ date: Date) {
		guard rawRun.setPaused(true, date: date) else {
			return
		}
		
		flushDetails()
		rawRun.currentPace = 0
	}
	
	func resume(_ date: Date) -> [MKPolyline] {
		guard rawRun.setPaused(false, date: date) else {
			return []
		}
		
		if let cur = previousLocation {
			// Set the previous position to nil so a new separate track is started
			previousLocation = nil
			return add(locations: [cur])
		}
		
		return []
	}
	
	func add(locations: [CLLocation]) -> [MKPolyline] {
		precondition(!invalidated, "This run builder has completed his job")
		
		guard !paused else {
			previousLocation = locations.last
			return []
		}
		
		var polylines = [MKPolyline]()
		var smoothLocations: [CLLocation] = []
		
		for loc in locations {
			/// The logical positions after location smoothing to save to the workout route.
			let routeSmoothLoc: [CLLocation]
			
			if let prev = previousLocation {
				/// Real distance between the points, in meters.
				let deltaD = loc.distance(from: prev)
				/// Distance reduction considering accuracy, in meters.
				let deltaAcc = min(loc.horizontalAccuracy * accuracyInfluence, deltaD)
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
				/// The last logical position after location smoothing.
				let smoothLoc = prev.moveCloser(loc, withOriginWeight: locAvgWeight)
				/// Logical distance between the points after location smoothing, in meters.
				let smoothDelta = smoothLoc.distance(from: prev)
				
				addRawDetail(distance: smoothDelta, start: prev.timestamp, end: smoothLoc.timestamp)
				
				let routePositions = prev.interpolateRoute(to: smoothLoc, maximumTimeInterval: routeTimeAccuracy)
				polylines.append(MKPolyline(coordinates: routePositions.map { $0.coordinate }, count: routePositions.count))
				// Drop the first location as it is the last added location
				routeSmoothLoc = Array(routePositions[1...])
			} else {
				// Saving the first location
				if rawRun.startPosition == nil {
					// This can be reached also after every resume action, but the position must be marked only at the start
					markPosition(loc, isStart: true)
				}
				routeSmoothLoc = [loc]
			}
			
			smoothLocations.append(contentsOf: routeSmoothLoc)
			previousLocation = routeSmoothLoc.last
		}
		
		rawRun.route += polylines
		if !smoothLocations.isEmpty {
			DispatchQueue.main.async {
				self.pendingLocationInsertion += 1
				self.route.insertRouteData(smoothLocations) { res, _ in
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
		
		let ann = rawRun.annotation(for: location, isStart: isStart)
		
		if isStart {
			rawRun.startPosition = ann
		} else {
			rawRun.endPosition = ann
		}
	}
	
	/// Compact (if necessary) the raw details still not compacted in a single (one per each data type) HealthKit sample.
	/// - parameter flush: If set to `true` forces the uncompacted details to be compacted even if they don't cover the time interval specified by `detailsTimePrecision`. The default value is `false`.
	private func compactLastDetails(flush: Bool = false) {
		guard let end = rawDetails.last?.end, let lastCompactedEnd = details.last?.endDate ?? rawDetails.first?.start else {
			return
		}
		
		if !flush {
			guard end.timeIntervalSince(lastCompactedEnd) >= detailsTimePrecision else {
				return
			}
		}
		
		if let index = rawDetails.index(where: { $0.start >= lastCompactedEnd }) {
			let range = rawDetails.suffix(from: index)
			uncompactedRawDetails = 0
			guard let start = range.first?.start else {
				return
			}
			
			let detCalories = range.reduce(0) { $0 + $1.calories }
			let detDistance = range.reduce(0) { $0 + $1.distance }
			// This two samples must have same start and end.
			details.append(HKQuantitySample(type: HealthKitManager.distanceType, quantity: HKQuantity(unit: .meter(), doubleValue: detDistance), start: start, end: end))
			details.append(HKQuantitySample(type: HealthKitManager.calorieType, quantity: HKQuantity(unit: .kilocalorie(), doubleValue: detCalories), start: start, end: end))
		}
	}
	
	/// Save a raw retails.
	/// - parameter distance: The distance to add, in meters.
	/// - parameter start: The start of the time interval of the when the distance was run/walked.
	/// - parameter start: The end of the time interval of the when the distance was run/walked.
	private func addRawDetail(distance: Double, start: Date, end: Date) {
		rawRun.totalDistance += distance
		let calories: Double
		if distance > 0 {
			calories = activityType.caloriesFor(time: end.timeIntervalSince(start), distance: distance, weight: weight)
		} else {
			calories = 0
		}
		rawRun.totalCalories += calories
		
		rawDetails.append((distance: distance, calories: calories, start: start, end: end))
		uncompactedRawDetails += 1
		
		rawRun.currentPace = 0
		var paceDetailsCount = 0
		if let index = rawDetails.index(where: { end.timeIntervalSince($0.start) < paceTimePrecision }) {
			let range = rawDetails.suffix(from: index)
			paceDetailsCount = range.count
			if let s = range.first?.start {
				let d = range.reduce(0) { $0 + $1.distance }
				if d > 0 {
					rawRun.currentPace = end.timeIntervalSince(s) * 1000 / d
				}
			}
		}
		
		compactLastDetails()
		
		rawDetails = Array(rawDetails.suffix(max(paceDetailsCount, uncompactedRawDetails)))
	}
	
	/// Compacts all remaining raw details in samples for HealthKit.
	private func flushDetails() {
		compactLastDetails(flush: true)
		rawDetails = []
	}
	
	/// Completes the run and saves it to HealthKit.
	func finishRun(end: Date, completion: @escaping (Run?) -> Void) {
		precondition(!invalidated, "This run builder has completed his job")
		
		flushDetails()
		rawRun.end = end
		rawRun.currentPace = nil
		if let prev = previousLocation {
			if rawRun.route.isEmpty {
				// If the run has a single position create a dot polyline
				rawRun.route.append(MKPolyline(coordinates: [prev.coordinate], count: 1))
				markPosition(prev, isStart: true)
			}
			
			markPosition(prev, isStart: false)
		}
		
		guard !rawRun.route.isEmpty else {
			self.discard()
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
				let totalCalories = HKQuantity(unit: .kilocalorie(), doubleValue: self.rawRun.totalCalories)
				let totalDistance = HKQuantity(unit: .meter(), doubleValue: self.rawRun.totalDistance)

				let workout = HKWorkout(activityType: self.activityType.healthKitEquivalent,
										start: self.rawRun.start,
										end: self.rawRun.end,
										workoutEvents: self.rawRun.workoutEvents,
										totalEnergyBurned: totalCalories,
										totalDistance: totalDistance,
										device: HKDevice.local(),
										metadata: [HKMetadataKeyIndoorWorkout: false]
				)
				HealthKitManager.healthStore.save(workout) { success, _ in
					if success {
						// Save the route only if workout has been saved
						self.route.finishRoute(with: workout, metadata: nil) { route, _ in
							if self.details.isEmpty {
								completion(self.rawRun)
							} else {
								// This also save the samples
								HealthKitManager.healthStore.add(self.details, to: workout) { _, _ in
									completion(self.rawRun)
								}
							}
						}
					} else {
						// Workout failed to save, discard other data
						self.discard()
						completion(self.rawRun)
					}
				}
			} else {
				// Required data cannot be saved, return immediately
				self.discard()
				completion(self.rawRun)
			}
		}
	}
	
	func discard() {
		// This throws a strange error if no locations have been added
//		route.discard()
		invalidated = true
	}
	
}

fileprivate class InProgressRun: Run {
	
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
	
	/// The list of workouts event. The list is guaranteed to start with a pause event and alternate with a resume event. If the run has ended, i.e. setEnd(_:) has been called, the last event is a resume.
	private(set) var workoutEvents: [HKWorkoutEvent] = []
	
	var duration: TimeInterval {
		var events = self.workoutEvents
		var duration: TimeInterval = 0
		var intervalStart = self.start
		
		while !events.isEmpty {
			let pause = events.removeFirst()
			duration += pause.dateInterval.start.timeIntervalSince(intervalStart)
			
			if !events.isEmpty {
				let resume = events.removeFirst()
				intervalStart = resume.dateInterval.start
			} else {
				// Run currently paused
				return duration
			}
		}
		
		return duration + end.timeIntervalSince(intervalStart)
	}
	
	var currentPace: TimeInterval? = 0
	
	var paused: Bool {
		return (workoutEvents.last?.type ?? .resume) == .pause
	}
	
	var route: [MKPolyline] = []
	var startPosition: MKPointAnnotation?
	var endPosition: MKPointAnnotation?
	
	private(set) var realEnd: Date?
	
	fileprivate init(type: Activity, start: Date) {
		self.type = type
		self.start = start
	}
	
	/// Create an appropriate event for the run. Setting the pause state to the current state will do nothing.
	/// - returns: Whether the requested event has been added.
	func setPaused(_ paused: Bool, date: Date) -> Bool {
		guard self.paused != paused else {
			return false
		}
		
		workoutEvents.append(HKWorkoutEvent(type: paused ? .pause : .resume, dateInterval: DateInterval(start: date, duration: 0), metadata: nil))
		
		return true
	}
	
}
