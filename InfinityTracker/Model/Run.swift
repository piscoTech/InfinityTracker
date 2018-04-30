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
	
}
