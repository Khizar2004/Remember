import SwiftUI

struct MemoryChallengeView: View {
    @StateObject var challenge: MemoryChallenge
    @State private var userAnswer: String = ""
    @State private var showingResult: Bool = false
    @State private var lastAnswerCorrect: Bool = false
    @State private var showingConfetti: Bool = false
    @State private var animationAmount: CGFloat = 1
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            GlitchTheme.background.ignoresSafeArea()
            
            // Main content
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("MEMORY RECOVERY")
                        .font(GlitchTheme.terminalFont(size: 24))
                        .foregroundColor(GlitchTheme.glitchCyan)
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(GlitchTheme.glitchRed)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Progress indicator
                ProgressBar(progress: challenge.progress)
                    .frame(height: 8)
                    .padding(.horizontal)
                
                // Score indicator
                if challenge.questions.count > 0 {
                    HStack {
                        Text("SCORE: \(challenge.score)/\(challenge.questions.count)")
                            .font(GlitchTheme.terminalFont(size: 16))
                            .foregroundColor(GlitchTheme.glitchYellow)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                if challenge.isCompleted {
                    // Challenge completion view
                    completionView
                } else if let question = challenge.currentQuestion {
                    // Current question view
                    ScrollView {
                        VStack(spacing: 20) {
                            // Question
                            Text(question.question)
                                .font(GlitchTheme.terminalFont(size: 18))
                                .foregroundColor(GlitchTheme.terminalGreen)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(GlitchTheme.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(GlitchTheme.glitchCyan.opacity(0.5), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal)
                            
                            // Answer input
                            VStack(spacing: 16) {
                                TextField("Enter your answer", text: $userAnswer)
                                    .font(GlitchTheme.terminalFont(size: 16))
                                    .foregroundColor(GlitchTheme.terminalGreen)
                                    .padding()
                                    .background(GlitchTheme.fieldBackground)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(GlitchTheme.glitchCyan.opacity(0.5), lineWidth: 1)
                                    )
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                
                                Button(action: {
                                    submitAnswer()
                                }) {
                                    Text("SUBMIT")
                                        .font(GlitchTheme.terminalFont(size: 16))
                                        .foregroundColor(GlitchTheme.background)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(GlitchTheme.glitchCyan)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(GlitchTheme.terminalGreen, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                            
                            Spacer()
                        }
                        .padding(.bottom, 30)
                    }
                } else {
                    // No questions available
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(GlitchTheme.glitchYellow)
                        
                        Text("NO PROTECTION QUESTIONS")
                            .font(GlitchTheme.terminalFont(size: 24))
                            .foregroundColor(GlitchTheme.glitchYellow)
                            .multilineTextAlignment(.center)
                        
                        Text("This memory doesn't have any protection questions.\nIt will be restored automatically.")
                            .font(GlitchTheme.terminalFont(size: 16))
                            .foregroundColor(GlitchTheme.terminalGreen)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            // Auto-restore memory without questions
                            challenge.onComplete?(true)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("RESTORE MEMORY")
                                .font(GlitchTheme.terminalFont(size: 16))
                                .foregroundColor(GlitchTheme.background)
                                .padding()
                                .frame(width: 200)
                                .background(GlitchTheme.glitchCyan)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(GlitchTheme.terminalGreen, lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .padding(.bottom, 20)
            .opacity(showingResult ? 0.3 : 1)
            .blur(radius: showingResult ? 3 : 0)
            
            // Result overlay
            if showingResult {
                resultOverlay
            }
            
            // Confetti overlay when challenge is completed successfully
            if showingConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .navigationBarHidden(true)
        .background(GlitchTheme.background)
    }
    
    // Result overlay view
    private var resultOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: lastAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(lastAnswerCorrect ? GlitchTheme.glitchCyan : GlitchTheme.glitchRed)
                .scaleEffect(animationAmount)
                .animation(
                    Animation.easeInOut(duration: 0.5)
                        .repeatCount(1, autoreverses: true),
                    value: animationAmount
                )
                .onAppear {
                    animationAmount = 1.5
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        animationAmount = 1
                    }
                }
            
            Text(lastAnswerCorrect ? "CORRECT!" : "INCORRECT")
                .font(GlitchTheme.terminalFont(size: 24))
                .foregroundColor(lastAnswerCorrect ? GlitchTheme.glitchCyan : GlitchTheme.glitchRed)
                .padding()
            
            if !challenge.isCompleted {
                Button(action: {
                    withAnimation {
                        showingResult = false
                    }
                    userAnswer = ""
                }) {
                    Text("CONTINUE")
                        .font(GlitchTheme.terminalFont(size: 16))
                        .foregroundColor(GlitchTheme.background)
                        .padding()
                        .frame(width: 200)
                        .background(GlitchTheme.glitchCyan)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GlitchTheme.terminalGreen, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(GlitchTheme.cardBackground.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lastAnswerCorrect ? GlitchTheme.glitchCyan : GlitchTheme.glitchRed, lineWidth: 2)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    // Challenge completion view
    private var completionView: some View {
        VStack(spacing: 30) {
            let isSuccessful = Double(challenge.score) / Double(challenge.questions.count) >= 0.5
            
            if isSuccessful {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(GlitchTheme.glitchCyan)
                
                Text("MEMORY RECOVERED")
                    .font(GlitchTheme.terminalFont(size: 28))
                    .foregroundColor(GlitchTheme.glitchCyan)
                    .multilineTextAlignment(.center)
                
                Text("Score: \(challenge.score)/\(challenge.questions.count)")
                    .font(GlitchTheme.terminalFont(size: 18))
                    .foregroundColor(GlitchTheme.glitchYellow)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 80))
                    .foregroundColor(GlitchTheme.glitchRed)
                
                Text("RECOVERY FAILED")
                    .font(GlitchTheme.terminalFont(size: 28))
                    .foregroundColor(GlitchTheme.glitchRed)
                    .multilineTextAlignment(.center)
                
                Text("Score: \(challenge.score)/\(challenge.questions.count)")
                    .font(GlitchTheme.terminalFont(size: 18))
                    .foregroundColor(GlitchTheme.glitchYellow)
                
                Text("TRY AGAIN TO SAVE THIS MEMORY")
                    .font(GlitchTheme.terminalFont(size: 16))
                    .foregroundColor(GlitchTheme.terminalGreen)
                    .padding(.top, 10)
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    challenge.reset()
                }) {
                    Text("TRY AGAIN")
                        .font(GlitchTheme.terminalFont(size: 16))
                        .foregroundColor(GlitchTheme.background)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(GlitchTheme.glitchYellow)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GlitchTheme.terminalGreen, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("EXIT")
                        .font(GlitchTheme.terminalFont(size: 16))
                        .foregroundColor(GlitchTheme.background)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(GlitchTheme.glitchCyan)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GlitchTheme.terminalGreen, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .padding(30)
        .onAppear {
            let isSuccessful = Double(challenge.score) / Double(challenge.questions.count) >= 0.5
            if isSuccessful {
                showingConfetti = true
                HapticFeedback.success()
                
                // Hide confetti after some time
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showingConfetti = false
                    }
                }
            } else {
                HapticFeedback.error()
            }
        }
    }
    
    // Submit answer
    private func submitAnswer() {
        HapticFeedback.light()
        lastAnswerCorrect = challenge.submitAnswer(userAnswer)
        
        withAnimation {
            showingResult = true
        }
        
        // If challenge is completed, automatically dismiss result overlay and transition to completion view
        if challenge.isCompleted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showingResult = false
                    userAnswer = ""
                }
            }
        } else {
            // For regular questions, hide the result after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showingResult = false
                    userAnswer = ""
                }
            }
        }
    }
}

