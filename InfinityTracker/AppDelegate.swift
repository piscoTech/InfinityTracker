//
//  AppDelegate.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
	weak var newRunController: NewRunController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Appearance.configureNavigationBar()
        setWindowBackgroundColor()
		
        return true
    }
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		((window?.rootViewController as? UINavigationController)?.viewControllers.first as? HomeController)?.setupLocationPermission(updateView: true)
		newRunController?.checkIfStopNeeded()
	}
    
    private func setWindowBackgroundColor() {
        window?.backgroundColor = UIColor.white
    }

}

