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
import MBLibrary
import HealthKit

class NewRunController: UIViewController {
	
	// MARK: IBOutlets
	
	@IBOutlet weak var whiteViewOne: UIView!
	@IBOutlet weak var whiteViewTwo: UIView!
	@IBOutlet weak var whiteViewThree: UIView!
	@IBOutlet weak var startButton: GradientButton!
	@IBOutlet weak var stopButton: GradientButton!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var sliderControl: UISlider!
	@IBOutlet weak var distanceLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!
	
	// MARK: Private Properties
	
	private var timer: Timer?
	private var run: RunBuilder! {
		willSet {
			precondition(run == nil, "Cannot start multiple runs")
		}
	}
	private let locationManager = CLLocationManager()
	
	// MARK: FilePrivate Properties
	
	/// The last registered position when the workout was not yet started or paused
	private var previousLocation: CLLocation?
	
	private var mapDelta: Double = 0.0050
	
	private var didStart: Bool {
		return run != nil
	}
	private var didEnd = false
	private var cannotSaveAlertDisplayed = false
	
	// MARK: Delegates
	
	weak var newRunDismissDelegate: DismissDelegate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		(UIApplication.shared.delegate as? AppDelegate)?.newRunController = self
		
		setupNavigationBar()
		setupViews()
		startUpdatingLocations()
		setupMap()
		
		DispatchQueue.main.async {
			if HealthKitManager.canSaveWorkout() != .full {
				// TODO: If no health write permission, show alert no data will be saved
				self.cannotSaveAlertDisplayed = true
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		locationManager.stopUpdatingLocation()
		
		guard let timer = self.timer else {
			return
		}
		
		timer.invalidate()
	}
	
	@IBAction func handleStartTapped() {
		startRun()
	}
	
	@IBAction func handleStopTapped() {
		let actionSheet = UIAlertController(title: nil, message: "Are you sure you want to stop?", preferredStyle: .actionSheet)
		
		let stopAction = UIAlertAction(title: "Stop", style: .destructive) { [weak self] (action) in
			self?.manualStop()
		}
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
		
		actionSheet.addAction(stopAction)
		actionSheet.addAction(cancelAction)
		
		self.present(actionSheet, animated: true, completion: nil)
	}
	
	private func manualStop() {
		guard !didEnd else {
			return
		}
		
		self.didEnd = true
		self.stopRun()
		run.finishRun(end: Date()) { res in
			DispatchQueue.main.async {
				if let run = res {
					self.performSegue(withIdentifier: "RunDetailController", sender: run)
				} else {
					self.dismiss(animated: true)
				}
			}
		}
	}
	
	func checkIfStopNeeded() {
		if CLLocationManager.locationServicesEnabled() {
			let status = CLLocationManager.authorizationStatus()
			if status == .authorizedWhenInUse || status == .authorizedAlways {
				return
			}
		}
		
		manualStop()
	}
	
	@IBAction func sliderDidChangeValue() {
		let miles = Double(sliderControl.value)
		mapDelta = miles / 69.0
		
		var currentRegion = mapView.region
		currentRegion.span = MKCoordinateSpan(latitudeDelta: mapDelta, longitudeDelta: mapDelta)
		mapView.region = currentRegion
	}
	
	@objc func handleDismissController() {
		let actionSheet = UIAlertController(title: nil, message: "Are you sure you want to leave this screen?", preferredStyle: .actionSheet)
		let stopAction = UIAlertAction(title: "Leave", style: .destructive) { [weak self] (action) in
			guard self != nil else {
				return
			}
			
			self?.newRunDismissDelegate?.shouldDismiss(self!)
		}
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
		
		actionSheet.addAction(stopAction)
		actionSheet.addAction(cancelAction)
		
		self.present(actionSheet, animated: true, completion: nil)
	}
	
	private func startRun() {
		// Remove next lines, and change Start to Pause
		startButton.isEnabled = false
		startButton.alpha = 1.0
		
//		startButtonCenterXConstraint.constant -= 300
//		stopButtonCenterXConstraint.constant = 0
		
		UIView.animate(withDuration: 0.60, animations: {
			self.view.layoutIfNeeded()
			// Remove next line, Start should remain enabled as Pause
			self.startButton.alpha = 0.25
			self.stopButton.alpha = 1.0
		}) { (finished) in
//			self.startButton.removeFromSuperview()
			self.stopButton.isEnabled = true
		}
		
		run = RunBuilder(start: Date())
		timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
	}
	
	@objc func updateTimer() {
		durationLabel.text = (run?.totalDistance ?? 0).getDuration()
	}
	
	private func stopRun() {
		locationManager.stopUpdatingLocation()
	}
	
	private func setupMap() {
		mapView.delegate = self
		mapView.showsUserLocation = true
		mapView.mapType = .standard
		mapView.userTrackingMode = .follow
	}
	
	private func startUpdatingLocations() {
		locationManager.delegate = self
		locationManager.activityType = .fitness
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.distanceFilter = 0.1
		locationManager.allowsBackgroundLocationUpdates = true
		locationManager.startUpdatingLocation()
	}
	
	fileprivate func updateUI() {
		let distanceKM = run.totalDistance.metersToKilometers().rounded(to: 1)
		distanceLabel.text = "\(distanceKM) km"
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let navigationController = segue.destination as? UINavigationController, let destinationController = navigationController.viewControllers.first as? RunDetailController, let run = sender as? Run else {
			return
		}
		
		destinationController.run = run
		destinationController.runDetailDismissDelegate = self
		destinationController.displayCannotSaveAlert = HealthKitManager.canSaveWorkout() != .full
	}
	
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
		
		updateTimer()
	}
	
	private func setupNavigationBar() {
		let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
		imageView.contentMode = .scaleAspectFit
		let image = Image.navbarLogo
		imageView.image = image
		navigationItem.titleView = imageView
		
		let leftBarButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(handleDismissController))
		navigationItem.leftBarButtonItem = leftBarButton
	}
	
}

// MARK: - CLLocationManagerDelegate

extension NewRunController: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let current = locations.last {
			let region = MKCoordinateRegion(center: current.coordinate, span: MKCoordinateSpan(latitudeDelta: mapDelta, longitudeDelta: mapDelta))
			mapView.setRegion(region, animated: true)
		}
		
		guard !didEnd else {
			return
		}
		
		if didStart {
			let locList: [CLLocation]
			if let prev = previousLocation {
				locList = [prev] + locations
				previousLocation = nil
			} else {
				locList = locations
			}
			
			mapView.addOverlays(run.add(locations: locList))
		} else if let loc = locations.last {
			previousLocation = loc
		}
	}
	
}

// MARK: - MKMapViewDelegate

extension NewRunController: MKMapViewDelegate {
	
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

// MARK: - DismissDelegate

extension NewRunController: DismissDelegate {
	
	func shouldDismiss(_ viewController: UIViewController) {
		viewController.dismiss(animated: true, completion: { [weak self] in
			guard let strongSelf = self else {
				return
			}
			
			self?.newRunDismissDelegate?.shouldDismiss(strongSelf)
		})
	}
	
}
