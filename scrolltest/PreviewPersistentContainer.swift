//
//  PreviewPersistentContainer.swift
//  WPMtracker
//
//  Created by Elisa Carrillo on 1/11/25.
//

import Foundation
import CoreData

class PreviewPersistentContainer {
    static let shared: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        let description = container.persistentStoreDescriptions.first
        description?.type = NSSQLiteStoreType
        
        print("SQLite file location: \(description?.url?.absoluteString ?? "No URL")")

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
}
