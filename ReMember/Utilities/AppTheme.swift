import SwiftUI

struct AppTheme {
    // Main colors
    static let background = Color.black
    static let textPrimary = Color(red: 0.0, green: 0.8, blue: 0.2) // CRT green
    static let textSecondary = Color(red: 0.0, green: 0.6, blue: 0.15)
    static let accent = Color(red: 0.1, green: 0.9, blue: 0.9) // Cyan accent
    static let destructive = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    // UI element colors
    static let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.15)
    static let fieldBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    
    // Font styles
    static func pixelFont(size: CGFloat) -> Font {
        return Font.custom("Menlo", size: size)
    }
    
    // Decay indicators
    static func colorForDecayLevel(_ level: Int) -> Color {
        // Ensure the level is within valid range
        let validLevel = max(0, min(level, 100))
        let decayFactor = Double(validLevel) / 100.0
        
        // Interpolate from green to red as decay increases
        return Color(
            red: 0.0 + decayFactor * 0.9,
            green: 0.8 - decayFactor * 0.6,
            blue: 0.2 - decayFactor * 0.1
        )
    }
}

// CRT screen effect modifier
struct CRTScreenModifier: ViewModifier {
    let intensity: Double
    
    func body(content: Content) -> some View {
        // Ensure intensity is within valid range
        let safeIntensity = max(0.0, min(intensity, 1.0))
        
        return content
            .overlay(
                ZStack {
                    // Horizontal scan lines
                    VStack(spacing: 2) {
                        ForEach(0..<50, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.black.opacity(0.2))
                                .frame(height: 1)
                        }
                    }
                    .mask(Rectangle())
                    
                    // CRT vignette effect
                    RadialGradient(
                        gradient: Gradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.3 * safeIntensity)
                            ]
                        ),
                        center: .center,
                        startRadius: 100,
                        endRadius: 300
                    )
                }
            )
            .background(AppTheme.background)
    }
}

// Screen flicker effect
struct ScreenFlickerModifier: ViewModifier {
    let active: Bool
    
    @State private var opacity: Double = 1.0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                guard active else { return }
                
                withAnimation(
                    Animation
                        .easeInOut(duration: 0.1)
                        .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.9
                }
            }
    }
}

// ViewBuilder for decayed text
struct DecayedText: View {
    let text: String
    let decayLevel: Int
    let size: CGFloat
    
    // Use a fixed offset per entry rather than a random one that changes
    @State private var offset: CGSize = .zero
    
    // Use ID to keep the effect consistent for each text item
    private let id = UUID()
    
    var body: some View {
        // Ensure decayLevel is within valid range
        let validDecayLevel = max(0, min(decayLevel, 100))
        let decayedText = TextDecayEffect.applyDecay(to: text, level: validDecayLevel)
        
        return Text(decayedText)
            .font(AppTheme.pixelFont(size: size))
            .foregroundColor(AppTheme.colorForDecayLevel(validDecayLevel))
            .blur(radius: TextDecayEffect.blurEffect(for: validDecayLevel))
            .opacity(TextDecayEffect.opacityEffect(for: validDecayLevel))
            .offset(offset)
            .onAppear {
                // Only apply jitter effects for heavy decay to minimize movement
                if validDecayLevel > 60 {
                    // Create a deterministic jitter based on the text content and ID
                    // to ensure consistent behavior for the same entry
                    let seed = abs((text.hashValue + id.hashValue) % 1000)
                    let magnitude = Double(validDecayLevel) / 100.0 * 2.0
                    
                    // Fixed offsets without random elements to avoid NaN
                    let xOffset = (Double(seed % 7) - 3.0) * magnitude
                    let yOffset = (Double(seed % 5) - 2.0) * magnitude
                    
                    // Validate the offset values to ensure they're not NaN or infinite
                    let safeXOffset = xOffset.isFinite ? xOffset : 0.0
                    let safeYOffset = yOffset.isFinite ? yOffset : 0.0
                    
                    withAnimation(.easeInOut(duration: 0.2)) {
                        offset = CGSize(width: safeXOffset, height: safeYOffset)
                    }
                }
            }
            .id(text + String(validDecayLevel))
    }
}

// Extension to add the theme modifiers to views
extension View {
    func crtScreen(intensity: Double = 1.0) -> some View {
        self.modifier(CRTScreenModifier(intensity: intensity))
    }
    
    func screenFlicker(active: Bool = true) -> some View {
        self.modifier(ScreenFlickerModifier(active: active))
    }
} 