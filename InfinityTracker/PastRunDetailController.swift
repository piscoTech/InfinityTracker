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
    
    var run: Run?
    var locationsArray: [CLLocation] = []
    
    // MARK: LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(handleEditName))
        
        guard run != nil else {
            return
        }
        
        let locations = run!.locations
        
        for location in locations! {
            let loc = location as! Location
            locationsArray.append(CLLocation(latitude: loc.latitude, longitude: loc.longitude))
        }
        
        addPolyLineToMap(locations: locationsArray)
        
        setupViews()
    }
    
    // MARK: Setup Views
    
    private func setupViews() {
        
        title = "Run Detail"
        
        whiteViewOne.layer.masksToBounds = true
        whiteViewOne.layer.cornerRadius = whiteViewOne.frame.height/2
        
        whiteViewTwo.layer.masksToBounds = true
        whiteViewTwo.layer.cornerRadius = whiteViewTwo.frame.height/2
        
        whiteViewThree.layer.masksToBounds = true
        whiteViewThree.layer.cornerRadius = whiteViewThree.frame.height/2
        
        let duration = Int(run!.duration)
        durationLabel.text = setupCounter(duration: duration)
        
        let distance = run!.distance
        let distanceKM = distance.metersToKilometers().rounded(to: 3)
        distanceLabel.text = "\(distanceKM) km"
        
        let calories = run!.calories.rounded(to: 0)
        caloriesLabel.text = "\(calories) kcal"
    }
    
    // MARK: Add Polyline Helper
    
    fileprivate func addPolyLineToMap(locations: [CLLocation]) {
        var coordinates = locations.map({ (location: CLLocation!) -> CLLocationCoordinate2D in
            return location.coordinate
        })
        
        let polyline = MKPolyline(coordinates: &coordinates, count: locationsArray.count)
        
        let rect = polyline.boundingMapRect
        
        mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
        
        mapView.add(polyline)
    }
    
    // MARK: User Interaction - Edit Walk Name
    
    func handleEditName() {
        
        let alertController = UIAlertController(title: "Type in a new name:", message: "", preferredStyle: .alert)
        
        let updateAction = UIAlertAction(title: "Update", style: .default, handler: { [weak self] alert in
            
            guard let newName = alertController.textFields?.first?.text else {
                return
            }
            
            guard !newName.isEmpty else {
                return
            }
            
            guard let runName = self?.run?.name else {
                return
            }
            
            CoreDataManager.updateRunName(currentValue: runName, newValue: newName)
            
            self?.navigationController?.popViewController(animated: true)
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) in
            
        })
        
        alertController.addTextField { (textField : UITextField!) in
            textField.placeholder = "Type the run name here.."
        }
        
        alertController.addAction(updateAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
}

extension PastRunDetailController: MKMapViewDelegate {
    
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
