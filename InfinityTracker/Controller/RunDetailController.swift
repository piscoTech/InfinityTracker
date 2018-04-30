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
	
	// MARK: IBOutlets
	
	@IBOutlet weak var whiteViewThree: UIView!
	@IBOutlet weak var whiteViewTwo: UIView!
	@IBOutlet weak var whiteViewOne: UIView!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var durationLabel: UILabel!
	@IBOutlet weak var distanceLabel: UILabel!
	@IBOutlet weak var caloriesLabel: UILabel!
	
	// MARK: Properties
	
	var run: Run!
	var displayCannotSaveAlert: Bool! = false
	weak var runDetailDismissDelegate: DismissDelegate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard run != nil else {
			return
		}
		
		if displayCannotSaveAlert {
			DispatchQueue.main.async {
				// TODO: Dispaly alert
			}
		}
		
		setupViews()
	}
	
	private func setupViews() {
		navigationItem.title = run.name
		if runDetailDismissDelegate != nil {
			// Displaying details for a just-ended run
			navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleDismissController(_:)))
		}
		
		let del = Appearance()
		del.setupAppearance(for: mapView)
		mapView.delegate = del
		
		whiteViewOne.layer.masksToBounds = true
		whiteViewOne.layer.cornerRadius = whiteViewOne.frame.height/2
		
		whiteViewTwo.layer.masksToBounds = true
		whiteViewTwo.layer.cornerRadius = whiteViewTwo.frame.height/2
		
		whiteViewThree.layer.masksToBounds = true
		whiteViewThree.layer.cornerRadius = whiteViewThree.frame.height/2
		
		durationLabel.text = run?.duration.getDuration()
		
		let distance = run?.totalDistance ?? 0
		let distanceKM = distance.metersToKilometers().rounded(to: 3)
		distanceLabel.text = "\(distanceKM) km"
		
		let calories = (run?.totalCalories ?? 0).rounded(to: 0)
		caloriesLabel.text = "\(calories) kcal"
		
		var rect: MKMapRect?
		for p in run.route {
			if let r = rect {
				rect = MKMapRectUnion(r, p.boundingMapRect)
			} else {
				rect = p.boundingMapRect
			}
		}
		if let rect = rect {
			mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
			mapView.addOverlays(run.route)
		}
		
		if let start = run.startPosition {
			mapView.addAnnotation(start)
			del.startPosition = start
		}
		if let end = run.endPosition {
			mapView.addAnnotation(end)
			del.endPosition = end
		}
	}
	
	@IBAction func handleDismissController(_ sender: AnyObject) {
		runDetailDismissDelegate?.shouldDismiss(self)
	}
	
}
