//
//  DetailView.swift
//  InfinityTracker
//
//  Created by Marco Boschi on 01/05/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit

class DetailView: UIView {
	
	static let verticalSpace: CGFloat = 10
	static let horizontalSpace: CGFloat = 10
	static let detailPadding: CGFloat = 6
	
	private let details: [UIView]
	
	private let distanceLbl: UILabel
	private let timeLbl: UILabel
	private let caloriesLbl: UILabel
	private let paceLbl: UILabel
	
	required init?(coder aDecoder: NSCoder) {
		let createDetail = { (name: String) -> (UIView, UILabel) in
			let nameLbl = UILabel()
			nameLbl.text = name
			nameLbl.font = .systemFont(ofSize: 14, weight: .light)
			let dataLbl = UILabel()
			dataLbl.font = .systemFont(ofSize: 20, weight: .medium)
			
			for l in [nameLbl, dataLbl] {
				l.translatesAutoresizingMaskIntoConstraints = false
				l.setContentHuggingPriority(.required, for: .vertical)
				l.textColor = Appearance.detailsColor
			}
			
			let stack = UIStackView(arrangedSubviews: [nameLbl, dataLbl])
			stack.alignment = .center
			stack.distribution = .fill
			stack.axis = .vertical
			stack.translatesAutoresizingMaskIntoConstraints = false
			
			let detail = UIView()
			detail.translatesAutoresizingMaskIntoConstraints = false
			detail.backgroundColor = .white
			detail.layer.masksToBounds = true
			detail.addSubview(stack)
			stack.topAnchor.constraint(equalTo: detail.topAnchor, constant: DetailView.detailPadding).isActive = true
			detail.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: DetailView.detailPadding).isActive = true
			detail.leftAnchor.constraint(equalTo: stack.leftAnchor, constant: 0).isActive = true
			detail.rightAnchor.constraint(equalTo: stack.rightAnchor, constant: 0).isActive = true
			
			return (detail, dataLbl)
		}
		
		let distance = createDetail(NSLocalizedString("DISTANCE", comment: "Distance"))
		let time = createDetail(NSLocalizedString("DURATION", comment: "Duration"))
		let calories = createDetail(NSLocalizedString("CALORIES", comment: "Calories"))
		let pace = createDetail(NSLocalizedString("PACE", comment: "Pace"))
		
		self.details = [distance, time, calories, pace].map { $0.0 }
		self.distanceLbl = distance.1
		self.timeLbl = time.1
		self.caloriesLbl = calories.1
		self.paceLbl = pace.1
		
		super.init(coder: aDecoder)
		
		for v in self.subviews {
			v.removeFromSuperview()
		}
		self.backgroundColor = nil
		
		let topDetail = UIStackView(arrangedSubviews: [distance.0, time.0])
		let bottomDetail = UIStackView(arrangedSubviews: [calories.0, pace.0])
		
		for s in [topDetail, bottomDetail] {
			s.alignment = .fill
			s.distribution = .fillEqually
			s.axis = .horizontal
			s.spacing = DetailView.horizontalSpace
			s.translatesAutoresizingMaskIntoConstraints = false
		}
		
		let details = UIStackView(arrangedSubviews: [topDetail, bottomDetail])
		details.alignment = .fill
		details.distribution = .fillEqually
		details.axis = .vertical
		details.spacing = DetailView.verticalSpace
		details.translatesAutoresizingMaskIntoConstraints = false
		
		self.addSubview(details)
		self.topAnchor.constraint(equalTo: details.topAnchor, constant: 0).isActive = true
		self.bottomAnchor.constraint(equalTo: details.bottomAnchor, constant: 0).isActive = true
		self.leftAnchor.constraint(equalTo: details.leftAnchor, constant: 0).isActive = true
		self.rightAnchor.constraint(equalTo: details.rightAnchor, constant: 0).isActive = true
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		DispatchQueue.main.async {
			for v in self.details {
				v.layer.cornerRadius = v.frame.height / 2
			}
		}
	}
	
	func update(for run: Run?) {
		distanceLbl.text = Appearance.format(distance: run?.totalDistance)
		timeLbl.text = Appearance.format(duration: run?.duration)
		caloriesLbl.text = Appearance.format(calories: run?.totalCalories)
		paceLbl.text = Appearance.format(pace: run?.currentPace ?? run?.pace)
	}

}
