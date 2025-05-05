import SwiftUI

struct ResetPasswordView: View {
    // Environment object for authentication
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    // State variables
    @State private var email = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var resetSent = false
    
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
                    
                    Text("RESET PASSWORD")
                        .font(GlitchTheme.terminalFont(size: 18))
                        .foregroundColor(GlitchTheme.glitchCyan)
                        .padding(.bottom, 20)
                    
                    // Success message
                    if resetSent {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 50))
                                .foregroundColor(GlitchTheme.terminalGreen)
                            
                            Text("PASSWORD RESET EMAIL SENT")
                                .font(GlitchTheme.terminalFont(size: 16))
                                .foregroundColor(GlitchTheme.terminalGreen)
                                .multilineTextAlignment(.center)
                            
                            Text("Check your email for instructions to reset your password")
                                .font(GlitchTheme.terminalFont(size: 14))
                                .foregroundColor(GlitchTheme.terminalGreen.opacity(0.7))
                                .multilineTextAlignment(.center)
                            
                            Button("RETURN TO LOGIN") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .font(GlitchTheme.terminalFont(size: 16))
                            .foregroundColor(GlitchTheme.glitchCyan)
                            .padding(.top, 20)
                        }
                        .padding(.horizontal, 30)
                    } else {
                        // Reset form
                        VStack(spacing: 15) {
                            Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(GlitchTheme.terminalFont(size: 14))
                                .foregroundColor(GlitchTheme.terminalGreen.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 10)
                            
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
                            
                            // Reset button
                            Button(action: resetPassword) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(GlitchTheme.glitchCyan)
                                    
                                    if authManager.isAuthenticating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: GlitchTheme.background))
                                    } else {
                                        Text("SEND RESET LINK")
                                            .font(GlitchTheme.terminalFont(size: 16))
                                            .foregroundColor(GlitchTheme.background)
                                            .padding(.vertical, 10)
                                    }
                                }
                                .frame(height: 50)
                            }
                            .disabled(authManager.isAuthenticating)
                            .padding(.top, 10)
                            
                            // Back to login button
                            Button("CANCEL") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .font(GlitchTheme.terminalFont(size: 14))
                            .foregroundColor(GlitchTheme.glitchCyan)
                            .padding(.top, 15)
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    // Add extra space at the bottom
                    Spacer(minLength: 50)
                }
                .padding()
                .modifier(GlitchTheme.CRTEffectModifier(intensity: 0.3))
            }
            .animation(nil) // Disable automatic animations
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Reset Password Method
    
    private func resetPassword() {
        // Basic validation
        guard !email.isEmpty else {
            showError(message: "Please enter your email")
            return
        }
        
        // Validate email format
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        guard emailPred.evaluate(with: email) else {
            showError(message: "Please enter a valid email address")
            return
        }
        
        // Attempt to send reset email
        Task {
            let success = await authManager.resetPassword(email: email)
            
            await MainActor.run {
                if success {
                    resetSent = true
                } else if let error = authManager.error {
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
struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView()
            .environmentObject(AuthManager())
    }
} 