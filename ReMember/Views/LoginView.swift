import SwiftUI
import Firebase
import GoogleSignIn

struct LoginView: View {
    // Environment object for the authentication manager
    @EnvironmentObject var authManager: AuthManager
    
    // For navigation
    @State private var isShowingSignUp = false
    @State private var isShowingResetPassword = false
    
    // Form data
    @State private var email = ""
    @State private var password = ""
    
    // Validation states
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                GlitchTheme.background
                    .ignoresSafeArea()
                
                // Use ScrollView to handle keyboard better
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Title with glitch effect
                        Text("Re:Member")
                            .font(GlitchTheme.glitchFont(size: 32))
                            .foregroundColor(GlitchTheme.terminalGreen)
                            .padding(.top, 40)
                            .modifier(GlitchTheme.RGBSplitModifier(amount: 1.5, angle: 90))
                        
                        Text("LOG IN")
                            .font(GlitchTheme.terminalFont(size: 18))
                            .foregroundColor(GlitchTheme.glitchCyan)
                            .padding(.bottom, 20)
                        
                        // Login form
                        VStack(spacing: 15) {
                            // Email field - fixed height
                            ZStack(alignment: .leading) {
                                if email.isEmpty {
                                    Text("EMAIL")
                                        .foregroundColor(GlitchTheme.terminalGreen.opacity(0.5))
                                        .font(GlitchTheme.terminalFont(size: 16))
                                        .padding(.leading, 16)
                                }
                                
                                TextField("", text: $email)
                                    .font(GlitchTheme.terminalFont(size: 16))
                                    .foregroundColor(GlitchTheme.terminalGreen)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding()
                            }
                            .frame(height: 50) // Fixed height
                            .background(GlitchTheme.fieldBackground)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(GlitchTheme.glitchCyan, lineWidth: 1)
                            )
                            
                            // Password field - fixed height
                            ZStack(alignment: .leading) {
                                if password.isEmpty {
                                    Text("PASSWORD")
                                        .foregroundColor(GlitchTheme.terminalGreen.opacity(0.5))
                                        .font(GlitchTheme.terminalFont(size: 16))
                                        .padding(.leading, 16)
                                }
                                
                                SecureField("", text: $password)
                                    .font(GlitchTheme.terminalFont(size: 16))
                                    .foregroundColor(GlitchTheme.terminalGreen)
                                    .padding()
                            }
                            .frame(height: 50) // Fixed height
                            .background(GlitchTheme.fieldBackground)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(GlitchTheme.glitchCyan, lineWidth: 1)
                            )
                            
                            // Error message with fixed height container
                            ZStack {
                                if showError {
                                    Text(errorMessage)
                                        .font(GlitchTheme.terminalFont(size: 14))
                                        .foregroundColor(GlitchTheme.glitchRed)
                                        .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(height: 20) // Allocate fixed space for error
                            .padding(.top, 5)
                            
                            // Login button
                            Button(action: loginWithEmail) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(GlitchTheme.glitchCyan)
                                    
                                    if authManager.authState == .loading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: GlitchTheme.background))
                                    } else {
                                        Text("LOGIN")
                                            .font(GlitchTheme.terminalFont(size: 16))
                                            .foregroundColor(GlitchTheme.background)
                                            .padding(.vertical, 10)
                                    }
                                }
                                .frame(height: 50)
                            }
                            .disabled(authManager.authState == .loading)
                            .padding(.top, 10)
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(GlitchTheme.terminalGreen.opacity(0.5))
                                    .frame(height: 1)
                                
                                Text("OR")
                                    .font(GlitchTheme.terminalFont(size: 14))
                                    .foregroundColor(GlitchTheme.terminalGreen.opacity(0.8))
                                
                                Rectangle()
                                    .fill(GlitchTheme.terminalGreen.opacity(0.5))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 15)
                            
                            // Google Sign-In button
                            Button(action: loginWithGoogle) {
                                HStack {
                                    Image(systemName: "g.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    
                                    Text("Continue with Google")
                                        .font(GlitchTheme.terminalFont(size: 16))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50) // Fixed height
                                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(authManager.authState == .loading)
                            
                            // Links for sign up and password reset
                            HStack {
                                Button("CREATE ACCOUNT") {
                                    isShowingSignUp = true
                                }
                                .font(GlitchTheme.terminalFont(size: 14))
                                .foregroundColor(GlitchTheme.glitchCyan)
                                
                                Spacer()
                                
                                Button("FORGOT PASSWORD") {
                                    isShowingResetPassword = true
                                }
                                .font(GlitchTheme.terminalFont(size: 14))
                                .foregroundColor(GlitchTheme.glitchCyan)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 30)
                        
                        // Add extra space at the bottom
                        Spacer(minLength: 50)
                    }
                    .padding()
                    .modifier(GlitchTheme.CRTEffectModifier(intensity: 0.3))
                }
                .animation(nil) // Disable automatic animations
            }
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $isShowingResetPassword) {
                ResetPasswordView()
                    .environmentObject(authManager)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Authentication Methods
    
    private func loginWithEmail() {
        // Basic validation
        guard !email.isEmpty else {
            showError(message: "Please enter your email")
            return
        }
        
        guard !password.isEmpty else {
            showError(message: "Please enter your password")
            return
        }
        
        // Attempt login
        Task {
            let success = await authManager.signIn(email: email, password: password)
            if !success, let error = authManager.error {
                await MainActor.run {
                    showError(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func loginWithGoogle() {
        Task {
            let success = await authManager.signInWithGoogle()
            if !success, let error = authManager.error {
                await MainActor.run {
                    showError(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
} 