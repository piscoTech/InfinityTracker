//
//  HomeController.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit
import CoreLocation

class HomeController: UIViewController {
	
	@IBOutlet weak var caloriesLabel: UILabel!
	@IBOutlet weak var distanceLabel: UILabel!
	@IBOutlet weak var logoImageView: UIImageView!
	@IBOutlet weak var runHistoryButton: UIButton!
	@IBOutlet weak var newRunButton: UIButton!
	
	private let newRunSegueIdentifier = "NewRunSegueIdentifier"
	private var locationEnabled = false
	
	private var locManager: CLLocationManager!
	
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
	
	private func setupBackgroundGradient() {
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = [Colors.orangeDark.cgColor, Colors.orangeLight.cgColor]
		gradientLayer.startPoint = CGPoint(x: 0, y: 0)
		gradientLayer.endPoint = CGPoint(x: 1, y: 0)
		view.layer.insertSublayer(gradientLayer, at: 0)
		gradientLayer.frame = view.bounds
	}
	
	fileprivate func setupViews() {
		logoImageView.layer.masksToBounds = true
		logoImageView.layer.cornerRadius = logoImageView.frame.width/2
		
		newRunButton.layer.masksToBounds = true
		newRunButton.layer.cornerRadius = newRunButton.frame.height/2
		newRunButton.alpha = locationEnabled ? 1 : 0.25
		
		let distance = HealthKitManager.getDistanceTotal()
		distanceLabel.text = "\(distance.metersToKilometers().rounded(to: 1))"
		
		let calories = HealthKitManager.getCaloriesTotal()
		caloriesLabel.text = "\(calories.rounded(to: 1))"
	}
	
	private func setupNavigationBar() {
		navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
		navigationController?.navigationBar.shadowImage = UIImage()
		navigationController?.navigationBar.isTranslucent = true
		navigationController?.view.backgroundColor = .clear
		
		navigationController?.setNavigationBarHidden(true, animated: false)
	}
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		if identifier == newRunSegueIdentifier && !locationEnabled {
			let alert = UIAlertController(title: NSLocalizedString("LOCATION_REQUIRED", comment: "Need gps"), message: NSLocalizedString("LOCATION_REQUIRED_TEXT", comment: "Need gps desc"), preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: NSLocalizedString("LOCATION_SETTINGS_OPEN", comment: "Open settings"), style: .default) { _ in
				if let bundleID = Bundle.main.bundleIdentifier, let settingsURL = URL(string: UIApplicationOpenSettingsURLString + bundleID) {
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
		if segue.identifier == newRunSegueIdentifier {
			guard let navigationController = segue.destination as? UINavigationController, let destinationController = navigationController.viewControllers.first as? NewRunController  else {
				return
			}
			
			destinationController.newRunDismissDelegate = self
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

