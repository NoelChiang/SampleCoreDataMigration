//
//  Car+CoreDataProperties.swift
//  SampleCoreDataMigration
//
//  Created by Noel on 2019/1/16.
//  Copyright © 2019 Noel. All rights reserved.
//
//

import Foundation
import CoreData


extension Car {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Car> {
        return NSFetchRequest<Car>(entityName: "Car")
    }

    @NSManaged public var model: String?
    @NSManaged public var brand: String?

}
