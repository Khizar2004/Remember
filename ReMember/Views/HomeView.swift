import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showingNewEntryView = false
    @State private var selectedEntry: JournalEntry?
    @State private var refreshTrigger = false // For forced refreshes - keeping for compatibility
    @State private var bootupComplete = false
    @State private var bootProgress = 0.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                GlitchTheme.background.ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Fixed header section - total height is constant
                    VStack(spacing: 0) {
                        // App title and status
                        HStack {
                            Text("RE:MEMBER")
                                .font(GlitchTheme.terminalFont(size: 28))
                                .foregroundColor(GlitchTheme.terminalGreen)
                                .fixedSize()
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(GlitchTheme.glitchCyan)
                                    .frame(width: 8, height: 8)
                                
                                Text("SYS:ACTIVE")
                                    .font(GlitchTheme.terminalFont(size: 12))
                                    .foregroundColor(GlitchTheme.glitchCyan)
                                    .fixedSize()
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 16)
                        .frame(height: 44) // Fixed height
                        
                        // Search field - fixed height
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(GlitchTheme.fieldBackground)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(GlitchTheme.glitchCyan.opacity(0.5), lineWidth: 1)
                                )
                            
                            HStack(spacing: 2) {
                                Text(">")
                                    .font(GlitchTheme.terminalFont(size: 16))
                                    .foregroundColor(GlitchTheme.terminalGreen)
                                    .frame(width: 20, alignment: .center)
                                    .padding(.leading, 8)
                                
                                TextField("", text: $viewModel.searchText)
                                    .font(GlitchTheme.terminalFont(size: 16))
                                    .foregroundColor(GlitchTheme.terminalGreen)
                                    .accentColor(GlitchTheme.glitchCyan)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .placeholder(when: viewModel.searchText.isEmpty) {
                                        Text("SEARCH MEMORY DATABASE")
                                            .font(GlitchTheme.terminalFont(size: 16))
                                            .foregroundColor(GlitchTheme.terminalGreen.opacity(0.6))
                                    }
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.refreshEntries()
                                    DispatchQueue.main.async {
                                        HapticFeedback.light()
                                    }
                                }) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundColor(GlitchTheme.glitchCyan)
                                        .frame(width: 24, height: 24)
                                        .contentShape(Rectangle())
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        .frame(height: 44) // Fixed height
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Status bar - fixed height
                        HStack {
                            Text("MEMORY FRAGMENTS: \(viewModel.store.entries.count)")
                                .font(GlitchTheme.terminalFont(size: 12))
                                .foregroundColor(GlitchTheme.glitchCyan)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            Text(formatDate(Date()))
                                .font(GlitchTheme.terminalFont(size: 10))
                                .foregroundColor(GlitchTheme.glitchYellow)
                                .fixedSize()
                        }
                        .frame(height: 20) // Fixed height
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    }
                    .background(Color.black.opacity(0.2)) // Subtle background for header section
                    .frame(height: 132) // Fixed total height (44 + 44 + 20 + padding)
                    
                    // Content area
                    if viewModel.filteredEntries.isEmpty {
                        Spacer()
                        VStack(spacing: 30) {
                            Image(systemName: "externaldrive.badge.xmark")
                                .font(.system(size: 40))
                                .foregroundColor(GlitchTheme.glitchCyan)
                            
                            Text("NO MEMORY FRAGMENTS DETECTED")
                                .font(GlitchTheme.terminalFont(size: 18))
                                .foregroundColor(GlitchTheme.glitchYellow)
                                .padding()
                                .frame(height: 30)
                            
                            Button(action: {
                                showingNewEntryView = true
                            }) {
                                Text("CREATE NEW MEMORY FRAGMENT")
                                    .font(GlitchTheme.terminalFont(size: 16))
                                    .foregroundColor(GlitchTheme.background)
                                    .padding()
                                    .background(GlitchTheme.glitchCyan)
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(GlitchTheme.terminalGreen, lineWidth: 1)
                                    )
                            }
                        }
                        Spacer()
                    } else {
                        // Entries list - without GeometryReader to prevent layout instability
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredEntries) { entry in
                                    GlitchedEntryCard(entry: entry)
                                        .onTapGesture { 
                                            selectedEntry = entry 
                                        }
                                        .frame(height: 140)
                                        .padding(.horizontal, 16) // Apply horizontal padding here
                                }
                            }
                            .padding(.vertical, 4) // Add slight vertical padding
                        }
                        .frame(maxHeight: .infinity) // Take remaining space
                    }
                }
                
                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingNewEntryView = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(GlitchTheme.glitchCyan)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(GlitchTheme.background)
                            }
                            .contentShape(Circle())
                        }
                        .shadow(color: GlitchTheme.glitchCyan.opacity(0.6), radius: 8, x: 0, y: 4)
                        .padding([.bottom, .trailing], 30)
                    }
                }
                
                // Boot sequence overlay
                if !bootupComplete {
                    BootSequenceView(progress: $bootProgress, complete: $bootupComplete)
                        .ignoresSafeArea()
                }
            }
            .crtEffect(intensity: 0.3)  // Reduced intensity
            .navigationBarHidden(true)
            .onAppear {
                // Initial boot sequence
                if !bootupComplete {
                    startBootSequence()
                    
                    // Fallback completion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                        if !bootupComplete {
                            print("Forcing boot completion")
                            bootupComplete = true
                            viewModel.refreshEntries()
                        }
                    }
                } else {
                    viewModel.refreshEntries()
                }
            }
            .sheet(isPresented: $showingNewEntryView, onDismiss: {
                // Refresh the entries list when returning from the new entry view
                viewModel.refreshEntries()
                DispatchQueue.main.async {
                    HapticFeedback.light()
                }
            }) {
                EntryEditView(store: viewModel.store)
            }
            .sheet(item: $selectedEntry, onDismiss: {
                // Refresh the entries list when returning from the detail view
                viewModel.refreshEntries()
                DispatchQueue.main.async {
                    HapticFeedback.light()
                }
            }) { entry in
                EntryDetailView(store: viewModel.store, entry: entry)
            }
        }
    }
    
    // Simulate system boot sequence
    private func startBootSequence() {
        // Reset boot progress
        bootProgress = 0.0
        
        // Use a more reliable approach with a strong reference and proper cancellation
        var progressTimer: Timer?
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation {
                if self.bootProgress < 1.0 {
                    self.bootProgress += 0.01
                } else {
                    timer.invalidate()
                    progressTimer = nil
                    self.bootupComplete = true
                    self.viewModel.refreshEntries()
                }
            }
        }
    }
    
    // Format date for system time display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // Cancel all running timers and animations 
    private func cancelAllAnimations() {
        // Reset animation-related flags in UserDefaults
        UserDefaults.standard.removeObject(forKey: "cursorBlinkActive")
        
        // Force any SwiftUI animations to complete
        withAnimation(.linear(duration: 0.1)) {
            // Update any state that might be animating
            refreshTrigger.toggle()
        }
        
        // Kill any potential running timers
        NotificationCenter.default.post(name: NSNotification.Name("CancelAllAnimationsNotification"), object: nil)
    }
}

