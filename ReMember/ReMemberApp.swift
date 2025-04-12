//
//  ReMemberApp.swift
//  ReMember
//
//  Created by Khizar Aamir on 2025-04-11.
//

import SwiftUI
import CoreData

@main
struct ReMemberApp: App {
    // Use a StateObject to ensure the store is created once and shared throughout the app lifetime
    @StateObject private var store = JournalEntryStore()
    
    // Ensure Core Data model setup
    init() {
        print("ReMemberApp initializing")
        
        // Fix common Core Data issues
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print("Documents Directory: \(urls[urls.count-1])")
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel(store: store))
                .preferredColorScheme(.dark)
                .environment(\.colorScheme, .dark) // Force dark mode
                .onAppear {
                    print("App appeared - Core Data setup complete")
                }
        }
    }
}
