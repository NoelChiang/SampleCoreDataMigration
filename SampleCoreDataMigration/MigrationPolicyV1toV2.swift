//
//  MigrationPolicyV1toV2.swift
//  SampleCoreDataMigration
//
//  Created by Noel on 2019/1/16.
//  Copyright © 2019 Noel. All rights reserved.
//

import UIKit
import CoreData

class MigrationPolicyV1toV2: NSEntityMigrationPolicy {
    
    /*
     Used to cache necessary data to avoid save duplicated data during migration
     */
    static var cachedValue: [String] = []
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        let cachedValue = MigrationPolicyV1toV2.cachedValue
        if let model = sInstance.value(forKey: "carModel") as? String,
            let brand = sInstance.value(forKey: "carBrand") as? String {
            //** If cachedValue already contained this type of model, then skip this item
            if !cachedValue.contains(model) {
                //** Create managedObject
                let car = NSEntityDescription.insertNewObject(forEntityName: "Car", into: manager.destinationContext)
                
                //** Save value to corresponded key of new entity
                car.setValue(model, forKey: "model")
                car.setValue(brand, forKey: "brand")
                
                //** Cache saved model to prevent duplicated data (Different Person might have same car model)
                MigrationPolicyV1toV2.cachedValue.append(model)
            }
        }
        
        //** Catch out all keys from source object
        let sourceKeys = sInstance.entity.attributesByName.keys
        
        //** Catch out all key-value sets from source object
        let sourceValues = sInstance.dictionaryWithValues(forKeys: Array(sourceKeys))
        
        //** Generate destination managed object
        let destinationInstance = NSEntityDescription.insertNewObject(forEntityName: mapping.destinationEntityName!, into: manager.destinationContext)
        
        //** Catch out all keys from destination object
        let destinationKeys = destinationInstance.entity.attributesByName.keys
        for destKey in destinationKeys {
            //** If corresponded key-value was found in source object,
            //** then set the value to destination object
            if let value = sourceValues[destKey] {
                destinationInstance.setValue(value, forKey: destKey)
            }
        }
        
        //** Finally, make association to source object and destination object
        manager.associate(sourceInstance: sInstance, withDestinationInstance: destinationInstance, for: mapping)
    }
}