// Boot sequence overlay
struct BootSequenceView: View {
    @Binding var progress: Double
    @Binding var complete: Bool
    @State private var showCommandLine = false
    @State private var commandText = ""
    @State private var bootTextLines: [String] = []
    @State private var cursorVisible = true
    @State private var bootPhase = 0
    
    private let bootTexts = [
        "INITIALIZING CORE MEMORY SYSTEMS...",
        "CONNECTING TO NEURAL DATABASE...",
        "LOADING MEMORY FRAGMENTS...",
        "CALIBRATING DECAY ALGORITHMS...",
        "CHECKING DATA INTEGRITY...",
        "ESTABLISHING SYS_REMEMBER PROTOCOLS...",
        "VERIFYING CORE MEMORY ARCHIVE...",
        "SYSTEM READY..."
    ]
    
    var body: some View {
        ZStack {
            GlitchTheme.background.opacity(0.98)
            
            VStack(alignment: .leading, spacing: 8) {
                
                // Terminal boot text
                ForEach(bootTextLines, id: \.self) { line in
                    Text(line)
                        .font(GlitchTheme.terminalFont(size: 14))
                        .foregroundColor(GlitchTheme.terminalGreen)
                        .digitalNoise(intensity: 0.2)
                }
                
                // Command line with blinking cursor
                if showCommandLine {
                    HStack(spacing: 0) {
                        Text(">")
                            .font(GlitchTheme.terminalFont(size: 16))
                            .foregroundColor(GlitchTheme.glitchCyan)
                        
                        Text(" " + commandText)
                            .font(GlitchTheme.terminalFont(size: 16))
                            .foregroundColor(GlitchTheme.terminalGreen)
                        
                        // Blinking cursor
                        if cursorVisible {
                            Rectangle()
                                .fill(GlitchTheme.terminalGreen)
                                .frame(width: 10, height: 16)
                                .opacity(0.7)
                        }
                    }
                }
                
                // Boot progress bar
                if progress < 1.0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LOADING SYSTEM: \(Int(progress * 100))%")
                            .font(GlitchTheme.terminalFont(size: 12))
                            .foregroundColor(GlitchTheme.glitchCyan)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 8)
                                    .foregroundColor(GlitchTheme.cardBackground)
                                
                                Rectangle()
                                    .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                                    .foregroundColor(GlitchTheme.glitchCyan)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.top, 20)
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .digitalNoise(intensity: 0.3)
            .rgbSplit(amount: 2, angle: 0)
        }
        .screenFlicker(intensity: 0.2)
        .onAppear {
            // Start the boot sequence
            startBootSequence()
            
            // Fallback timer to ensure boot always completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if !complete {
                    print("Boot sequence fallback triggered")
                    complete = true
                }
            }
        }
    }
    
    private func startBootSequence() {
        // Add boot texts with delays
        var delay = 0.0
        
        for (index, text) in bootTexts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                bootTextLines.append(text)
                
                // For the last line, show command line
                if index == bootTexts.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCommandLine = true
                        startCursorBlink()
                        startTypingCommand()
                    }
                }
            }
            
            delay += 0.3 // time between text lines
        }
    }
    
    private func startCursorBlink() {
        // Create blinking cursor effect with a stored timer
        var blinkTimer: Timer?
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation {
                self.cursorVisible.toggle()
            }
        }
        
        // Store the timer in a user default to prevent optimization
        UserDefaults.standard.set(true, forKey: "cursorBlinkActive")
    }
    
    private func startTypingCommand() {
        let finalCommand = "run memory_system --initialized --verify"
        var currentIndex = 0
        
        var typingTimer: Timer?
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if currentIndex < finalCommand.count {
                let index = finalCommand.index(finalCommand.startIndex, offsetBy: currentIndex)
                self.commandText += String(finalCommand[index])
                currentIndex += 1
            } else {
                timer.invalidate()
                typingTimer = nil
                
                // Ensure completion happens after typing finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.bootPhase = self.bootTexts.count
                        self.complete = true
                    }
                }
            }
        }
    }
}

