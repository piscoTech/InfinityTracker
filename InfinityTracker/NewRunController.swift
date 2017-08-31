//
//  NewRunController.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import CoreData

class NewRunController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var whiteViewOne: UIView!
    @IBOutlet weak var whiteViewTwo: UIView!
    @IBOutlet weak var whiteViewThree: UIView!
    @IBOutlet weak var startButtonCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var stopButtonCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var startButton: GradientButton!
    @IBOutlet weak var stopButton: GradientButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var sliderControl: UISlider!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    // MARK: Private Properties
    
    private var timer: Timer?
    private var run: Run?
    private let locationManager = CLLocationManager()
    
    // MARK: FilePrivate Properties
    
    fileprivate var locationsArray: [CLLocation] = []
    fileprivate var coordinates: [CLLocationCoordinate2D] = []
    fileprivate var previousLocation: CLLocation?
    fileprivate var duration: Int = 0
    fileprivate var distance: Double = 0.0
    fileprivate var speed: Double = 0.0
    fileprivate let averageWeight: Double = 132.0
    fileprivate var calories: Double = 0.0
    fileprivate var mapDelta: Double = 0.0050
    fileprivate var didStart: Bool = false
    
    // MARK: Delegates
    
    weak var newRunDismissDelegate: DismissDelegate?
    
    // MARK: LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupViews()
        startUpdatingLocations()
        setupMap()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        locationManager.stopUpdatingLocation()
        
        guard let timer = self.timer else {
            return
        }
        
        timer.invalidate()
    }
    
    // MARK: User Interaction - Start
    
    @IBAction func handleStartTapped() {
        didStart = true
        startRun()
    }
    
    // MARK: User Interaction - Stop
    
    @IBAction func handleStopTapped() {
        
        let actionSheet = UIAlertController(title: nil, message: "Are you sure you want to stop?", preferredStyle: .actionSheet)
        
        let stopAction = UIAlertAction(title: "Stop", style: .destructive) { [weak self] (action) in
            self?.didStart = false
            self?.stopRun()
            self?.saveCurrentTrack()
            self?.performSegue(withIdentifier: "RunDetailController", sender: self)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        
        actionSheet.addAction(stopAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: User Interaction - Zoom Slider
    
    @IBAction func sliderDidChangeValue() {
        
        let miles = Double(sliderControl.value)
        mapDelta = miles / 69.0
        
        var currentRegion = mapView.region
        currentRegion.span = MKCoordinateSpan(latitudeDelta: mapDelta, longitudeDelta: mapDelta)
        mapView.region = currentRegion
    }
    
    // MARK: User Interaction - Dismiss Controller
    
    func handleDismissController() {
        
        let actionSheet = UIAlertController(title: nil, message: "Are you sure you want to leave this screen?", preferredStyle: .actionSheet)
        
        let stopAction = UIAlertAction(title: "Leave", style: .destructive) { [weak self] (action) in
            
            guard self != nil else {
                return
            }
            
            self?.newRunDismissDelegate?.shouldDismiss(self!)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        
        actionSheet.addAction(stopAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: Start Run
    
    private func startRun() {
        
        startButton.isEnabled = false
        startButton.alpha = 1.0
        
        startButtonCenterXConstraint.constant -= 300
        stopButtonCenterXConstraint.constant -= 80
        
        UIView.animate(withDuration: 0.60, animations: {
            self.view.layoutIfNeeded()
            self.startButton.alpha = 0.0
            self.stopButton.alpha = 1.0
        }, completion : { (finished) in
            self.startButton.removeFromSuperview()
            self.stopButton.isEnabled = true
        })
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
    }
    
    // MARK: Update Timer
    
    func updateTimer(){
        duration += 1
        durationLabel.text = setupCounter(duration: duration)
    }
    
    // MARK: Stop Run
    
    private func stopRun() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: Setup Map
    
    private func setupMap() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = .standard
        mapView.userTrackingMode = .follow
    }
    
    // MARK: Update Locations
    
    private func startUpdatingLocations() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0.1
        locationManager.startUpdatingLocation()
    }
    
    // MARK: Add Polyline Helper
    
    fileprivate func addPolyLineToMap(locations: [CLLocation]) {
        var coordinates = locations.map({ (location: CLLocation!) -> CLLocationCoordinate2D in
            return location.coordinate
        })
        
        let polyline = MKPolyline(coordinates: &coordinates, count: 2)
        mapView.add(polyline)
    }
    
    // MARK: CoreData - Save Current Track
    
    private func saveCurrentTrack() {
        
        guard let runsCount = CoreDataManager.getRunsCount() else {
            return
        }
        
        let newTrack = Run(context: CoreDataManager.context)
        
        newTrack.name = "Run \(runsCount+1)"
        newTrack.distance = distance
        newTrack.duration = Int32(duration)
        newTrack.timestamp = NSDate()
        newTrack.calories = calories
        
        for location in locationsArray {
            let locationObject = Location(context: CoreDataManager.context)
            locationObject.latitude = location.coordinate.latitude
            locationObject.longitude = location.coordinate.longitude
            newTrack.addToLocations(locationObject)
        }
        
        CoreDataManager.saveContext()
        
    }
    
    // MARK: Update UI
    
    fileprivate func updateUI() {
        
        let distanceKM = distance.metersToKilometers().rounded(to: 1)
        distanceLabel.text = "\(distanceKM) km"
    }
    
    // MARK: PrepareForSegue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let navigationController = segue.destination as? UINavigationController, let destinationController = navigationController.viewControllers.first as? RunDetailController else {
            return
        }
        destinationController.locationsArray = locationsArray
        destinationController.runDetailDismissDelegate = self
        
    }
    
    // MARK: Setup Views
    
    private func setupViews() {
        
        stopButton.isEnabled = false
        stopButton.alpha = 0.25
        
        whiteViewOne.layer.cornerRadius = whiteViewOne.frame.height/2
        whiteViewOne.layer.masksToBounds = true
        
        whiteViewTwo.layer.cornerRadius = whiteViewTwo.frame.height/2
        whiteViewTwo.layer.masksToBounds = true
        
        whiteViewThree.layer.cornerRadius = whiteViewThree.frame.height/2
        whiteViewThree.layer.masksToBounds = true
        
        startButton.layer.cornerRadius = startButton.frame.height/2
        startButton.layer.masksToBounds = true
        
        stopButton.layer.cornerRadius = stopButton.frame.height/2
        stopButton.layer.masksToBounds = true
    }
    
    // MARK: Setup Navigation Bar
    
    private func setupNavigationBar() {
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        imageView.contentMode = .scaleAspectFit
        let image = Image.navbarLogo
        imageView.image = image
        navigationItem.titleView = imageView
        
        let leftButton = UIButton(type: .system)
        let quitButtonImage = Image.quitButton.withRenderingMode(.alwaysTemplate)
        leftButton.setImage(quitButtonImage, for: UIControlState.normal)
        leftButton.frame = CGRect(x:0, y:0, width:25, height:25)
        leftButton.addTarget(self, action: #selector(handleDismissController), for: .touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: leftButton)
        navigationItem.leftBarButtonItem = leftBarButton
    }
    
    
}


extension NewRunController: CLLocationManagerDelegate {
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let currentLocation = locations.last else {
            return
        }
        
        let currentLocationCoordinates = currentLocation.coordinate
        
        if didStart {
            
            if locationsArray.count > 0 {
                previousLocation = locationsArray[locationsArray.count - 1]
            }
            
            if let previousLocation = self.previousLocation {
                
                let delta = currentLocation.distance(from: previousLocation)
                distance += delta
                calories = distance.metersToKilometers()*1.6*0.72*averageWeight.rounded(to: 0)
                addPolyLineToMap(locations: [previousLocation, currentLocation])
                updateUI()
            }
            
        }
        
        let center = CLLocationCoordinate2D(latitude: currentLocationCoordinates.latitude, longitude: currentLocationCoordinates.longitude)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: mapDelta, longitudeDelta: mapDelta))
        
        mapView.setRegion(region, animated: true)
        
        locationsArray.append(currentLocation)
    }
    
}

extension NewRunController: MKMapViewDelegate {
    
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

extension NewRunController: DismissDelegate {
    
    // MARK: DismissDelegate
    
    func shouldDismiss(_ viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            self?.newRunDismissDelegate?.shouldDismiss(strongSelf)
        })
    }
    
    
}



