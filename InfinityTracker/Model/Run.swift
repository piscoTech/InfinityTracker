//
//  Run.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 26/04/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import MapKit

protocol Run {
	
	var type: Activity { get }
	
	///The total amount of energy burned in kilocalories
	var totalCalories: Double { get }
	/// The total distance in meters
	var totalDistance: Double { get }
	
	var start: Date { get }
	var end: Date { get }
	var duration: TimeInterval { get }
	
	var route: [MKPolyline] { get }
	var startPosition: MKPointAnnotation? { get }
	var endPosition: MKPointAnnotation? { get }
	
	/// Load all additional data such as the workout route. If all data is already loaded this method may not be implemented.
	func loadAdditionalData(completion: @escaping (Bool) -> Void)

}

extension Run {
	
	var name: String {
		return start.getFormattedDateTime()
	}
	
	func annotation(for location: CLLocation, isStart: Bool) -> MKPointAnnotation {
		let ann = MKPointAnnotation()
		ann.coordinate = location.coordinate
		
		return ann
	}
	
	func loadAdditionalData(completion: @escaping (Bool) -> Void) {
		completion(true)
	}
	
}
