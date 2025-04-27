import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn

/// AuthManager handles user authentication and manages the auth state
class AuthManager: ObservableObject {
    // Published properties for SwiftUI binding
    @Published var user: User?
    @Published var isAuthenticating = false
    @Published var error: Error?
    @Published var authState: AuthState = .signedOut
    
    // Singleton instance
    static let shared = AuthManager()
    
    // Authentication states
    enum AuthState {
        case signedIn
        case signedOut
        case loading
    }
    
    init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.user = user
                self.authState = user != nil ? .signedIn : .signedOut
                print("Auth state changed: \(self.authState)")
            }
        }
    }
    
    // MARK: - Email Authentication
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async -> Bool {
        await setAuthenticating(true)
        
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            await setUser(authResult.user)
            await setAuthenticating(false)
            return true
        } catch {
            await handleError(error)
            return false
        }
    }
    
    /// Create a new user with email and password
    func signUp(email: String, password: String) async -> Bool {
        await setAuthenticating(true)
        
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            await setUser(authResult.user)
            await setAuthenticating(false)
            return true
        } catch {
            await handleError(error)
            return false
        }
    }
    
    // MARK: - Google Authentication
    
    /// Sign in with Google
    func signInWithGoogle() async -> Bool {
        await setAuthenticating(true)
        
        do {
            // Get the client ID from GoogleService-Info.plist
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(domain: "AuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Firebase configuration error"])
            }
            
            // Create Google Sign In configuration object
            let config = GIDConfiguration(clientID: clientID)
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                throw NSError(domain: "AuthManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
            }
            
            print("Starting Google Sign-In flow...")
            
            // Start the sign in flow!
            let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController,
                hint: nil,
                additionalScopes: ["email", "profile"]
            )
            
            print("Google Sign-In successful, getting user info...")
            let user = gidSignInResult.user
            
            // Get the user's ID token and access token
            guard let idToken = user.idToken?.tokenString else {
                throw NSError(domain: "AuthManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "No ID token from Google Sign-In"]) 
            }
            
            print("Creating Firebase credential with Google token...")
            // Create a Firebase credential with the Google ID token
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            print("Signing in to Firebase with Google credential...")
            // Sign in to Firebase with the Google Auth credential
            let authResult = try await Auth.auth().signIn(with: credential)
            await setUser(authResult.user)
            await setAuthenticating(false)
            print("Firebase authentication with Google successful!")
            return true
        } catch {
            print("Google Sign-In error: \(error.localizedDescription)")
            await handleError(error)
            return false
        }
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    func signOut() -> Bool {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.user = nil
                self.authState = .signedOut
            }
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
            return false
        }
    }
    
    // MARK: - Reset Password
    
    /// Send a password reset email
    func resetPassword(email: String) async -> Bool {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            return true
        } catch {
            await handleError(error)
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func setAuthenticating(_ value: Bool) {
        isAuthenticating = value
        if value {
            authState = .loading
        }
    }
    
    @MainActor
    private func setUser(_ user: User?) {
        self.user = user
        self.authState = user != nil ? .signedIn : .signedOut
    }
    
    @MainActor
    private func handleError(_ error: Error) {
        self.error = error
        self.isAuthenticating = false
        self.authState = .signedOut
        print("Authentication error: \(error.localizedDescription)")
    }
    
    // MARK: - User Information
    
    /// The current user's display name or email
    var displayName: String {
        if let name = user?.displayName, !name.isEmpty {
            return name
        } else if let email = user?.email {
            return email
        } else {
            return "User"
        }
    }
    
    /// Check if a user is currently signed in
    var isSignedIn: Bool {
        return user != nil
    }
} 