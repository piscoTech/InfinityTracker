//
//  CLLocation.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 29/04/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import CoreLocation

extension CLLocation {
	
	private func degreeToRadian(_ angle: CLLocationDegrees) -> Double {
		return angle / 180.0 * .pi
	}
	
	private func radianToDegree(_ radian: Double) -> CLLocationDegrees {
		return radian * 180.0 / .pi
	}
	
	/// Calculate a weighted average between `self` and the passed location with weight `originWeight` for `self` and `1 - originWeight` for the given location.
	/// - parameter target: The other location.
	/// - parameter originWeight: The weight for `self` in the weighted average, must be between `0` and `1` inclusive.
	func moveCloser(_ target: CLLocation, withOriginWeight originWeight: Double) -> CLLocation {
		precondition(originWeight >= 0 && originWeight <= 1, "Weight must be in 0...1")
		var x = 0.0
		var y = 0.0
		var z = 0.0
		var h = 0.0
		
		let list = [(self, originWeight), (target, 1 - originWeight)]
		for (coord, weight) in list {
			let lat = degreeToRadian(coord.coordinate.latitude)
			let lon = degreeToRadian(coord.coordinate.longitude)
			
			x += cos(lat) * cos(lon) * weight
			y += cos(lat) * sin(lon) * weight
			z += sin(lat) * weight
			h += coord.altitude * weight
		}
		
		// Sum of weights is 1
		//x = x/CGFloat(listCoords.count)
		//y = y/CGFloat(listCoords.count)
		//z = z/CGFloat(listCoords.count)
		
		let lon = atan2(y, x)
		let hyp = sqrt(x*x + y*y)
		let lat = atan2(z, hyp)
		
		let res = CLLocationCoordinate2D(latitude: radianToDegree(lat), longitude: radianToDegree(lon))
		return CLLocation(coordinate: res, altitude: h, horizontalAccuracy: target.horizontalAccuracy, verticalAccuracy: target.verticalAccuracy, course: target.course, speed: target.speed, timestamp: target.timestamp)
	}
	
}
