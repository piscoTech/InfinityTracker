//
//  HomeController.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit
import CoreLocation
import MBLibrary
import StoreKit

class HomeController: UIViewController {
	
	@IBOutlet weak var caloriesLabel: UILabel!
	@IBOutlet weak var distanceLabel: UILabel!
	@IBOutlet weak var logoImageView: UIImageView!
	@IBOutlet weak var runHistoryButton: UIButton!
	@IBOutlet weak var newRunButton: UIButton!
	@IBOutlet weak var changeActivityLbl: UILabel!
	
	private let newRunSegueIdentifier = "NewRunSegueIdentifier"
	private var activityType = Preferences.activityType
	
	private var locationEnabled = false
	private var locManager: CLLocationManager!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		updateNewRunButton()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		setupBackgroundGradient()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		setupLocationPermission()
		setupViews()
		setupNavigationBar()
	}
	
	// MARK: - Permission Management
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		HealthKitManager.requestAuthorization()
		
		if #available(iOS 10.3, *) {
			guard Preferences.reviewRequestCounter >= Preferences.reviewRequestThreshold else {
				return
			}
			
			SKStoreReviewController.requestReview()
		}
	}
	
	func setupLocationPermission(updateView: Bool = false) {
		if CLLocationManager.locationServicesEnabled() {
			switch CLLocationManager.authorizationStatus() {
			case .notDetermined:
				if locManager == nil {
					DispatchQueue.main.async {
						self.locManager = CLLocationManager()
						self.locManager.delegate = self
						self.locManager.requestWhenInUseAuthorization()
					}
				}
				fallthrough
			case .restricted, .denied:
				locationEnabled = false
			case .authorizedAlways, .authorizedWhenInUse:
				locationEnabled = true
			}
		} else {
			locationEnabled = false
		}
		
		if updateView {
			setupViews()
		}
	}
	
	// MARK: - UI Management
	
	private func setupBackgroundGradient() {
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = [Appearance.orangeDark.cgColor, Appearance.orangeLight.cgColor]
		gradientLayer.startPoint = CGPoint(x: 0, y: 0)
		gradientLayer.endPoint = CGPoint(x: 1, y: 0)
		view.layer.insertSublayer(gradientLayer, at: 0)
		gradientLayer.frame = view.bounds
	}
	
	private func setupViews() {
		logoImageView.layer.masksToBounds = true
		logoImageView.layer.cornerRadius = logoImageView.frame.width/2
		
		newRunButton.layer.masksToBounds = true
		newRunButton.layer.cornerRadius = newRunButton.frame.height/2
		newRunButton.alpha = locationEnabled ? 1 : 0.25
		
		distanceLabel.text = Appearance.format(distance: nil, addUnit: false)
		caloriesLabel.text = Appearance.format(calories: nil, addUnit: false)
		HealthKitManager.getStatistics { (d, c) in
			DispatchQueue.main.async {
				self.distanceLabel.text = Appearance.format(distance: d, addUnit: false)
				self.caloriesLabel.text = Appearance.format(calories: c, addUnit: false)
			}
		}
		
	}
	
	private func setupNavigationBar() {
		Appearance.setupNavigationBar(navigationController)
		navigationController?.setNavigationBarHidden(true, animated: false)
	}
	
	private func updateNewRunButton() {
		newRunButton.setTitle(NSLocalizedString("NEW_\(activityType.localizable)", comment: "New run/walk"), for: [])
		changeActivityLbl.text = NSLocalizedString("LONG_PRESS_CHANGE_\(activityType.nextActivity.localizable)", comment: "Long press to change")
	}
	
	// MARK: - Activity Type
	
	@IBAction func toggleActivityType(_ sender: UILongPressGestureRecognizer) {
		guard sender.state == .began else {
			return
		}
		
		activityType = activityType.nextActivity
		Preferences.activityType = self.activityType
		updateNewRunButton()
	}
	
	// MARK: - Navigation
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		if identifier == newRunSegueIdentifier && !locationEnabled {
			let alert = UIAlertController(title: NSLocalizedString("LOCATION_REQUIRED", comment: "Need gps"), message: NSLocalizedString("LOCATION_REQUIRED_TEXT", comment: "Need gps desc"), preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: NSLocalizedString("LOCATION_SETTINGS_OPEN", comment: "Open settings"), style: .default) { _ in
				if let bundleID = Bundle.main.bundleIdentifier, let settingsURL = URL(string: UIApplication.openSettingsURLString + bundleID) {
					UIApplication.shared.open(settingsURL)
				}
			})
			alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"), style: .cancel))
			
			self.present(alert, animated: true)
			return false
		}
		
		return true
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueID = segue.identifier else {
			return
		}
		
		switch segueID {
		case newRunSegueIdentifier:
			guard let navigationController = segue.destination as? UINavigationController, let destinationController = navigationController.viewControllers.first as? NewRunController  else {
				return
			}
			
			destinationController.newRunDismissDelegate = self
			destinationController.activityType = activityType
			
		case "updateWeight":
			let dest = segue.destination
			PopoverController.preparePresentation(for: dest)
			dest.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
			dest.popoverPresentationController?.sourceView = self.view
			dest.popoverPresentationController?.canOverlapSourceViewRect = true
			
		default:
			break
		}
	}
	
}

// MARK: - DismissDelegate

extension HomeController: DismissDelegate {
	
	func shouldDismiss(_ viewController: UIViewController) {
		viewController.dismiss(animated: true, completion: nil)
	}
	
}

// MARK: - CLLocationManagerDelegate

extension HomeController: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status == .notDetermined {
			return
		}
		
		self.locationEnabled = status == .authorizedAlways || status == .authorizedWhenInUse
		self.setupViews()
		self.locManager = nil
	}
	
}
