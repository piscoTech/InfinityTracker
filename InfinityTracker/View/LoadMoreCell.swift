//
//  LoadMoreCell.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 12/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit

class LoadMoreCell: UITableViewCell {
	
	static let identifier = "loadMore"
	
	@IBOutlet private weak var loadIndicator: UIActivityIndicatorView!
	@IBOutlet private weak var loadBtn: UIButton!
	
	var isEnabled: Bool {
		get {
			return loadBtn.isEnabled
		}
		set {
			loadBtn.isEnabled = newValue
			loadIndicator.isHidden = newValue
			if !newValue {
				loadIndicator.startAnimating()
			} else {
				loadIndicator.stopAnimating()
			}
		}
	}
	
}
