//
//  PastRunDetailController.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class PastRunDetailController: UIViewController {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
        guard run != nil else {
            return
        }
		
		self.title = run.start.getFormattedDateTime()
        mapView.addOverlays(run.route)
        setupViews()
    }
    
    private func setupViews() {
        title = "Run Detail"
        
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
    }
    
}

// MARK: - MKMapViewDelegate

extension PastRunDetailController: MKMapViewDelegate {
    
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
