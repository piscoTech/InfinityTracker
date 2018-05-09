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
import MBLibrary
import HealthKit

class NewRunController: UIViewController {
	
	var activityType: Activity!
	
	// MARK: IBOutlets
	
	@IBOutlet weak var startButton: GradientButton!
	@IBOutlet weak var stopButton: GradientButton!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var sliderBackground: UIView!
	@IBOutlet weak var slider: UISlider!
	@IBOutlet weak var details: DetailView!
	
	// MARK: Private Properties
	
	private var weight: HKQuantity?
	private var timer: Timer?
	private var run: RunBuilder! {
		willSet {
			precondition(run == nil, "Cannot start multiple runs")
		}
	}
	private let locationManager = CLLocationManager()
	
	/// The last registered position when the workout was not yet started or paused
	private var previousLocation: CLLocation?
	
	private var mapDelta: Double = 0.0050
	
	private var didStart: Bool {
		return run != nil
	}
	private var didEnd: Bool {
		return run?.invalidated ?? false
	}
	private var cannotSaveAlertDisplayed = false
	
	// MARK: Delegates
	
	weak var newRunDismissDelegate: DismissDelegate?
	private let mapViewDelegate = Appearance()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		(UIApplication.shared.delegate as? AppDelegate)?.newRunController = self
		
		setupNavigationBar()
		setupViews()
		startUpdatingLocations()
		setupMap()
		HealthKitManager.getWeight { w in
			DispatchQueue.main.async {
				self.weight = w
				self.startButton.isEnabled = true
				self.startButton.alpha = 1
			}
		}
		
		DispatchQueue.main.async {
			if HealthKitManager.canSaveWorkout() != .full {
				self.present(HealthKitManager.healthPermissionAlert, animated: true)
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
	
	// MARK: - Manage Run Start
	
	@IBAction func handleStartPauseResumeTapped() {
		if !didStart {
			startRun()
		} else if run.paused {
			resumeRun()
		} else {
			pauseRun()
		}
	}
	
	private func startRun() {
		guard let weight = self.weight else {
			return
		}
		
		UIView.animate(withDuration: 0.60, animations: {
			self.view.layoutIfNeeded()
			self.stopButton.alpha = 1.0
		}) { (finished) in
			self.stopButton.isEnabled = true
		}
		
		run = RunBuilder(start: Date(), activityType: activityType, weight: weight)
		updatePauseStatus()
		timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
		if let prev = previousLocation {
			self.locationManager(locationManager, didUpdateLocations: [prev])
			previousLocation = nil
		}
	}
	
	// MARK: - Manage Run Pause
	
	private func pauseRun() {
		run.pause(Date())
		updatePauseStatus()
	}
	
	private func resumeRun() {
		mapView.addOverlays(run.resume(Date()))
		updatePauseStatus()
	}
	
	// MARK: - Manage Run Stop
	
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
	
	private func stopRun() {
		locationManager.stopUpdatingLocation()
	}
	
	// MARK: - UI Interaction
	
	@IBAction func sliderDidChangeValue() {
		let miles = Double(slider.value)
		mapDelta = miles / 69.0
		
		var currentRegion = mapView.region
		currentRegion.span = MKCoordinateSpan(latitudeDelta: mapDelta, longitudeDelta: mapDelta)
		mapView.region = currentRegion
	}
	
	private func setupMap() {
		mapViewDelegate.setupAppearance(for: mapView)
		mapView.delegate = mapViewDelegate
		
		mapView.showsUserLocation = true
		mapView.mapType = .standard
		mapView.userTrackingMode = .follow
		mapView.showsBuildings = true
	}
	
	private func startUpdatingLocations() {
		locationManager.delegate = self
		locationManager.activityType = .fitness
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.distanceFilter = 0.1
		locationManager.allowsBackgroundLocationUpdates = true
		locationManager.startUpdatingLocation()
	}
	
	private func updateUI() {
		details.update(for: run?.run)
	}
	
	@objc func updateTimer() {
		details.update(for: run?.run)
	}
	
	private func updatePauseStatus() {
		guard didStart else {
			return
		}
		
		startButton.setTitle(NSLocalizedString(run.paused ? "RESUME" : "PAUSE", comment: "Pause/Resume"), for: [])
	}
	
	private func setupViews() {
		stopButton.isEnabled = false
		stopButton.alpha = Appearance.disabledAlpha
		startButton.isEnabled = false
		stopButton.alpha = Appearance.disabledAlpha
		
		for v in [sliderBackground!, startButton!, stopButton!] {
			v.layer.cornerRadius = v.frame.height/2
			v.layer.masksToBounds = true
		}
		
		updateTimer()
		updateUI()
	}
	
	private func setupNavigationBar() {
		navigationItem.title = NSLocalizedString("NEW_\(activityType.localizable)", comment: "New run/walk")
		
		let leftBarButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(handleDismissController))
		navigationItem.leftBarButtonItem = leftBarButton
	}
	
	// MARK: - Navigation
	
	@objc func handleDismissController() {
		let actionSheet = UIAlertController(title: nil, message: "Are you sure you want to leave this screen?", preferredStyle: .actionSheet)
		let stopAction = UIAlertAction(title: "Leave", style: .destructive) { [weak self] (action) in
			guard self != nil else {
				return
			}
			
			self?.run?.discard()
			self?.newRunDismissDelegate?.shouldDismiss(self!)
		}
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
		
		actionSheet.addAction(stopAction)
		actionSheet.addAction(cancelAction)
		
		self.present(actionSheet, animated: true, completion: nil)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let navigationController = segue.destination as? UINavigationController, let destinationController = navigationController.viewControllers.first as? RunDetailController, let run = sender as? Run else {
			return
		}
		
		destinationController.run = run
		destinationController.runDetailDismissDelegate = self
		destinationController.displayCannotSaveAlert = !cannotSaveAlertDisplayed && HealthKitManager.canSaveWorkout() != .full
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
			mapView.addOverlays(run.add(locations: locations), level: Appearance.overlayLevel)
		} else if let loc = locations.last {
			previousLocation = loc
		}
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
