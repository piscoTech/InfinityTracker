//
//  WeightUpdateController.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 02/05/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary
import HealthKit

class WeightUpdateController: UIViewController {
	
	@IBOutlet weak var currentWeight: UILabel!
	@IBOutlet weak var newWeight: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

		updateWeight()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	private func updateWeight() {
		HealthKitManager.getRealWeight { w in
			DispatchQueue.main.async {
				self.currentWeight.text = Appearance.format(weight: w?.doubleValue(for: .gramUnit(with: .kilo)))
			}
		}
	}

	@IBAction func save(_ sender: AnyObject) {
		guard let w = (newWeight.text ?? "").toDouble(), w > 0 else {
			newWeight.shake()
			newWeight.becomeFirstResponder()
			return
		}
		
		let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: w)
		let now = Date()
		let weight = HKQuantitySample(type: HealthKitManager.weightType, quantity: quantity, start: now, end: now)
		HealthKitManager.healthStore.save(weight) { res, _ in
			DispatchQueue.main.async {
				if res {
					self.newWeight.text = ""
					self.newWeight.resignFirstResponder()
					self.updateWeight()
				} else {
					let alert = UIAlertController(simpleAlert: NSLocalizedString("ERROR", comment: "Error"), message: NSLocalizedString("WEIGHT_SAVE_ERROR", comment: "Cannot save"))
					self.present(alert, animated: true)
				}
			}
		}
	}

}
