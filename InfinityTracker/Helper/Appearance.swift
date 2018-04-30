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
	
	static let disabledAlpha: CGFloat = 0.25
	
	private let pinIdentifier = "pin"
	var startPosition: MKPointAnnotation?
	var endPosition: MKPointAnnotation?
	
	func setupAppearance(for map: MKMapView) {
		map.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: pinIdentifier)
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
		var view: MKAnnotationView?
		if let start = startPosition, start === annotation {
			let ann = mapView.dequeueReusableAnnotationView(withIdentifier: pinIdentifier, for: annotation) as! MKPinAnnotationView
			ann.pinTintColor = MKPinAnnotationView.greenPinColor()
			
			view = ann
		}
		
		if let end = endPosition, end === annotation {
			let ann = mapView.dequeueReusableAnnotationView(withIdentifier: pinIdentifier, for: annotation) as! MKPinAnnotationView
			ann.pinTintColor = MKPinAnnotationView.redPinColor()
			
			view = ann
		}
		
		view?.canShowCallout = false
		view?.isEnabled = false
		
		return view
	}
	
}
