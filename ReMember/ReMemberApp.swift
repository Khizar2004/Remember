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
    
    // Use a StateObject for UserSettings to ensure it's created once and shared throughout the app
    @StateObject private var settings = UserSettings.shared
    
    // Track initial boot sequence
    @State private var hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    
    // Ensure Core Data model setup
    init() {
        print("ReMemberApp initializing")
        
        // Apply global UI appearance
        applyGlobalAppearance()
        
        // Fix common Core Data issues
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print("Documents Directory: \(urls[urls.count-1])")
    }
    
    // Configure global appearance settings
    private func applyGlobalAppearance() {
        // Set dark appearance for UIKit components
        UINavigationBar.appearance().barStyle = .black
        
        // Set global tint color for UIKit components
        UIView.appearance().tintColor = UIColor(GlitchTheme.glitchCyan)
        
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(GlitchTheme.background)
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(GlitchTheme.terminalGreen)
        ]
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Configure TabBar appearance 
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(GlitchTheme.background)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel(store: store))
                .preferredColorScheme(.dark)
                .environment(\.colorScheme, .dark) // Force dark mode
                .environmentObject(settings) // Make settings available throughout the app
                .onAppear {
                    // Mark as launched after first run
                    if !hasLaunchedBefore {
                        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                        hasLaunchedBefore = true
                    }
                }
        }
    }
}
