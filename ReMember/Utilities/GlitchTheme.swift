import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// GlitchTheme contains all visual styling for Re:Member's retro-futuristic glitched memory terminal aesthetic
struct GlitchTheme {
    // Colors
    
    // Main palette - dark blue-black base with neon highlights
    static let background = Color(red: 0.05, green: 0.05, blue: 0.1) // Deep blue-black
    static let terminalGreen = Color(red: 0.0, green: 0.9, blue: 0.4) // Bright terminal green
    static let glitchPink = Color(red: 0.98, green: 0.2, blue: 0.6) // Magenta-pink for error states
    static let glitchCyan = Color(red: 0.1, green: 0.9, blue: 0.9) // Cyan for highlights
    static let glitchRed = Color(red: 0.9, green: 0.2, blue: 0.2) // Red for critical errors/high decay
    static let glitchYellow = Color(red: 0.9, green: 0.8, blue: 0.2) // Warning color
    static let glitchOrange = Color(red: 0.95, green: 0.5, blue: 0.1) // Orange for high decay
    
    // UI element backgrounds
    static let cardBackground = Color(red: 0.08, green: 0.09, blue: 0.15).opacity(0.7) // Semi-transparent
    static let fieldBackground = Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.5) // Input fields
    
    // Fonts
    
    // Terminal style fonts
    static func terminalFont(size: CGFloat) -> Font {
        let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        return Font.custom("Menlo", size: scaledSize).monospaced()
    }
    
    static func pixelFont(size: CGFloat) -> Font {
        let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        if let descriptor = UIFont.monospacedSystemFont(ofSize: scaledSize, weight: .regular).fontDescriptor
            .withDesign(.monospaced) {
            let font = UIFont(descriptor: descriptor, size: scaledSize)
            return Font(font)
        }
        return Font.system(size: scaledSize).monospaced()
    }
    
    static func glitchFont(size: CGFloat) -> Font {
        let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        return Font.custom("Menlo", size: scaledSize).monospaced().weight(.bold)
    }

    // Decay Effects
    
    // Color mapping for decay levels (0-100)
    static func colorForDecayLevel(_ level: Int) -> Color {
        let validLevel = max(0, min(level, 100))
        let decayFactor = Double(validLevel) / 100.0
        
        if decayFactor < 0.3 {
            return Color(
                red: 0.0,
                green: 0.9 - (decayFactor * 0.3),
                blue: 0.4 + (decayFactor * 1.0)
            )
        } else if decayFactor < 0.7 {
            let normalizedFactor = (decayFactor - 0.3) / 0.4
            return Color(
                red: normalizedFactor * 0.9,
                green: 0.8 - (normalizedFactor * 0.4),
                blue: 0.7
            )
        } else {
            let normalizedFactor = (decayFactor - 0.7) / 0.3
            return Color(
                red: 0.9,
                green: 0.4 - (normalizedFactor * 0.4),
                blue: 0.7 - (normalizedFactor * 0.5)
            )
        }
    }
    
    // View Modifiers
    
    // Nostalgic CRT effect with scanlines
    struct CRTEffectModifier: ViewModifier {
        let intensity: Double
        
        func body(content: Content) -> some View {
            let safeIntensity = max(0.0, min(intensity, 1.0))
            
            return content
                .background(background)
                .overlay(
                    ZStack {
                        VStack(spacing: 1) {
                            ForEach(0..<100, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.15 * safeIntensity))
                                    .frame(height: 1)
                            }
                        }
                        .mask(Rectangle())
                        .allowsHitTesting(false) 
                        
                        RadialGradient(
                            gradient: Gradient(
                                colors: [
                                    Color.clear,
                                    Color.black.opacity(0.3 * safeIntensity)
                                ]
                            ),
                            center: .center,
                            startRadius: 50,
                            endRadius: 400
                        )
                        .allowsHitTesting(false) 
                        
                        Rectangle()
                            .fill(
                                Color.white.opacity(0.02 * safeIntensity)
                            )
                            .blendMode(.overlay)
                            .allowsHitTesting(false) 
                    }
                )
                .compositingGroup()
        }
    }
    
    // RGB Split effect for glitching
    struct RGBSplitModifier: ViewModifier {
        let amount: CGFloat
        let angle: Double
        @State private var isAnimating = false
        
        func body(content: Content) -> some View {
            let safeAmount = max(0, min(amount, 5.0))
            
            return content
                .overlay(
                    ZStack {
                        content
                            .colorMultiply(.red)
                            .opacity(0.8)
                            .offset(
                                x: isAnimating ? cos(CGFloat(angle) * .pi / 180) * safeAmount : 0,
                                y: isAnimating ? sin(CGFloat(angle) * .pi / 180) * safeAmount : 0
                            )
                            .blendMode(.screen)
                        
                        content
                            .colorMultiply(.green)
                            .opacity(0.8)
                            .offset(
                                x: 0,
                                y: 0
                            )
                            .blendMode(.screen)
                        
                        content
                            .colorMultiply(.blue)
                            .opacity(0.8)
                            .offset(
                                x: isAnimating ? -cos(CGFloat(angle) * .pi / 180) * safeAmount : 0,
                                y: isAnimating ? -sin(CGFloat(angle) * .pi / 180) * safeAmount : 0
                            )
                            .blendMode(.screen)
                    }
                )
                .compositingGroup()
                .onAppear {
                    if safeAmount > 0.5 {
                        withAnimation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
                }
        }
    }
    
    // Digital noise overlay for decay effects
    struct NoiseModifier: ViewModifier {
        let intensity: Double
        @State private var noisePhase: CGFloat = 0
        
        func body(content: Content) -> some View {
            let safeIntensity = max(0.0, min(intensity, 1.0))
            
            return content
                .overlay(
                    Rectangle()
                        .fill(
                            Color.white.opacity(Double.random(in: 0...0.05) * safeIntensity)
                        )
                        .blendMode(.overlay)
                )
                .onAppear {
                    if safeIntensity > 0.3 {
                        withAnimation(Animation.linear(duration: 0.1).repeatForever(autoreverses: true)) {
                            noisePhase = 1.0
                        }
                    }
                }
        }
    }
    
    // Glitch blocks for error states
    struct GlitchBlocksModifier: ViewModifier {
        let intensity: Double
        @State private var blocks: [GlitchBlock] = []
        @State private var isVisible = false
        
        struct GlitchBlock: Identifiable {
            let id = UUID()
            let x: CGFloat
            let y: CGFloat
            let width: CGFloat
            let height: CGFloat
            let color: Color
        }
        
        func body(content: Content) -> some View {
            ZStack {
                content
                
                if intensity > 0.1, isVisible {
                    ForEach(blocks) { block in
                        Rectangle()
                            .fill(block.color)
                            .frame(width: block.width, height: block.height)
                            .position(x: block.x, y: block.y)
                    }
                }
            }
            .onAppear {
                guard intensity > 0.3 else { return }
                
                let blockCount = min(Int(intensity * 3), 5) // Limit to max 5 blocks
                blocks = (0..<blockCount).map { _ in
                    GlitchBlock(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...800),
                        width: CGFloat.random(in: 10...50),
                        height: CGFloat.random(in: 3...20),
                        color: [glitchCyan, glitchPink, glitchRed].randomElement()!.opacity(Double.random(in: 0.3...0.7))
                    )
                }
                
                if intensity > 0.5 {
                    withAnimation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) {
                        isVisible = true
                    }
                } else {
                    isVisible = true
                }
            }
        }
    }

    // Screen flicker effect
    struct FlickerModifier: ViewModifier {
        let intensity: Double
        @State private var opacity: Double = 1.0
        
        func body(content: Content) -> some View {
            let safeIntensity = max(0.0, min(intensity, 1.0))
            
            content
                .opacity(opacity)
                .onAppear {
                    guard safeIntensity > 0.1 else { return }
                    
                    withAnimation(
                        Animation
                            .easeInOut(duration: 0.1)
                            .repeatForever(autoreverses: true)
                    ) {
                        opacity = 1.0 - (safeIntensity * 0.2)
                    }
                }
        }
    }
}

