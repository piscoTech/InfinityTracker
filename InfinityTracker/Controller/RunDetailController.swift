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
	
	private let routePadding: CGFloat = 20
	private let routePaddingBottom: CGFloat = 160
	
	// MARK: IBOutlets
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var details: DetailView!
	
	// MARK: Properties
	
	var run: Run!
	var displayCannotSaveAlert: Bool! = false
	weak var runDetailDismissDelegate: DismissDelegate?
	private let mapViewDelegate = Appearance()
	
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
		run.loadAdditionalData { res in
			guard res else {
				return
			}
			
			DispatchQueue.main.async {
				var rect: MKMapRect?
				for p in self.run.route {
					if let r = rect {
						rect = MKMapRectUnion(r, p.boundingMapRect)
					} else {
						rect = p.boundingMapRect
					}
				}
				if let rect = rect {
					self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: self.routePadding * 2, left: self.routePadding, bottom: self.routePadding + self.routePaddingBottom, right: self.routePadding), animated: false)
					self.mapView.addOverlays(self.run.route, level: Appearance.overlayLevel)
				}
				
				if let start = self.run.startPosition {
					self.mapView.addAnnotation(start)
					self.mapViewDelegate.startPosition = start
				}
				if let end = self.run.endPosition {
					self.mapView.addAnnotation(end)
					self.mapViewDelegate.endPosition = end
				}
			}
		}
	}
	
	private func setupViews() {
		navigationItem.title = run.name
		if runDetailDismissDelegate != nil {
			// Displaying details for a just-ended run
			navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleDismissController(_:)))
		}
		
		mapViewDelegate.setupAppearance(for: mapView)
		mapView.delegate = mapViewDelegate
		
		details.update(for: run)
	}
	
	@IBAction func handleDismissController(_ sender: AnyObject) {
		runDetailDismissDelegate?.shouldDismiss(self)
	}
	
}
