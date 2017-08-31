//
//  HomeController.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit

class HomeController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var runHistoryButton: UIButton!
    @IBOutlet weak var newRunButton: UIButton!
    
    // MARK: Properties
    
    private let newRunSegueIdentifier = "NewRunSegueIdentifier"
    
    // MARK: LifeCycle
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupBackgroundGradient()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupViews()
        setupNavigationBar()
    }
    
    // MARK: Background Gradient
    
    private func setupBackgroundGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [Colors.orangeDark.cgColor, Colors.orangeLight.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.frame = view.bounds
    }
    
    // MARK: Setup Views
    
    private func setupViews() {
        
        logoImageView.layer.masksToBounds = true
        logoImageView.layer.cornerRadius = logoImageView.frame.width/2
        
        newRunButton.layer.masksToBounds = true
        newRunButton.layer.cornerRadius = newRunButton.frame.height/2
        
        let distance = CoreDataManager.getDistanceTotal()
        distanceLabel.text = "\(distance.metersToKilometers().rounded(to: 1))"
        
        let calories = CoreDataManager.getCaloriesTotal()
        caloriesLabel.text = "\(calories.rounded(to: 1))"
    }
    
    // MARK: Setup Navigation Bar
    
    private func setupNavigationBar() {
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: PrepareForSegue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == newRunSegueIdentifier {
            
            guard let navigationController = segue.destination as? UINavigationController, let destinationController = navigationController.viewControllers.first as? NewRunController  else {
                return
            }
            
            destinationController.newRunDismissDelegate = self
        }
        
    }
    
}

extension HomeController: DismissDelegate {
    
    // MARK: DismissDelegate
    
    func shouldDismiss(_ viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    
}
