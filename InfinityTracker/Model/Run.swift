//
//  Run.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 26/04/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import MapKit

protocol Run {
	
	///The total amount of energy burned in kilocalories
	var totalCalories: Double { get }
	/// The total distance in meters
	var totalDistance: Double { get }
	
	var start: Date { get }
	var end: Date { get }
	var duration: TimeInterval { get }
	
	var route: [MKPolyline] { get }

}

extension Run {
	
	var name: String {
		return start.getFormattedDateTime()
	}
	
}
