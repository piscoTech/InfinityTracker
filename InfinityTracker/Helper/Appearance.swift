//
//  Appearance.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit
import MapKit

class Appearance: NSObject, MKMapViewDelegate {
	
	static let mapViewDelegate = Appearance()
	
	static let orangeLight = #colorLiteral(red: 0.9137254902, green: 0.7725490196, blue: 0.2901960784, alpha: 1)
    static let orangeDark = UIColor.orange
	
	static let disabledAlpha: CGFloat = 0.25
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if overlay is MKPolyline {
			let polylineRenderer = MKPolylineRenderer(overlay: overlay)
			polylineRenderer.strokeColor = Appearance.orangeDark
			polylineRenderer.lineWidth = 6.0
			return polylineRenderer
		}
		
		return MKPolylineRenderer()
	}
	
}
