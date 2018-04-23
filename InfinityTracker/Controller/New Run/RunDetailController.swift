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
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Properties
    
    var locationsArray: [CLLocation]?
    
    // MARK: Delegates
    
    weak var runDetailDismissDelegate: DismissDelegate?
    
    // MARK: LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Run Detail"
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addPolyLineToMap(locations: locationsArray!)
    }
    
    // MARK: User Interaction - Dismiss Controller
    
    @IBAction func handleDismissController(_ sender: UIButton) {
        runDetailDismissDelegate?.shouldDismiss(self)
    }
    
    // MARK: Add Polyline Helper
    
    fileprivate func addPolyLineToMap(locations: [CLLocation]) {
        var coordinates = locations.map({ (location: CLLocation!) -> CLLocationCoordinate2D in
            return location.coordinate
        })
        
        let polyline = MKPolyline(coordinates: &coordinates, count: locationsArray!.count)
        
        let rect = polyline.boundingMapRect
        
        mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
        
        mapView.add(polyline)
    }
    
    // MARK: Setup Views
    
    private func setupViews() {
        doneButton.layer.masksToBounds = true
        doneButton.layer.cornerRadius = doneButton.frame.height/2
    }
    
}

extension RunDetailController: MKMapViewDelegate {
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline{
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = Colors.orangeDark
            polylineRenderer.lineWidth = 6.0
            return polylineRenderer
        }
        
        return MKPolylineRenderer()
    }
    
}
