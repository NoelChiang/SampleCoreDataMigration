# SampleCoreDataMigration
**- Platform version:** iOS12<br>
**- Flow:**
- Model update: 
  - Add model version
    - Editor -> Add Model Version...
  - Make change for entity or attribute as you need
  - Switch model version to new one from inspector at right side
  - Save file
- Migration policy:
  - Create new policy file
    - File - New -> File -> Cocoa touch class
  - Subclass "NSEntityMigrationPolicy"
  - Override below funcion and do anything you want to do during data migration 
    ```
    func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws { 
      
    }
    ```
- Mapping file:
  - Create new mapping file
    - File -> New -> File -> Mapping Model
  - Select entity you want to do customize migration, open inspector at right side, set custom policy with the policy you just created
  - Set policy **MUST** include your app target name. ex: "MyApp.MyCustomPolicy"
- Persistent store setup:
  - Create persistentStoreCoordinator by model
  - Add options based on necessary of migration, and add persistentStore to coordinator 
  ```
  if manualMigrationNeeded {
    options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
    // Do migration
  } else {
    options = [NSInferMappingModelAutomaticallyOption: true, NSSQLitePragmasOption: ["journal_mode": "WAL"]]
  }
  try? coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
  ```
- Migration:
  - Get source model by metadata of persistentStore
  - Get destination model by search bundle resource path
  - Generate mapping object(NSMappingModel) by source model & destination model 
  - Generate migration manager(NSMappingModel) by source model & destination model 
  - Call method "migrateStore"
  ```
  try? migrationManager.migrateStore(from: sourceURL, sourceType: NSSQLiteStoreType, options: nil, with: mappingInstance, toDestinationURL: destinationURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)
  ```
