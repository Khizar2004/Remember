import SwiftUI

struct SignUpView: View {
    // Environment object for authentication
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    // Form data
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    // Validation states
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            GlitchTheme.background
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Title with glitch effect
                    Text("Re:Member")
                        .font(GlitchTheme.glitchFont(size: 32))
                        .foregroundColor(GlitchTheme.terminalGreen)
                        .padding(.top, 40)
                        .modifier(GlitchTheme.RGBSplitModifier(amount: 1.5, angle: 90))
                    
                    Text("CREATE ACCOUNT")
                        .font(GlitchTheme.terminalFont(size: 18))
                        .foregroundColor(GlitchTheme.glitchCyan)
                        .padding(.bottom, 20)
                    
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
                        
                        // Confirm password field - fixed height
                        ZStack(alignment: .leading) {
                            if confirmPassword.isEmpty {
                                Text("CONFIRM PASSWORD")
                                    .foregroundColor(GlitchTheme.terminalGreen.opacity(0.5))
                                    .font(GlitchTheme.terminalFont(size: 16))
                                    .padding(.leading, 16)
                            }
                            
                            SecureField("", text: $confirmPassword)
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
                        
                        // Sign up button
                        Button(action: signUp) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(GlitchTheme.glitchCyan)
                                
                                if authManager.authState == .loading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: GlitchTheme.background))
                                } else {
                                    Text("SIGN UP")
                                        .font(GlitchTheme.terminalFont(size: 16))
                                        .foregroundColor(GlitchTheme.background)
                                        .padding(.vertical, 10)
                                }
                            }
                            .frame(height: 50)
                        }
                        .disabled(authManager.authState == .loading)
                        .padding(.top, 10)
                        
                        // Back to login button
                        Button("BACK TO LOGIN") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(GlitchTheme.terminalFont(size: 14))
                        .foregroundColor(GlitchTheme.glitchCyan)
                        .padding(.top, 15)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer(minLength: 50)
                }
                .padding()
                .modifier(GlitchTheme.CRTEffectModifier(intensity: 0.3))
            }
            .animation(nil) // Disable automatic animations
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Sign Up Method
    
    private func signUp() {
        // Basic validation
        guard !email.isEmpty else {
            showError(message: "Please enter your email")
            return
        }
        
        guard !password.isEmpty else {
            showError(message: "Please enter your password")
            return
        }
        
        guard password.count >= 6 else {
            showError(message: "Password must be at least 6 characters")
            return
        }
        
        guard password == confirmPassword else {
            showError(message: "Passwords do not match")
            return
        }
        
        // Attempt sign up
        Task {
            let success = await authManager.signUp(email: email, password: password)
            if success {
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } else if let error = authManager.error {
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
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthManager())
    }
} 