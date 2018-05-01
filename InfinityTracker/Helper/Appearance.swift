//
//  Appearance.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit
import MapKit

/// Contains all constants representing the appearance of the app. An instance can be used as `MKMapViewDelegate` to uniform the appearance of the maps.
class Appearance: NSObject, MKMapViewDelegate {
	
	static let orangeLight = #colorLiteral(red: 0.9137254902, green: 0.7725490196, blue: 0.2901960784, alpha: 1)
    static let orangeDark = UIColor.orange
	static let detailsColor = #colorLiteral(red: 1, green: 0.4941176471, blue: 0.3803921569, alpha: 1)
	
	static let appLogo: UIImage = #imageLiteral(resourceName: "infinityLogo")
	static let emptyState: UIImage = #imageLiteral(resourceName: "emptyState")
	static let navBarLogo: UIImage = #imageLiteral(resourceName: "navBarLogo")
	
	static let disabledAlpha: CGFloat = 0.25
	
	// MARK: - Formatting
	
	static private let missingNumber = "–"
	
	static let distanceF: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.usesSignificantDigits = false
		formatter.maximumFractionDigits = 2
		
		return formatter
	}()
	
	static let caloriesF: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.usesSignificantDigits = false
		formatter.maximumFractionDigits = 1
		
		return formatter
	}()
	
	/// Format a distance in kilometers.
	/// - parameter distance: The distance to format, in meters.
	/// - parameter addUnit: Whether or not to add the unit, i.e. `km`.
	static func format(distance: Double?, addUnit: Bool = true) -> String {
		let num: String
		if let raw = distanceF.string(from: NSNumber(value: (distance ?? 0) / 1000)) {
			num = raw
		} else {
			num = missingNumber
		}
		
		return num + (addUnit ? " km" : "")
	}
	
	/// Format a duration in hours, minutes and seconds.
	/// - parameter duration: The duration to format, in seconds.
	static func format(duration: TimeInterval?) -> String {
		return (duration ?? 0).getDuration()
	}
	
	/// Format burned calories in kilocalories.
	/// - parameter calories: The calories to format, in kilocalories.
	/// - parameter addUnit: Whether or not to add the unit, i.e. `kcal`.
	static func format(calories: Double?, addUnit: Bool = true) -> String {
		let num: String
		if let raw = caloriesF.string(from: NSNumber(value: calories ?? 0)) {
			num = raw
		} else {
			num = missingNumber
		}
		
		return num + (addUnit ? " kcal" : "")
	}
	
	/// Format a pace in hours, minutes and seconds per kilometer.
	/// - parameter pace: The pace to format, in seconds per kilometer.
	static func format(pace: Double?) -> String {
		return (pace ?? 0).getDuration(hideHours: true) + "/km"
	}
	
	// MARK: - MKMapViewDelegate
	
	private let pinIdentifier = "pin"
	var startPosition: MKPointAnnotation?
	var endPosition: MKPointAnnotation?
	static let overlayLevel = MKOverlayLevel.aboveRoads
	
	func setupAppearance(for map: MKMapView) {
		map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: pinIdentifier)
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if overlay is MKPolyline {
			let polylineRenderer = MKPolylineRenderer(overlay: overlay)
			polylineRenderer.strokeColor = Appearance.orangeDark
			polylineRenderer.lineWidth = 6.0
			return polylineRenderer
		}
		
		return MKPolylineRenderer()
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		var view: MKMarkerAnnotationView?
		if let start = startPosition, start === annotation {
			let ann = mapView.dequeueReusableAnnotationView(withIdentifier: pinIdentifier, for: annotation) as! MKMarkerAnnotationView
			ann.markerTintColor = MKPinAnnotationView.greenPinColor()
			
			view = ann
		}
		
		if let end = endPosition, end === annotation {
			let ann = mapView.dequeueReusableAnnotationView(withIdentifier: pinIdentifier, for: annotation) as! MKMarkerAnnotationView
			ann.markerTintColor = MKPinAnnotationView.redPinColor()
			
			view = ann
		}
		
		view?.titleVisibility = .adaptive
		
		return view
	}
	
}