// ViewBuilder for glitched text
struct GlitchedText: View {
    let text: String
    let decayLevel: Int
    let size: CGFloat
    let isListView: Bool // Flag to determine if this is in a list view
    
    @State private var offset: CGSize = .zero
    @State private var glitchPhase = false
    private let id = UUID()
    
    init(text: String, decayLevel: Int, size: CGFloat, isListView: Bool = false) {
        self.text = text
        self.decayLevel = decayLevel
        self.size = size
        self.isListView = isListView
    }
    
    var body: some View {
        let validDecayLevel = max(0, min(decayLevel, 100))
        let decayFactor = Double(validDecayLevel) / 100.0
        
        let glitchedText: String
        if isListView && validDecayLevel < 90 {
            glitchedText = text
        } else {
            glitchedText = TextDecayEffect.applyDecay(to: text, level: validDecayLevel)
        }
        
        return Text(glitchedText)
            .font(GlitchTheme.pixelFont(size: size))
            .foregroundColor(GlitchTheme.colorForDecayLevel(validDecayLevel))
            .blur(radius: isListView ? min(decayFactor * 0.5, 0.5) : (decayFactor > 0.7 ? 0.8 : 0))
            .opacity(TextDecayEffect.opacityEffect(for: validDecayLevel))
            .offset(offset)
            .modifier(GlitchTheme.RGBSplitModifier(
                amount: isListView ? 0 : (decayFactor > 0.5 ? CGFloat(decayFactor) : 0), 
                angle: 90
            ))
            .onAppear {
                if isListView {
                    return
                }
                
                if validDecayLevel > 40 {
                    let textHash = abs(text.prefix(20).hashValue) 
                    let idHash = abs(id.hashValue)
                    let seed = (textHash % 500) + (idHash % 500) 
                    let magnitude = min(decayFactor * 3.0, 3.0) 
                    
                    let xOffset = min(max((Double(seed % 7) - 3.0), -3.0), 3.0) * magnitude 
                    let yOffset = min(max((Double(seed % 5) - 2.0), -3.0), 3.0) * magnitude
                    
                    let safeXOffset = xOffset.isFinite && !xOffset.isNaN ? xOffset : 0.0
                    let safeYOffset = yOffset.isFinite && !yOffset.isNaN ? yOffset : 0.0
                    
                    if decayFactor > 0.6 {
                        withAnimation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) {
                            offset = CGSize(width: safeXOffset, height: safeYOffset)
                            glitchPhase = true
                        }
                    } else {
                        offset = CGSize(width: safeXOffset / 2, height: safeYOffset / 2)
                    }
                }
            }
            .id(text + String(validDecayLevel))
    }
}

