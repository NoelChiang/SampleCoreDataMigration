//
//  ViewController.swift
//  SampleCoreDataMigration
//
//  Created by Noel on 2019/1/16.
//  Copyright © 2019 Noel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func createV1DB(_ sender: UIButton) {
        CoredataManager.shared.setupV1PersistentStorage()
    }
    @IBAction func migrateToV2DB(_ sender: UIButton) {
        CoredataManager.shared.setupV2PersistentStorage()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.deleteExistPersistentStorage()
        print("\(NSHomeDirectory())")
    }
    
    /*
     Delete existed storage file for every launching
     */
    func deleteExistPersistentStorage() {
        let path1 = "\(NSHomeDirectory())/Documents/DataBank.sqlite"
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: path1))
        let path2 = "\(NSHomeDirectory())/Documents/DataBank.sqlite-shm"
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: path2))
        let path3 = "\(NSHomeDirectory())/Documents/DataBank.sqlite-wal"
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: path3))
    }
}