// Progress bar component
struct ProgressBar: View {
    var progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(GlitchTheme.cardBackground)
                    .cornerRadius(5)
                
                Rectangle()
                    .fill(GlitchTheme.glitchCyan)
                    .cornerRadius(5)
                    .frame(width: min(CGFloat(self.progress) / 100 * geometry.size.width, geometry.size.width))
                    .animation(.linear, value: progress)
            }
        }
    }
}

// Confetti view for successful challenge completion
struct ConfettiView: View {
    @State private var particles = [Particle]()
    
    struct Particle: Identifiable {
        let id = UUID()
        let position: CGPoint
        let color: Color
        let rotation: Double
        let size: CGFloat
        let duration: Double
        let delay: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Rectangle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size * 2)
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(0)
                    .animation(
                        Animation.easeOut(duration: particle.duration)
                            .delay(particle.delay)
                            .speed(0.7), 
                        value: true
                    )
            }
        }
        .onAppear {
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            for _ in 0..<100 {
                let position = CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight / 2)
                )
                let color = colors.randomElement()!
                let rotation = Double.random(in: 0...360)
                let size = CGFloat.random(in: 5...15)
                let duration = Double.random(in: 1.0...3.0)
                let delay = Double.random(in: 0...0.5)
                
                let particle = Particle(
                    position: position,
                    color: color,
                    rotation: rotation,
                    size: size,
                    duration: duration,
                    delay: delay
                )
                
                particles.append(particle)
            }
        }
    }
} 