// Enhanced restoration animation
struct EnhancedRestorationView: View {
    let progress: Double
    
    @State private var scanPosition: CGFloat = -200
    @State private var glitchOffset = CGSize.zero
    @State private var glitchBlocks: [GlitchBlock] = []
    @State private var showScanPulse = false
    @State private var dataMatrix: [[Bool]] = Array(repeating: Array(repeating: false, count: 20), count: 20)
    @State private var lastProgressUpdate: Double = 0
    
    struct GlitchBlock: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let color: Color
    }
    
    var body: some View {
        let safeProgress = max(0.0, min(progress, 1.0))
        
        ZStack {
            Rectangle()
                .fill(GlitchTheme.background)
                .opacity(0.9)
            
            VStack(spacing: 3) {
                ForEach(0..<20, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<20, id: \.self) { column in
                            Rectangle()
                                .fill(dataMatrix[row][column] ? GlitchTheme.glitchCyan : GlitchTheme.cardBackground)
                                .frame(width: 12, height: 12)
                                .brightness(dataMatrix[row][column] && row % 2 == 0 ? 0.1 : 0)
                        }
                    }
                }
            }
            .rotationEffect(Angle(degrees: 0))
            .offset(glitchOffset)
            .blur(radius: 0.5)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            GlitchTheme.glitchCyan.opacity(0),
                            GlitchTheme.glitchCyan.opacity(0.7),
                            GlitchTheme.glitchCyan.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .offset(y: scanPosition)
                .opacity(0.8)
                .blur(radius: 1)
            
            VStack {
                Text("MEMORY DEFRAGMENTATION")
                    .font(GlitchTheme.terminalFont(size: 18))
                    .foregroundColor(GlitchTheme.glitchCyan)
                
                Text("\(Int(safeProgress * 100))% COMPLETE")
                    .font(GlitchTheme.terminalFont(size: 22))
                    .foregroundColor(GlitchTheme.terminalGreen)
                    .modifier(GlitchTheme.RGBSplitModifier(amount: safeProgress < 0.9 ? 1.0 : 0.0, angle: 0))
                
                if safeProgress > 0.1 {
                    Text("RECONSTRUCTING DATA SEGMENTS...")
                        .font(GlitchTheme.terminalFont(size: 14))
                        .foregroundColor(GlitchTheme.glitchYellow)
                }
                
                if safeProgress > 0.5 {
                    Text("STABILIZING MEMORY FRAGMENTS")
                        .font(GlitchTheme.terminalFont(size: 14))
                        .foregroundColor(GlitchTheme.glitchYellow)
                }
                
                if safeProgress > 0.9 {
                    Text("SYSTEM INTEGRITY RESTORED")
                        .font(GlitchTheme.terminalFont(size: 14))
                        .foregroundColor(GlitchTheme.glitchCyan)
                        .modifier(GlitchTheme.FlickerModifier(intensity: 0.5))
                }
            }
            .padding()
            .background(GlitchTheme.background.opacity(0.7))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(GlitchTheme.glitchCyan, lineWidth: 1)
            )
            
            ForEach(glitchBlocks) { block in
                Rectangle()
                    .fill(block.color)
                    .frame(width: block.width, height: block.height)
                    .position(x: block.x, y: block.y)
            }
            
            if showScanPulse {
                Circle()
                    .stroke(GlitchTheme.glitchCyan, lineWidth: 1)
                    .frame(width: 400 * safeProgress, height: 400 * safeProgress)
                    .opacity(0.5)
                    .blur(radius: 3)
            }
        }
        .onChange(of: safeProgress) { newProgress in
            if abs(newProgress - lastProgressUpdate) >= 0.02 {
                updateDataMatrix(for: newProgress)
                lastProgressUpdate = newProgress
            }
        }
        .onAppear {
            dataMatrix = Array(repeating: Array(repeating: false, count: 20), count: 20)
            lastProgressUpdate = 0
            
            updateDataMatrix(for: safeProgress)
            
            withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                scanPosition = 400
            }
            
            updateGlitchBlocks()
            
            Timer.publish(every: 0.3, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    updateGlitchOffset()
                    updateGlitchBlocks()
                    
                    if Bool.random() && safeProgress > 0.3 {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showScanPulse = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                showScanPulse = false
                            }
                        }
                    }
                }
        }
    }
    
    private func updateDataMatrix(for progress: Double) {
        withAnimation(.easeInOut(duration: 0.1)) {
            for row in 0..<20 {
                for column in 0..<20 {
                    let cellIndex = (row * 20) + column
                    let shouldBeRestored = Double(cellIndex) / 400.0 <= progress
                    
                    if dataMatrix[row][column] != shouldBeRestored {
                        dataMatrix[row][column] = shouldBeRestored
                    }
                }
            }
        }
    }
    
    private func updateGlitchOffset() {
        withAnimation(.easeInOut(duration: 0.1)) {
            let offsetX = CGFloat.random(in: -3...3)
            let offsetY = CGFloat.random(in: -3...3)
            glitchOffset = CGSize(width: offsetX, height: offsetY)
        }
    }
    
    private func updateGlitchBlocks() {
        withAnimation(.easeInOut(duration: 0.1)) {
            if Bool.random() {
                glitchBlocks = []
            }
            
            let blockCount = Int((1.0 - progress) * 10)
            let newBlocks = (0..<blockCount).map { _ in
                GlitchBlock(
                    x: CGFloat.random(in: 0...400),
                    y: CGFloat.random(in: 0...800),
                    width: CGFloat.random(in: 10...80),
                    height: CGFloat.random(in: 2...10),
                    color: [GlitchTheme.glitchCyan, GlitchTheme.glitchPink].randomElement()!.opacity(Double.random(in: 0.3...0.7))
                )
            }
            
            glitchBlocks = newBlocks
        }
    }
}

