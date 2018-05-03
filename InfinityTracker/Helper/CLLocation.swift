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
	/// - parameter timestamp: The timestamp for the weighted average, if `nil` the timestamp of the `target` will be used.
	func moveCloser(_ target: CLLocation, withOriginWeight originWeight: Double, timestamp: Date? = nil) -> CLLocation {
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
		return CLLocation(coordinate: res, altitude: h, horizontalAccuracy: target.horizontalAccuracy, verticalAccuracy: target.verticalAccuracy, course: target.course, speed: target.speed, timestamp: timestamp ?? target.timestamp)
	}
	
	/// Calculate additional positions between the receiver and the given location to ensure a maximum time interval between points.
	/// - parameter target: The end point of the route. This location must be after the receiver.
	/// - parameter deltaT: The maximum allowed time interval between points.
	func interpolateRoute(to target: CLLocation, maximumTimeInterval deltaT: TimeInterval) -> [CLLocation] {
		let destTimeInterval = target.timestamp.timeIntervalSince(self.timestamp)
		guard destTimeInterval > deltaT else {
			return [self, target]
		}
		
		return [self] + (1 ... Int(Foundation.floor(destTimeInterval / deltaT))).compactMap { inc in
			let incT = Double(inc) * deltaT
			guard incT != destTimeInterval else {
				return nil
			}
			
			let w = 1 - incT / destTimeInterval
			return self.moveCloser(target, withOriginWeight: w, timestamp: self.timestamp.addingTimeInterval(incT))
		} + [target]
	}
	
}
