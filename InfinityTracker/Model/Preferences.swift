//
//  Preferences.swift
//  Workout
//
//  Created by Marco Boschi on 03/08/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

fileprivate enum PreferenceKeys: String, KeyValueStoreKey {
	case authorized = "authorized"
	case authVersion = "authVersion"
	// TODO: Add activity type
	
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
	
}
