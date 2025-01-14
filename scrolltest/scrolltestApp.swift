//
//  scrolltestApp.swift
//  scrolltest
//
//  Created by Elisa Carrillo on 1/11/25.
//

import SwiftUI

@main
struct scrolltestApp: App {
    let previewpc = PreviewPersistentContainer.shared
    
    @StateObject private var keyboardMonitor = HIDKeyboardMonitor(context: PreviewPersistentContainer.shared.viewContext)
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    
    var body: some Scene {
        WindowGroup {
     
            ContentView()
                .environment(\.managedObjectContext, previewpc.viewContext)
                .environmentObject(keyboardMonitor)
                
        }
    }
}


