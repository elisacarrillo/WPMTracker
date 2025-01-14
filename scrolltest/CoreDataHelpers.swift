//
//  CoreDataHelpers.swift
//  scrolltest
//
//  Created by Elisa Carrillo on 1/14/25.
//


import Foundation

import CoreData

/// Saves a new WPM entry to Core Data.
func saveWPMEntry(timestamp: Date, userId: String, wpm: Int, context: NSManagedObjectContext) {
    print("SAVEWPM")
    let newEntry = WPMEntry(context: context)
    newEntry.timestamp = timestamp
    newEntry.userId = userId
    newEntry.wpm = Int32(wpm)

    do {
        try context.save()
        print("WPM entry saved successfully.")
    } catch {
        print("Failed to save WPM entry: \(error)")
    }
}

/// Fetches all WPM entries from Core Data.
func fetchWPMEntries(context: NSManagedObjectContext) -> [WPMEntry] {
    let fetchRequest: NSFetchRequest<WPMEntry> = WPMEntry.fetchRequest()

    do {
        return try context.fetch(fetchRequest)
    } catch {
        print("Failed to fetch WPM entries: \(error)")
        return []
    }
}
