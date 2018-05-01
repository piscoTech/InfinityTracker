//
//  PastRunsListController.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit
import HealthKit

class PastRunsListController: UITableViewController {
	
	let displayLimit = 50
    
    private var runs: [Run] = []
    private let cellIdentifier = "RunTableCell"
    
    lazy var emptyStateView: EmptyStateView = {
        let emptyStateView = EmptyStateView()
        emptyStateView.contentMode = .scaleAspectFit
        return emptyStateView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNavigationBar()
        
        runs = []
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let filter = HKQuery.predicateForObjects(from: HKSource.default())
		let type = HKObjectType.workoutType()
		let workoutQuery = HKSampleQuery(sampleType: type, predicate: filter, limit: displayLimit, sortDescriptors: [sortDescriptor]) { (_, r, err) in
			self.runs = (r as? [HKWorkout] ?? []).compactMap { SavedRun(raw: $0) }
			
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
		
		HealthKitManager.healthStore.execute(workoutQuery)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if runs.count > 0 {
            hideEmptyState()
            return runs.count
        } else {
            showEmptyState()
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! RunTableCell
        let run = runs[indexPath.row]
        cell.nameLabel.text = run.name
        cell.timestampLabel.text = "\(run.totalDistance) km"
		
        return cell
    }
	
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destinationController = segue.destination as? RunDetailController {
			guard let selectedCell = sender as? RunTableCell, let selectedIndex = tableView.indexPath(for: selectedCell) else {
				return
			}
			
            destinationController.run = runs[selectedIndex.row]
        }
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .white
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func showEmptyState() {
        tableView.backgroundView = emptyStateView
    }
    
    private func hideEmptyState() {
        tableView.backgroundView = nil
    }
	
}
