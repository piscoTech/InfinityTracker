//
//  AppDelegate.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let locationManager = CLLocationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        configureNavigationBar()
        setWindowBackgroundColor()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        CoreDataManager.saveContext()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        CoreDataManager.saveContext()
    }
    
    private func configureNavigationBar() {
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().barTintColor = UIColor.white
        UINavigationBar.appearance().tintColor = Colors.orangeDark
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont(name: Font.mainFontMedium, size: Font.regularSize)!, NSForegroundColorAttributeName: UIColor.orange]
        
        let backButtonImage = Image.backArrow.withRenderingMode(.alwaysTemplate).resizableImage(withCapInsets: UIEdgeInsets(top: 3,left: 3,bottom: 3,right: 3), resizingMode: .stretch)
        UINavigationBar.appearance().backIndicatorImage = backButtonImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backButtonImage
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffsetMake(-60, -60), for: .default)
    }
    
    private func setWindowBackgroundColor() {
        window?.backgroundColor = UIColor.white
    }

}

