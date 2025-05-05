import SwiftUI
import Combine

struct EntryDetailView: View {
    @StateObject private var viewModel: EntryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditView = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var glitchIntensity = 0.0
    @State private var showingEditWarning = false
    @State private var flickerPhase = UUID()
    @State private var flickerTimer: Timer? = nil
    @GestureState private var isPressed = false
    
    // Define decay threshold beyond which editing is disallowed
    private let editDecayThreshold = 70
    
    init(store: JournalEntryStore, entry: JournalEntry) {
        _viewModel = StateObject(wrappedValue: EntryViewModel(store: store, entry: entry))
    }
    
    var body: some View {
        ZStack {
            GlitchTheme.background.edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(GlitchTheme.terminalGreen)
                            
                            Text("SYSTEM")
                                .font(GlitchTheme.terminalFont(size: 12))
                                .foregroundColor(GlitchTheme.terminalGreen)
                        }
                        .padding(8)
                        .background(GlitchTheme.fieldBackground)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(GlitchTheme.terminalGreen.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                    if let entry = viewModel.entry {
                        Text("FRAGMENT #\(entry.id.uuidString.prefix(8))")
                            .font(GlitchTheme.terminalFont(size: 12))
                            .foregroundColor(GlitchTheme.glitchYellow)
                            .screenFlicker(intensity: 0.2)
                    }
                    
                    Spacer()
                    Button(action: {
                        if let entry = viewModel.entry, entry.decayLevel > editDecayThreshold {
                            // Show warning for heavily decayed memories
                            showingEditWarning = true
                        } else {
                            // Allow editing for less decayed memories
                            showingEditView = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(GlitchTheme.glitchCyan)
                            
                            Text("EDIT")
                                .font(GlitchTheme.terminalFont(size: 12))
                                .foregroundColor(GlitchTheme.glitchCyan)
                        }
                        .padding(8)
                        .background(GlitchTheme.fieldBackground)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(GlitchTheme.glitchCyan.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let entry = viewModel.entry {
                            HStack {
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                        .frame(width: 8, height: 8)
                                        .screenFlicker(intensity: Double(entry.decayLevel) / 100.0)
                                    
                                    Text("MEMORY STABILITY:")
                                        .font(GlitchTheme.terminalFont(size: 12))
                                        .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                        .fixedSize(horizontal: true, vertical: false)
                                        .lineLimit(1)
                                        .id("stabilityLabel")
                                    
                                    Text("\(100 - entry.decayLevel)%")
                                        .font(GlitchTheme.terminalFont(size: 16).bold())
                                        .foregroundColor(.yellow)
                                        .padding(.horizontal, 4)
                                        .background(Color.black.opacity(0.8))
                                        .cornerRadius(4)
                                        .id("stabilityValue")
                                        .fixedSize(horizontal: true, vertical: false)
                                        .shadow(color: .yellow, radius: 1)
                                }
                                
                                Spacer()
                                
                                Text("SYS.DECRYPT STATUS: \(entry.decayLevel > 50 ? "DEGRADED" : "NOMINAL")")
                                    .font(GlitchTheme.terminalFont(size: 9))
                                    .foregroundColor(entry.decayLevel > 50 ? GlitchTheme.glitchRed : GlitchTheme.glitchCyan)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .lineLimit(1)
                                    .id("decryptStatus")
                            }
                            .padding(.vertical, 5)
                            .frame(height: 30) // Fixed height to prevent bouncing
                            .id("statusHeader") // Stable ID for layout
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ENTRY DESIGNATION:")
                                    .font(GlitchTheme.terminalFont(size: 12))
                                    .foregroundColor(GlitchTheme.glitchYellow.opacity(0.7))
                                
                                if entry.decayLevel >= 75 {
                                    Text(obscureTextByDecay(entry.title, decay: entry.decayLevel))
                                        .font(GlitchTheme.pixelFont(size: 26))
                                        .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                        .padding(.bottom, 10)
                                        .blur(radius: min(Double(entry.decayLevel) / 200, 0.5))
                                        .offset(x: entry.decayLevel > 90 ? entryChaosOffset() * 0.8 : 0)
                                        .rgbSplit(amount: entry.decayLevel > 90 ? min(CGFloat(entry.decayLevel) / 60, 1.5) : 0, angle: 90)
                                } else {
                                    Text(entry.title)
                                        .font(GlitchTheme.pixelFont(size: 26))
                                        .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                        .padding(.bottom, 10)
                                }
                            }
                            .padding(.vertical, 5)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Text("TIMESTAMP:")
                                        .font(GlitchTheme.terminalFont(size: 12))
                                        .foregroundColor(GlitchTheme.glitchYellow.opacity(0.7))
                                    
                                    Text(formattedDate(entry.creationDate))
                                        .font(GlitchTheme.terminalFont(size: 12))
                                        .foregroundColor(GlitchTheme.terminalGreen)
                                }
                                
                                if let restored = entry.lastRestoredDate {
                                    HStack(spacing: 8) {
                                        Text("DEFRAGMENTED:")
                                            .font(GlitchTheme.terminalFont(size: 12))
                                            .foregroundColor(GlitchTheme.glitchYellow.opacity(0.7))
                                        
                                        Text(formattedDate(restored))
                                            .font(GlitchTheme.terminalFont(size: 12))
                                            .foregroundColor(GlitchTheme.glitchCyan)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                            
                            Rectangle()
                                .fill(GlitchTheme.colorForDecayLevel(entry.decayLevel).opacity(0.3))
                                .frame(height: 1)
                                .padding(.vertical, 10)
                            
                            HStack(spacing: 2) {
                                ForEach(0..<min(20, entry.content.count/20), id: \.self) { index in
                                    let dataDecay = min(entry.decayLevel + Int.random(in: -10...10), 100)
                                    Rectangle()
                                        .fill(GlitchTheme.colorForDecayLevel(dataDecay))
                                        .frame(width: 3, height: 30)
                                        .opacity(TextDecayEffect.opacityEffect(for: dataDecay))
                                }
                            }
                            .padding(.bottom, 10)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("MEMORY CONTENT:")
                                    .font(GlitchTheme.terminalFont(size: 12))
                                    .foregroundColor(GlitchTheme.glitchYellow.opacity(0.7))
                                
                                if entry.decayLevel >= 75 {
                                    Text(obscureTextByDecay(entry.content, decay: entry.decayLevel))
                                        .font(GlitchTheme.pixelFont(size: 16))
                                        .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                        .lineSpacing(6)
                                        .blur(radius: min(Double(entry.decayLevel) / 100, 0.8))
                                        .offset(x: entry.decayLevel > 85 ? entryChaosOffset() : 0)
                                        .rgbSplit(amount: entry.decayLevel > 85 ? min(CGFloat(entry.decayLevel) / 50, 1.8) : 0, angle: 90)
                                        .digitalNoise(intensity: min(Double(entry.decayLevel) / 200, 0.4))
                                } else {
                                    GlitchedText(text: entry.content, decayLevel: entry.decayLevel, size: 16, isListView: false)
                                        .lineSpacing(6)
                                        .glitchBlocks(intensity: Double(entry.decayLevel) / 200)
                                }
                            }
                            
                            if let entry = viewModel.entry, !entry.photoAttachments.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("MEMORY FRAGMENTS")
                                        .font(.system(.headline, design: .monospaced))
                                        .foregroundColor(.cyan)
                                        .shadow(color: .cyan.opacity(0.8), radius: 2, x: 0, y: 0)
                                        .padding(.top, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHGrid(rows: [GridItem(.flexible())], spacing: 10) {
                                            ForEach(Array(entry.photoAttachments.keys), id: \.self) { photoID in
                                                if let photoURL = entry.photoAttachments[photoID] {
                                                    SavedPhotoView(photoURL: photoURL, decayLevel: entry.decayLevel)
                                                }
                                            }
                                        }
                                        .frame(height: 150)
                                        .padding(.horizontal)
                                    }
                                }
                                .id(entry.photoAttachments.count)
                            }
                            
                            if !entry.tags.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("MEMORY CLASSIFICATION:")
                                        .font(GlitchTheme.terminalFont(size: 12))
                                        .foregroundColor(GlitchTheme.glitchYellow.opacity(0.7))
                                        .padding(.top, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(entry.tags, id: \.self) { tag in
                                                Text(tag)
                                                    .font(GlitchTheme.pixelFont(size: 12))
                                                    .foregroundColor(GlitchTheme.glitchCyan)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(GlitchTheme.cardBackground)
                                                    .cornerRadius(4)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .stroke(GlitchTheme.glitchCyan.opacity(0.6), lineWidth: 1)
                                                    )
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                    .id("contentTop")
                }
                .overlay(
                    Group {
                        if viewModel.showRestoreAnimation {
                            EnhancedRestorationView(progress: viewModel.restorationProgress)
                        }
                    }
                )
                
                Spacer()
                
                if let entry = viewModel.entry, entry.decayLevel > 10 {
                    if entry.decayLevel >= 50 {
                        Button(action: {
                            if entry.hasProtectionQuestions {
                                viewModel.startMemoryChallenge()
                            } else {
                                viewModel.initiateRestoration()
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    glitchIntensity = 3.0
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        glitchIntensity = 0.0
                                    }
                                }
                            }
                        }) {
                            VStack(spacing: 4) {
                                HStack {
                                    Spacer()
                                    Text(entry.hasProtectionQuestions ? "RECOVER MEMORY" : "RESTORE MEMORY")
                                        .font(GlitchTheme.terminalFont(size: 16))
                                        .foregroundColor(GlitchTheme.background)
                                    Spacer()
                                }
                                
                                Text("[SYS.RECONSTRUCT.SEQUENCE]")
                                    .font(GlitchTheme.terminalFont(size: 10))
                                    .foregroundColor(GlitchTheme.background.opacity(0.7))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(GlitchTheme.glitchCyan)
                            .cornerRadius(6)
                            .shadow(color: GlitchTheme.glitchCyan.opacity(0.5), radius: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(GlitchTheme.terminalGreen, lineWidth: 1)
                            )
                            .digitalNoise(intensity: 0.2)
                        }
                    } else {
                        Button(action: {
                            viewModel.initiateRestoration()
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                glitchIntensity = 3.0
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    glitchIntensity = 0.0
                                }
                            }
                        }) {
                            VStack(spacing: 4) {
                                HStack {
                                    Spacer()
                                    Text("DEFRAGMENT MEMORY")
                                        .font(GlitchTheme.terminalFont(size: 16))
                                        .foregroundColor(GlitchTheme.background)
                                    Spacer()
                                }
                                
                                Text("[SYS.RECONSTRUCT.SEQUENCE]")
                                    .font(GlitchTheme.terminalFont(size: 10))
                                    .foregroundColor(GlitchTheme.background.opacity(0.7))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(GlitchTheme.glitchYellow)
                            .cornerRadius(6)
                            .shadow(color: GlitchTheme.glitchYellow.opacity(0.5), radius: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(GlitchTheme.terminalGreen, lineWidth: 1)
                            )
                            .digitalNoise(intensity: 0.2)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Color.black.opacity(0.03)
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .screenFlicker(intensity: 0.2)
            
            if let entry = viewModel.entry, entry.decayLevel > 60 || glitchIntensity > 0 {
                Color.clear
                    .allowsHitTesting(false)
                    .rgbSplit(amount: max(CGFloat(entry.decayLevel) / 50, CGFloat(glitchIntensity)), angle: 0)
                    .ignoresSafeArea()
                    .compositingGroup()
                    .blendMode(.screen)
            }
            
            if showingEditWarning {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // Optional: allow dismissing by tapping outside
                        // showingEditWarning = false
                    }
                
                VStack(spacing: 20) {
                    Text("MEMORY CORRUPTION CRITICAL")
                        .font(GlitchTheme.terminalFont(size: 22))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    Text("Memory fragment too degraded for modification. Stability below acceptable parameters.\n\nRestore memory to regain edit access.")
                        .font(GlitchTheme.terminalFont(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            showingEditWarning = false
                            
                            if let entry = viewModel.entry {
                                if entry.decayLevel >= 50 && entry.hasProtectionQuestions {
                                    viewModel.startMemoryChallenge()
                                } else {
                                    viewModel.initiateRestoration()
                                    
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        glitchIntensity = 3.0
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            glitchIntensity = 0.0
                                        }
                                    }
                                }
                            }
                        }) {
                            Text("RESTORE")
                                .font(GlitchTheme.terminalFont(size: 18).bold())
                                .foregroundColor(GlitchTheme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(GlitchTheme.glitchCyan)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            showingEditWarning = false
                        }) {
                            Text("UNDERSTOOD")
                                .font(GlitchTheme.terminalFont(size: 18))
                                .foregroundColor(GlitchTheme.glitchCyan)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(GlitchTheme.glitchCyan, lineWidth: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 10)
                    .frame(width: 280) // Fixed width for buttons
                }
                .padding(24)
                .background(Color.black.opacity(0.9))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(GlitchTheme.glitchRed, lineWidth: 2)
                )
                .frame(maxWidth: 320)
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .crtEffect(intensity: 1.0)
        .background(GlitchTheme.background.edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(true)
        .toolbar { /* ... existing toolbar content ... */ }
        .sheet(isPresented: $showingEditView, onDismiss: {
            // Force reload the entry from the store after editing
            if let entryId = viewModel.entry?.id {
                // Find and update with the fresh entry from the store
                if let index = viewModel.viewModelStore.entries.firstIndex(where: { $0.id == entryId }) {
                    // Get updated entry from the store
                    let updatedEntry = viewModel.viewModelStore.entries[index]
                    
                    // Replace our viewModel with a fresh one containing the updated entry
                    DispatchQueue.main.async {
                        viewModel.entry = updatedEntry
                        viewModel.objectWillChange.send()
                    }
                }
            }
        }) {
            if let entry = viewModel.entry {
                EntryEditView(store: viewModel.viewModelStore, entry: entry)
            }
        }
        .id(viewModel.entry?.id.uuidString ?? "no-entry")
        .sheet(isPresented: $viewModel.showingMemoryChallenge) {
            if let entry = viewModel.entry {
                let challenge = MemoryChallenge(entry: entry) { success in
                    if success {
                        // Successfully restored the memory
                        viewModel.restoreMemory()
                        HapticFeedback.success()
                    }
                }
                MemoryChallengeView(challenge: challenge)
            }
        }
        .onAppear {
            // Start flicker timer with higher priority and frequency
            self.flickerTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                // Always update the flicker phase regardless of interaction state
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
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter.string(from: date)
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
    
    // Helper to provide a pseudo-random offset for text jitter
    private func entryChaosOffset() -> CGFloat {
        // Use a deterministic but random-looking approach to avoid expensive calculations
        let base = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 10)
        return CGFloat(sin(base)) * 2.0
    }
}

struct SavedPhotoView: View {
    let photoURL: URL
    @State private var image: UIImage? = nil
    @State private var isPresented = false
    @State private var loadAttempted = false
    var decayLevel: Int = 0
    
    var body: some View {
        // Calculate safe decay factor
        let decayFactor = min(max(Double(decayLevel), 0), 100) / 100.0
        
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    // Apply stronger decay effects to thumbnails
                    .opacity(max(1.0 - (decayFactor * 0.5), 0.5)) // More aggressive opacity reduction
                    .blur(radius: decayFactor > 0.5 ? min(decayFactor * 3.0, 3.0) : 0) // Stronger blur for high decay
                    .contrast(max(1.0 - (decayFactor * 0.6), 0.4)) // More aggressive contrast reduction
                    .saturation(max(1.0 - (decayFactor * 0.7), 0.3)) // Reduced saturation at high decay
                    .rgbSplit(amount: decayFactor > 0.3 ? min(CGFloat(decayFactor * 6), 6) : 0, angle: 90) // Stronger RGB split
                    .digitalNoise(intensity: min(decayFactor * 0.7, 0.7)) // Stronger noise
                    // Add visual corruption elements for high decay
                    .overlay(
                        Group {
                            if decayFactor > 0.6 {
                                ZStack {
                                    // Scan lines for moderate corruption
                                    VStack(spacing: 3) {
                                        ForEach(0..<10, id: \.self) { _ in
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    
                                    // Random glitch rectangles for high corruption
                                    if decayFactor > 0.8 {
                                        ForEach(0..<Int(decayFactor * 5), id: \.self) { _ in
                                            Rectangle()
                                                .fill(Color.cyan.opacity(0.2))
                                                .frame(
                                                    width: CGFloat.random(in: 10...50),
                                                    height: CGFloat.random(in: 3...15)
                                                )
                                                .offset(
                                                    x: CGFloat.random(in: -60...60),
                                                    y: CGFloat.random(in: -75...75)
                                                )
                                                .blendMode(.difference)
                                        }
                                    }
                                }
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(
                                decayLevel > 50 ? Color.red.opacity(0.8) : GlitchTheme.colorForDecayLevel(decayLevel).opacity(0.8), 
                                lineWidth: 2
                            )
                    )
                    .shadow(color: GlitchTheme.colorForDecayLevel(decayLevel).opacity(0.5), radius: 3, x: 0, y: 0)
                    // Apply additional glitch effects for severe corruption
                    .modifier(GlitchTheme.NoiseModifier(intensity: min(decayFactor * 0.5, 0.5)))
                    .onTapGesture {
                        isPresented = true
                    }
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 120, height: 150)
                    .overlay(
                        ProgressView()
                            .tint(.cyan)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(GlitchTheme.colorForDecayLevel(decayLevel).opacity(0.8), lineWidth: 2)
                    )
            }
        }
        .id(photoURL.lastPathComponent)
        .onAppear {
            loadImage()
        }
        .onChange(of: photoURL) { _ in
            loadImage()
        }
        .fullScreenCover(isPresented: $isPresented) {
            PhotoDetailView(photoURL: photoURL, isPresented: $isPresented, decayLevel: decayLevel)
        }
    }
    
    private func loadImage() {
        if image != nil || loadAttempted {
            return
        }
        
        loadAttempted = true
        
        do {
            let imageData = try Data(contentsOf: photoURL)
            
            DispatchQueue.main.async {
                self.image = UIImage(data: imageData)
            }
        } catch {
            // Handle error silently
        }
    }
}

#Preview {
    EntryDetailView(store: JournalEntryStore(), entry: JournalEntry(title: "Test Memory", content: "This is a test memory fragment with some content that will display in the detail view.", decayLevel: 40))
} 