// Enhanced glitched entry card with fixed dimensions
struct GlitchedEntryCard: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title row - fixed height
            HStack {
                Text(entry.title)
                    .font(GlitchTheme.terminalFont(size: 18))
                    .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                    .lineLimit(1)
                    .frame(height: 24)
                
                Spacer()
                
                // Decay indicator
                Circle()
                    .fill(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                    .frame(width: 12, height: 12)
            }
            .frame(height: 30)
            
            // Content preview - fixed height
            Text(entry.content.count > 100 ? String(entry.content.prefix(100)) + "..." : entry.content)
                .font(GlitchTheme.pixelFont(size: 14))
                .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                .opacity(TextDecayEffect.opacityEffect(for: entry.decayLevel))
                .lineLimit(3)
                .frame(height: 70, alignment: .top)
            
            // Info row - fixed height
            HStack {
                Text("CREATED: \(formattedDate(entry.creationDate))")
                    .font(GlitchTheme.pixelFont(size: 10))
                    .foregroundColor(GlitchTheme.glitchYellow)
                
                Spacer()
                
                if let restored = entry.lastRestoredDate {
                    Text("RESTORED: \(formattedDate(restored))")
                        .font(GlitchTheme.pixelFont(size: 10))
                        .foregroundColor(GlitchTheme.glitchCyan)
                }
            }
            .frame(height: 20)
        }
        .padding(10)
        .background(GlitchTheme.cardBackground)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(GlitchTheme.colorForDecayLevel(entry.decayLevel).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yy HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
} 