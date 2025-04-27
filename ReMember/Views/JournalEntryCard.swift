import SwiftUI
import Combine

struct JournalEntryCard: View {
    let entry: JournalEntry
    let cardWidth: CGFloat
    
    @State private var showingDetailView = false
    @State private var flickerPhase = UUID()
    @State private var flickerTimer: Timer? = nil
    @GestureState private var isPressed = false
    @StateObject private var viewModel = CardViewModel()
    
    var body: some View {
        Button(action: {
            showingDetailView = true
        }) {
            ZStack {
                // Card background with decay visual effects
                RoundedRectangle(cornerRadius: 12)
                    .fill(GlitchTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                GlitchTheme.colorForDecayLevel(entry.decayLevel).opacity(0.6),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    .digitalNoise(intensity: min(Double(entry.decayLevel) / 300, 0.3))
                
                // Card content
                VStack(alignment: .leading, spacing: 10) {
                    // Header section - decay meter, ID, date
                    HStack {
                        // Corruption level indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                .frame(width: 8, height: 8)
                                .screenFlicker(intensity: Double(entry.decayLevel) / 100.0)
                            
                            Text("\(100 - entry.decayLevel)%")
                                .font(GlitchTheme.terminalFont(size: 12))
                                .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                        }
                        
                        Spacer()
                        
                        Text(formattedDate(entry.creationDate))
                            .font(GlitchTheme.terminalFont(size: 10))
                            .foregroundColor(GlitchTheme.terminalGreen)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    
                    // Memory title with appropriate corruption effects
                    VStack(alignment: .leading, spacing: 2) {
                        // For heavily decayed titles, use the obscuring technique
                        if entry.decayLevel >= 75 {
                            Text(obscureTextByDecay(entry.title, decay: entry.decayLevel))
                                .font(GlitchTheme.pixelFont(size: 16))
                                .lineLimit(2)
                                .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                .padding(.horizontal, 12)
                                .offset(x: entry.decayLevel > 90 ? textChaosOffset() : 0)
                                .rgbSplit(amount: entry.decayLevel > 90 ? min(CGFloat(entry.decayLevel) / 50, 1.8) : 0, angle: 90)
                        } else {
                            Text(entry.title)
                                .font(GlitchTheme.pixelFont(size: 16))
                                .lineLimit(2)
                                .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                .padding(.horizontal, 12)
                        }
                    }
                    
                    // Content preview with decay effects
                    VStack(alignment: .leading) {
                        if entry.decayLevel >= 85 {
                            // For heavily decayed content previews, use redacted blocks
                            Text(obscureTextByDecay(entry.content.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines), decay: entry.decayLevel))
                                .font(GlitchTheme.pixelFont(size: 12))
                                .lineLimit(3)
                                .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                .padding(.horizontal, 12)
                                .blur(radius: min(Double(entry.decayLevel) / 150, 0.5))
                                .digitalNoise(intensity: min(Double(entry.decayLevel) / 250, 0.2))
                        } else if entry.decayLevel >= 65 {
                            // For medium decayed content, use decay effects
                            GlitchedText(
                                text: entry.content.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines), 
                                decayLevel: entry.decayLevel,
                                size: 12,
                                isListView: true
                            )
                            .lineLimit(3)
                            .padding(.horizontal, 12)
                            .digitalNoise(intensity: min(Double(entry.decayLevel) / 250, 0.2))
                        } else {
                            // For less decayed content, just show preview
                            Text(entry.content.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(GlitchTheme.pixelFont(size: 12))
                                .lineLimit(3)
                                .foregroundColor(GlitchTheme.terminalGreen)
                                .padding(.horizontal, 12)
                        }
                    }
                    
                    // Footer section - tags, photo indicators
                    HStack {
                        // Tags (limited display)
                        if !entry.tags.isEmpty {
                            HStack(spacing: 5) {
                                ForEach(Array(entry.tags.prefix(2)), id: \.self) { tag in
                                    Text(tag)
                                        .font(GlitchTheme.pixelFont(size: 9))
                                        .foregroundColor(GlitchTheme.glitchCyan)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(GlitchTheme.fieldBackground)
                                        .cornerRadius(3)
                                }
                                
                                if entry.tags.count > 2 {
                                    Text("+\(entry.tags.count - 2)")
                                        .font(GlitchTheme.pixelFont(size: 9))
                                        .foregroundColor(GlitchTheme.glitchYellow)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Photo attachment indicator
                        if !entry.photoAttachments.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "photo")
                                    .font(.system(size: 10))
                                    .foregroundColor(GlitchTheme.glitchCyan)
                                
                                Text("\(entry.photoAttachments.count)")
                                    .font(GlitchTheme.terminalFont(size: 10))
                                    .foregroundColor(GlitchTheme.glitchCyan)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .frame(width: cardWidth)
                
                // Visual effects overlay for heavily decayed cards
                if entry.decayLevel > 70 {
                    // Add scan lines
                    ScanlineOverlay(type: entry.decayLevel > 85 ? .heavy : .light)
                        .blendMode(.overlay)
                        .opacity(min(Double(entry.decayLevel) / 100, 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(width: cardWidth, height: 160)
        }
        .buttonStyle(CardButtonStyle())
        .navigationDestination(isPresented: $showingDetailView) {
            // Navigate to entry detail view
            if let store = viewModel.store {
                EntryDetailView(store: store, entry: entry)
            } else {
                Text("Error: Store not available")
                    .font(GlitchTheme.terminalFont(size: 16))
                    .foregroundColor(GlitchTheme.glitchRed)
            }
        }
        .onAppear {
            // Initialize store and start flicker timer
            viewModel.initializeStore()
            
            // Start flicker timer for redaction effects with higher priority
            self.flickerTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                // Always update the flicker phase regardless of press state
                self.flickerPhase = UUID()
            }
            
            // Make sure the timer runs on a high-priority runloop mode
            RunLoop.current.add(self.flickerTimer!, forMode: .common)
        }
        .onDisappear {
            // Clean up timer
            flickerTimer?.invalidate()
            flickerTimer = nil
        }
        .simultaneousGesture(
            // Track when the card is being pressed
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
        )
    }
    
    // Helper to obscure text based on decay level with visually rich effects
    private func obscureTextByDecay(_ text: String, decay: Int) -> String {
        // Cache results for performance - using flickerPhase as part of the cache key
        struct DecayCache {
            static var cache: [String: [String: String]] = [:]
            static let limit = 30
        }
        
        // Generate cache key using both decay and current flicker phase
        let cacheKey = "\(decay)_\(flickerPhase)"
        
        // Check cache first
        if let cached = DecayCache.cache[text]?[cacheKey] {
            return cached
        }
        
        // Clean cache if too large
        if DecayCache.cache.count > DecayCache.limit {
            DecayCache.cache.removeAll()
        }
        
        if decay < 75 {
            return text
        }
        
        let decayPercentage = Double(decay) / 100.0
        var result = ""
        
        // Get current milliseconds for flickering
        let timeBasedFlicker = Int(Date().timeIntervalSince1970 * 1000) % 1000
        
        // Array of different redaction characters for flickering effect
        let redactionChars = ["█", "▓", "▒", "░", "■", "◼", "◾", "▪", "▇"]
        
        // Select primary and secondary redaction characters based on flicker phase
        let primaryRedaction = redactionChars[timeBasedFlicker % redactionChars.count]
        let secondaryRedaction = redactionChars[(timeBasedFlicker + 2) % redactionChars.count]
        
        // Determine if we're in a glitch moment (brief visual artifact)
        let glitchMoment = timeBasedFlicker % 200 < 20 // Occasional glitch
        
        if decay >= 95 {
            // Near complete decay - almost nothing is visible
            for (i, char) in text.enumerated() {
                if i % 25 == 0 || (char == " " && i % 15 == 0) {
                    // Show occasional real characters
                    result.append(char)
                } else if i % 20 == 0 {
                    // Add rare glitch char for visual interest
                    let glyphChars = ["¥", "§", "Æ", "¢", "Ø", "∆", "Ω", "π", "µ"]
                    result.append(glyphChars[(i + timeBasedFlicker) % glyphChars.count])
                } else if glitchMoment && i % 7 == 0 {
                    // During glitch moments, add digital artifacts
                    let artifacts = ["0", "1", "/", "\\", "|", "~", "_"]
                    result.append(artifacts[(i + timeBasedFlicker) % artifacts.count])
                } else {
                    // Primary or secondary redaction based on position and time
                    result.append((i + timeBasedFlicker) % 5 == 0 ? secondaryRedaction : primaryRedaction)
                }
            }
        } else if decay >= 90 {
            // Very high decay - just a few characters visible with corruption
            for (i, char) in text.enumerated() {
                if i % 15 == 0 || (char == " " && i % 5 == 0) {
                    if char.isLetter && Double.random(in: 0...1) > 0.5 {
                        // Character substitution for letters
                        let charString = String(char).lowercased()
                        if charString == "a" { result.append("4") }
                        else if charString == "e" { result.append("3") }
                        else if charString == "i" { result.append("1") }
                        else if charString == "o" { result.append("0") }
                        else if charString == "s" { result.append("5") }
                        else { result.append(char) }
                    } else {
                        result.append(char)
                    }
                } else if i % 10 == 0 {
                    // Add occasional glitch chars
                    let glitchChars = ["#", "@", "$", "%", "&", "*", "!"]
                    result.append(glitchChars[(i + timeBasedFlicker) % glitchChars.count])
                } else if glitchMoment && i % 8 == 0 {
                    // Occasionally let characters "bleed through" the redaction
                    result.append(char)
                } else {
                    // Flickering redaction characters
                    result.append((i + timeBasedFlicker) % 4 == 0 ? secondaryRedaction : primaryRedaction)
                }
            }
        } else if decay >= 85 {
            // High decay - some words partly visible with corruption
            for (i, char) in text.enumerated() {
                if i % 8 == 0 || (char == " " && i % 3 == 0) || (i % 10 == 0 && Double.random(in: 0...1) > 0.7) {
                    if char.isLetter && Double.random(in: 0...1) > 0.3 {
                        // Character substitution for letters
                        let charString = String(char).lowercased()
                        if charString == "a" { result.append("4") }
                        else if charString == "e" { result.append("3") }
                        else if charString == "i" { result.append("1") }
                        else if charString == "o" { result.append("0") }
                        else if charString == "s" { result.append("5") }
                        else { result.append(char) }
                    } else {
                        result.append(char)
                    }
                } else if Double.random(in: 0...1) > 0.9 {
                    // Mix in some glitch characters
                    let glitchChars = ["#", "@", "$", "%", "&", "*", "!"]
                    result.append(glitchChars[(i + timeBasedFlicker) % glitchChars.count])
                } else if Double.random(in: 0...1) > 0.8 {
                    // Some special symbols for visual interest
                    let specialChars = ["±", "Ω", "×", "÷", "≠"]
                    result.append(specialChars[(i + timeBasedFlicker) % specialChars.count])
                } else if glitchMoment && i % 12 == 0 {
                    // During glitch moments, briefly show actual text
                    result.append(char)
                } else {
                    // Alternating redaction characters
                    result.append((i + timeBasedFlicker) % 3 == 0 ? secondaryRedaction : primaryRedaction)
                }
            }
        } else {
            // Medium-high decay - many words partly obscured with corruption
            for (i, char) in text.enumerated() {
                if char == " " || i % 4 == 0 || Double.random(in: 0...1) > decayPercentage * 0.8 {
                    if char.isLetter && Double.random(in: 0...1) > 0.4 {
                        // Character substitution for letters
                        let charString = String(char).lowercased()
                        if charString == "a" { result.append("4") }
                        else if charString == "e" { result.append("3") }
                        else if charString == "i" { result.append("1") }
                        else if charString == "o" { result.append("0") }
                        else if charString == "s" { result.append("5") }
                        else { result.append(char) }
                    } else {
                        result.append(char)
                    }
                } else if Double.random(in: 0...1) > 0.85 {
                    let simpleGlitchChars = ["#", "@", "$"]
                    result.append(simpleGlitchChars[(i + timeBasedFlicker) % simpleGlitchChars.count])
                } else if glitchMoment && i % 6 == 0 {
                    // During glitch moments, show original text  
                    result.append(char)
                } else {
                    // Use a mix of redaction characters
                    let redactionIndex = (i + timeBasedFlicker) % redactionChars.count
                    result.append(redactionChars[redactionIndex])
                }
            }
        }
        
        // Cache the result
        if DecayCache.cache[text] == nil {
            DecayCache.cache[text] = [:]
        }
        DecayCache.cache[text]?[cacheKey] = result
        
        return result
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    // Helper to provide a pseudo-random offset for text jitter
    private func textChaosOffset() -> CGFloat {
        // Use a deterministic but random-looking approach to avoid expensive calculations
        let base = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 10)
        return CGFloat(sin(base)) * 2.0
    }
}

class CardViewModel: ObservableObject {
    @Published var store: JournalEntryStore?
    
    func initializeStore() {
        if store == nil {
            store = JournalEntryStore()
        }
    }
}

// Special button style for cards with haptic feedback
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    HapticFeedback.light()
                }
            }
    }
} 