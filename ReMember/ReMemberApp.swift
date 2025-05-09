//
//  ReMemberApp.swift
//  ReMember
//
//  Created by Khizar Aamir on 2025-04-11.
//

import SwiftUI
import CoreData
import Firebase
import FirebaseAuth
import GoogleSignIn

@main
struct ReMemberApp: App {
    @StateObject private var store = JournalEntryStore()
    @StateObject private var settings = UserSettings.shared
    @StateObject private var authManager = AuthManager.shared
    @State private var hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        configureGoogleSignIn()
        
        // Apply global UI appearance
        applyGlobalAppearance()
    }
    
    // Configure Google Sign-In
    private func configureGoogleSignIn() {
        // Get the client ID from GoogleService-Info.plist
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            return
        }
        
        // Create GIDConfiguration with the Firebase client ID
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
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
            Group {
                // Show appropriate view based on authentication state
                if authManager.authState == .signedIn {
                    // User is signed in, show main app content
                    HomeView(viewModel: HomeViewModel(store: store))
                        .environmentObject(settings)
                        .environmentObject(authManager)
                } else {
                    // User is not signed in, show login view
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
            .environment(\.colorScheme, .dark) // Force dark mode
            .onAppear {
                // Mark as launched after first run
                if !hasLaunchedBefore {
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                    hasLaunchedBefore = true
                }
            }
            // Handle Google Sign-In URL
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            // Listen for auth state changes to refresh entries
            .onChange(of: authManager.authState) { oldValue, newValue in
                if newValue == .signedIn {
                    // Refresh entries when user signs in
                    store.refreshEntriesForCurrentUser()
                }
            }
        }
    }
}
