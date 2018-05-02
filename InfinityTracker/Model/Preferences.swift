//
//  Preferences.swift
//  Workout
//
//  Created by Marco Boschi on 03/08/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import HealthKit
import MBLibrary

fileprivate enum PreferenceKeys: String, KeyValueStoreKey {
	case authorized = "authorized"
	case authVersion = "authVersion"
	
	case activityType = "activityType"
	
	var description: String {
		return rawValue
	}
	
}

class Preferences {
	
	private static let appSpecific = KeyValueStore(userDefaults: UserDefaults.standard)
	private init() {}
	
	static var authorized: Bool {
		get {
			return appSpecific.bool(forKey: PreferenceKeys.authorized)
		}
		set {
			appSpecific.set(newValue, forKey: PreferenceKeys.authorized)
			appSpecific.synchronize()
		}
	}
	
	static var authVersion: Int {
		get {
			return appSpecific.integer(forKey: PreferenceKeys.authVersion)
		}
		set {
			appSpecific.set(newValue, forKey: PreferenceKeys.authVersion)
			appSpecific.synchronize()
		}
	}
	
	static var activityType: Activity {
		get {
			let def = Activity.running
			guard let rawAct = UInt(exactly: appSpecific.integer(forKey: PreferenceKeys.activityType)),
				let act = HKWorkoutActivityType(rawValue: rawAct) else {
				return def
			}
			
			return Activity.fromHealthKitEquivalent(act) ?? def
		}
		set {
			appSpecific.set(newValue.healthKitEquivalent.rawValue, forKey: PreferenceKeys.activityType)
			appSpecific.synchronize()
		}
	}
	
}