// Memory deletion effect animation
struct DeletionEffectModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .modifier(GlitchTheme.RGBSplitModifier(amount: isAnimating ? 6.0 : 0.0, angle: 90))
            .opacity(isAnimating ? 0.0 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isAnimating = true
                }
            }
    }
}

// Extensions to add the theme modifiers to views
extension View {
    func crtEffect(intensity: Double = 1.0) -> some View {
        self.modifier(GlitchTheme.CRTEffectModifier(intensity: intensity))
    }
    
    func rgbSplit(amount: CGFloat = 1.0, angle: Double = 0) -> some View {
        self.modifier(GlitchTheme.RGBSplitModifier(amount: amount, angle: angle))
    }
    
    func digitalNoise(intensity: Double = 0.5) -> some View {
        self.modifier(GlitchTheme.NoiseModifier(intensity: intensity))
    }
    
    func glitchBlocks(intensity: Double = 0.5) -> some View {
        self.modifier(GlitchTheme.GlitchBlocksModifier(intensity: intensity))
    }
    
    func screenFlicker(intensity: Double = 0.5) -> some View {
        self.modifier(GlitchTheme.FlickerModifier(intensity: intensity))
    }
    
    // Extension for placeholder text in TextField
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    func deletionEffect() -> some View {
        modifier(DeletionEffectModifier())
    }
} 
