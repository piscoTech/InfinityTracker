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
    var locationsArray: [CLLocation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
        guard run != nil else {
            return
        }
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(handleEditName))
        
        let locations = run.locations
		var smoothDistance = 0.0
		var smoothCalories = 0.0
		
		let dropThreshold = 1.0
		let moveCloserThreshold = 3.0
		/// The weight of the origin when computing the average between two locations. Must be between 0 and 1 inclusive.
		let moveCloserOriginWeight = 0.8
		
        for location in locations! {
            let tmp = location as! Location
			let loc = CLLocation(latitude: tmp.latitude, longitude: tmp.longitude)
			let smoothLoc: CLLocation
			if let prev = locationsArray.last {
				let delta = loc.distance(from: prev)
				let deltaT = loc.timestamp.timeIntervalSince(prev.timestamp)
				let smoothDelta: Double
				
				if delta <= dropThreshold {
					continue
				} else if delta < moveCloserThreshold {
					smoothLoc = moveCloser(to: prev, target: loc, originWeight: moveCloserOriginWeight)
					smoothDelta = smoothLoc.distance(from: prev)
				} else {
					smoothLoc = loc
					smoothDelta = delta
				}
				
				smoothDistance += smoothDelta
				// FIXME: This needs to be parametric
				let deltaC = Activity.walking.caloriesFor(time: deltaT, distance: smoothDelta, weight: 67)
				smoothCalories += deltaC
			} else {
				smoothLoc = loc
			}
			
            locationsArray.append(smoothLoc)
        }
		
		print("Smoothed distance: \(smoothDistance)")
		print("Smoothed calories: \(smoothCalories)")
        addPolyLineToMap(locations: locationsArray)
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
        
        let distance = run?.distance ?? 0
        let distanceKM = distance.metersToKilometers().rounded(to: 3)
        distanceLabel.text = "\(distanceKM) km"
        
        let calories = run!.calories.rounded(to: 0)
        caloriesLabel.text = "\(calories) kcal"
    }
    
    fileprivate func addPolyLineToMap(locations: [CLLocation]) {
        var coordinates = locations.map({ (location: CLLocation!) -> CLLocationCoordinate2D in
            return location.coordinate
        })
        
        let polyline = MKPolyline(coordinates: &coordinates, count: locationsArray.count)
        let rect = polyline.boundingMapRect
        
        mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
        mapView.add(polyline)
    }
    
    @objc func handleEditName() {
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
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alertController.addTextField { (textField : UITextField!) in
            textField.placeholder = "Type the run name here..."
        }
        
        alertController.addAction(updateAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
}

extension PastRunDetailController {
	
	private func degreeToRadian(_ angle: CLLocationDegrees) -> Double {
		return angle / 180.0 * .pi
	}
	
	private func radianToDegree(_ radian: Double) -> CLLocationDegrees {
		return radian * 180.0 / .pi
	}
	
	private func moveCloser(to origin: CLLocation, target: CLLocation, originWeight: Double) -> CLLocation {
		precondition(originWeight >= 0 && originWeight <= 1, "Weight must be in 0...1")
		var x = 0.0
		var y = 0.0
		var z = 0.0
		var h = 0.0
		
		let list = [(origin, originWeight), (target, 1-originWeight)]
		for (coord, weight) in list {
			let lat = degreeToRadian(coord.coordinate.latitude)
			let lon = degreeToRadian(coord.coordinate.longitude)
			
			x += cos(lat) * cos(lon) * weight
			y += cos(lat) * sin(lon) * weight
			z += sin(lat) * weight
			h += coord.altitude * weight
		}
		
		// Sum of weights is 1
//		x = x/CGFloat(listCoords.count)
//		y = y/CGFloat(listCoords.count)
//		z = z/CGFloat(listCoords.count)
		
		let lon = atan2(y, x)
		let hyp = sqrt(x*x + y*y)
		let lat = atan2(z, hyp)
		
		let res = CLLocationCoordinate2D(latitude: radianToDegree(lat), longitude: radianToDegree(lon))
		return CLLocation(coordinate: res, altitude: h, horizontalAccuracy: target.horizontalAccuracy, verticalAccuracy: target.verticalAccuracy, course: target.course, speed: target.speed, timestamp: target.timestamp)
	}
	
}

// MARK: - MKMapViewDelegate

extension PastRunDetailController: MKMapViewDelegate {
    
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
