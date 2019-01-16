//
//  CoredataManager.swift
//  SampleCoreDataMigration
//
//  Created by Noel on 2019/1/16.
//  Copyright © 2019 Noel. All rights reserved.
//

import UIKit
import CoreData

class CoredataManager: NSObject {
    static let shared = CoredataManager()
    var manualMigrationNeeded = false
    fileprivate var managedObjectContext: NSManagedObjectContext!
    fileprivate var modelPaths: [String] {
        //** Get xcdatamodeld(Model file's package)
        guard let momdPath = Bundle.main.paths(forResourcesOfType: "momd", inDirectory: nil).first else {
            return []
        }
        
        //** Under model's package, get all the xcdatamodel(Which will be every version's of Model file)
        //** and return
        let momdPackage = (momdPath as NSString).lastPathComponent
        return Bundle.main.paths(forResourcesOfType: "mom", inDirectory: momdPackage)
    }
    
    /*
     Setup persistent storage by version1 model, and create initial data
     */
    func setupV1PersistentStorage() {
        var momPath: String?
        for modelPath in modelPaths {
            //** In this project, if file path not contain "Model 2", it will be version1's model
            if !modelPath.contains("Model 2") {
                momPath = modelPath
                break
            }
        }
        guard let v1Path = momPath else {
            return
        }
        
        //** Setup persistentStore with version1's model
        self.setupPersistentStorage(forPath: v1Path)

        //** Create dummy data based on version 1 model
        let person1 = self.createObject(withEntity: "Person") as! Person
        person1.name = "Leon"
        person1.age = 35
        person1.carModel = "V60"
        person1.carBrand = "Volvo"
        let person2 = self.createObject(withEntity: "Person") as! Person
        person2.name = "Ada"
        person2.age = 32
        person2.carModel = "Macan"
        person2.carBrand = "Porche"
        let person3 = self.createObject(withEntity: "Person") as! Person
        person3.name = "Ashley"
        person3.age = 20
        person3.carModel = "Macan"
        person3.carBrand = "Porche"
        self.saveToData()
    }
    
    /*
     Setup model to version 2 and make data migration
     */
    func setupV2PersistentStorage() {
        //** Clear all store before all process, which to prevent data cross occupied issue
        for store in managedObjectContext!.persistentStoreCoordinator!.persistentStores {
            try! managedObjectContext!.persistentStoreCoordinator!.remove(store)
        }
        manualMigrationNeeded = true
        var momPath: String?
        for modelPath in modelPaths {
            //** Get version2's model path
            if modelPath.contains("Model 2") {
                momPath = modelPath
                break
            }
        }
        guard let v2Path = momPath else {
            return
        }
        //** Setup persistentStore with version2's model
        self.setupPersistentStorage(forPath: v2Path)
    }
    
    fileprivate func setupPersistentStorage(forPath path: String?) {
        
        guard var modelPath = Bundle.main.url(forResource: "Model", withExtension: "momd") else {
            return
        }
        if path != nil {
            modelPath = URL(fileURLWithPath: path!)
        }
        guard let objectModel = NSManagedObjectModel(contentsOf: modelPath) else {
            return
        }
        guard var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            return
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        url = url.appendingPathComponent("DataBank.sqlite")
        var options: [String: Any] = [:]
        
        //** Check if migration is needed
        if manualMigrationNeeded {
            options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            self.manualMigration(sourceURL: url)
        } else {
            options = [NSInferMappingModelAutomaticallyOption: true, NSSQLitePragmasOption: ["journal_mode": "WAL"]]
        }
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
        }
        managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
    }
    
    fileprivate func manualMigration(sourceURL: URL) {
        //** Get the metadata of current persistent store file(dataBank.sqlite)
        guard let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sourceURL) else {
            return
        }
        //** Using metadata to create model object of current saved one (Which will be the source of migration)
        let sourceModel = NSManagedObjectModel.mergedModel(from: [Bundle.main], forStoreMetadata: sourceMetadata)
        var destModel: NSManagedObjectModel?
        var mapping: NSMappingModel?
        for modelPath in modelPaths {
            //** Search version2's model path
            if modelPath.contains("Model 2") {
                //** Generate version2 model object(Which will be the destination of migration)
                destModel = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: modelPath))
                
                //** Provide source and destination model to create mapping object
                mapping = NSMappingModel(from: [Bundle.main], forSourceModel: sourceModel, destinationModel: destModel)
                break
            }
        }
        
        //** Check if mapping object, source model, and destination model existed
        guard let mappingInstance = mapping,
            let sourceModelInstance = sourceModel,
            let destModelInstance = destModel else {
                return
        }
        
        //** Use current sqlite file name with suffix "v2" to create temp file name for destination
        let storageExtension = sourceURL.pathExtension
        let storagePath = sourceURL.deletingPathExtension().path
        let destinationPath = "\(storagePath)_v2.\(storageExtension)"
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        //** Use source and destinaion model object to create MigrationManager
        let migrationManager = NSMigrationManager(sourceModel: sourceModelInstance, destinationModel: destModelInstance)
        var migrationSucceeded: Bool = true
        
        //** Add KVO to detect migration progress
        migrationManager.addObserver(self, forKeyPath: "migrationProgress", options: .new, context: nil)
        
        //** Migration
        do {
            try migrationManager.migrateStore(from: sourceURL, sourceType: NSSQLiteStoreType, options: nil, with: mappingInstance, toDestinationURL: destinationURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)
        } catch {
            print("Migration failed: \(error.localizedDescription)")
            migrationSucceeded = false
        }
        
        //** Remove KVO, stop to detect migration progress
        migrationManager.removeObserver(self, forKeyPath: "migrationProgress")
        
        //** If migration failed, return to caller
        guard migrationSucceeded else {
            return
        }
        
        //** Create temp file name to save source storage file
        let guid = ProcessInfo.processInfo.globallyUniqueString
        let backupPath = "\(NSTemporaryDirectory())/\(guid)"
        do {
            try FileManager.default.moveItem(atPath: sourceURL.path, toPath: backupPath)
        } catch {
            print("Move file failed: \(error.localizedDescription)")
            return
        }
        
        //** Move destination storage file to current position, then remove temp source storage file
        do {
            try FileManager.default.moveItem(atPath: destinationPath, toPath: sourceURL.path)
        } catch {
            print("Move file failed: \(error.localizedDescription)")
            // Move back file back to original location
            try? FileManager.default.moveItem(atPath: backupPath, toPath: sourceURL.path)
            return
        }
        
        //** Remove cached data
        MigrationPolicyV1toV2.cachedValue.removeAll()
    }
    
    fileprivate func createObject(withEntity entity:String) -> NSManagedObject? {
        var mObject:NSManagedObject?
        self.managedObjectContext.performAndWait {
            mObject = NSEntityDescription.insertNewObject(forEntityName: entity, into: self.managedObjectContext)
        }
        return mObject
    }
    
    fileprivate func saveToData() {
        self.managedObjectContext.performAndWait {
            do {
                try self.managedObjectContext.save()
            } catch {
                print("Save data failed: \(error.localizedDescription)")
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let key = keyPath, key == "migrationProgress" {
            print("progress: \((object as! NSMigrationManager).migrationProgress)")
        }
    }
    
}
