//
//  Person+CoreDataProperties.swift
//  SampleCoreDataMigration
//
//  Created by Noel on 2019/1/16.
//  Copyright © 2019 Noel. All rights reserved.
//
//

import Foundation
import CoreData


extension Person {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Person> {
        return NSFetchRequest<Person>(entityName: "Person")
    }

    @NSManaged public var name: String?
    @NSManaged public var age: Int32
    @NSManaged public var carModel: String?
    @NSManaged public var carBrand: String?
}
