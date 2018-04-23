//
//  CoreDataStackManager.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import CoreData
import UIKit

class CoreDataManager {
    
    // MARK: CoreData Stack
    
    private static let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "InfinityTracker")
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Fatal Error: \(error)")
            }
        }
        return container
    }()
    
    static var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: CoreData Saving Support
    
    class func saveContext () {
        let context = persistentContainer.viewContext
        guard context.hasChanges else {
            return
        }
        do {
            try context.save()
        } catch let error as NSError {
            fatalError("Fatal Error: \(error)")
        }
    }
    
    // MARK: CoreData Fetching Support
    
    public static func fetchObjects<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext) -> [T] {
        
        let request = NSFetchRequest<T>(entityName: String(describing: entity))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        do {
            return try context.fetch(request)
        }
        catch let error as NSError {
            print(error)
            return [T]()
        }
    }
    
    // MARK: Remove All CoreData Entities
    
    public static func removeAllCoreDataEntriesFor(_ entityName: String) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
        }
        catch let error as NSError {
            fatalError("Fatal Error: \(error)")
        }
        
    }
    
    // MARK: Update Run Name
    
    public static func updateRunName(currentValue: String, newValue: String) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Run")
        fetchRequest.predicate = NSPredicate(format: "name = %@", currentValue)
        
        do {
            let results = try context.fetch(fetchRequest) as? [NSManagedObject]
            
            if let unwrappedResults = results {
                if unwrappedResults.count > 0 {
                    let object = unwrappedResults[0]
                    object.setValue(newValue, forKey: "name")
                    saveContext()
                }
            }
        }
        catch let error as NSError {
            fatalError("Fatal Error: \(error)")
        }
    }
    
    
    // MARK: Get Distance Total
    
    public static func getDistanceTotal() -> Double {
        
        var totalDistance: Double = 0.0
        
        let runs = fetchObjects(entity: Run.self, context: context)
        
        for run in runs {
            totalDistance += run.distance
        }
        
        return totalDistance
    }
    
    // MARK: Get Calories Total
    
    public static func getCaloriesTotal() -> Double {
        
        var caloriesTotal: Double = 0.0
        
        let runs = fetchObjects(entity: Run.self, context: context)
        
        for run in runs {
            caloriesTotal += run.calories
        }
        
        return caloriesTotal
    }
    
    // MARK: Get Runs Count
    
    public static func getRunsCount() -> Int? {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Run")
        
        do {
            let count = try context.count(for: fetchRequest)
            return count
        }
        catch {
            return nil
        }
    }
    
    
}
