//
//  PastRunsListController.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit

class PastRunsListController: UITableViewController {
    
    // MARK: Private Properties
    
    private var runs: [Run] = []
    private let cellIdentifier = "RunTableCell"
    
    lazy var emptyStateView: EmptyStateView = {
        let emptyStateView = EmptyStateView()
        emptyStateView.contentMode = .scaleAspectFit
        return emptyStateView
    }()
    
    // MARK: LifeCycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNavigationBar()
        
        runs = CoreDataManager.fetchObjects(entity: Run.self, predicate: nil, context: CoreDataManager.context)
        
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "RunTableCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
    }
    
    // MARK: UITableViewDataSource
    
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
        let date = run.timestamp! as Date
        cell.timestampLabel.text = "\(date.formatDate())"
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        performSegue(withIdentifier: "PastTrackDetailSegueIdentifier", sender: selectedCell)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    // MARK: PrepareForSegue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destinationController = segue.destination as? PastRunDetailController {
            let selectedCell = sender as! UITableViewCell
            let selectedIndex = tableView.indexPath(for: selectedCell)!
            destinationController.title = runs[selectedIndex.row].name
            destinationController.run = runs[selectedIndex.row]
        }
    }
    
    // MARK: User Interaction
    
    @IBAction func handleRemoveAllTracks() {
        
        let actionSheet = UIAlertController(title: nil, message: "Are you sure you want to remove all run history from Core Data?", preferredStyle: .actionSheet)
        
        let stopAction = UIAlertAction(title: "Remove All", style: .destructive) { [weak self] (action) in
            CoreDataManager.removeAllCoreDataEntriesFor("Run")
            CoreDataManager.removeAllCoreDataEntriesFor("Location")
            self?.navigationController?.popToRootViewController(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        
        actionSheet.addAction(stopAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: Setup Navigation Bar
    
    private func setupNavigationBar() {
        
        title = "Past Runs"
        
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .white
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: Show Empty State
    
    private func showEmptyState() {
        tableView.backgroundView = emptyStateView
    }
    
    // MARK: Hide Empty State
    
    private func hideEmptyState() {
        tableView.backgroundView = nil
    }
    
    
}
