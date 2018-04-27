//
//  RunDetailController.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class RunDetailController: UIViewController {
	
	@IBOutlet weak var doneButton: UIButton!
	@IBOutlet weak var mapView: MKMapView!
	
	var run: Run!
	var displayCannotSaveAlert = false
	
	weak var runDetailDismissDelegate: DismissDelegate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupViews()
		
		if displayCannotSaveAlert {
			// TODO: Dispaly alert
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		mapView.addOverlays(run.route)
	}
	
	// MARK: User Interaction - Dismiss Controller
	
	@IBAction func handleDismissController(_ sender: UIButton) {
		runDetailDismissDelegate?.shouldDismiss(self)
	}
	
	private func setupViews() {
		doneButton.layer.masksToBounds = true
		doneButton.layer.cornerRadius = doneButton.frame.height/2
	}
	
}

// MARK: - MKMapViewDelegate

extension RunDetailController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if overlay is MKPolyline {
			let polylineRenderer = MKPolylineRenderer(overlay: overlay)
			polylineRenderer.strokeColor = Colors.orangeDark
			polylineRenderer.lineWidth = 6.0
			return polylineRenderer
		}
		
		return MKPolylineRenderer()
	}
	
}
