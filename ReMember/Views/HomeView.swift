import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showingNewEntryView = false
    @State private var selectedEntry: JournalEntry?
    @State private var refreshTrigger = false // For forced refreshes - keeping for compatibility
    @State private var bootupComplete = false
    @State private var bootProgress = 0.0
    @State private var showingDeleteConfirmation = false
    @State private var entryToDelete: UUID?
    
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
                    
                    // Add tag filtering section if there are tags
                    if !viewModel.availableTags.isEmpty {
                        TagsContainerView(viewModel: viewModel)
                    }
                    
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
                        // Entries list - using List for proper swipe action support
                        List {
                                ForEach(viewModel.filteredEntries) { entry in
                                ZStack {
                                    GlitchedEntryCard(entry: entry)
                                }
                                .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedEntry = entry
                                        }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .frame(height: entry.tags.isEmpty ? 140 : 160)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        entryToDelete = entry.id
                                        showingDeleteConfirmation = true
                                        HapticFeedback.light()
                                    } label: {
                                        Label("DELETE", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .background(GlitchTheme.background)
                        .scrollContentBackground(.hidden)
                        .environment(\.defaultMinListRowHeight, 0)
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
                EntryEditView(store: viewModel.store, entry: nil)
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
            .confirmationDialog(
                "DELETE MEMORY FRAGMENT?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("REMOVE FROM SYSTEM", role: .destructive) {
                    if let id = entryToDelete {
                        withAnimation(.easeInOut) {
                            // Apply glitch effect first
                            viewModel.deleteEntry(id: id)
                            
                            // Apply haptic feedback for deletion action
                            HapticFeedback.medium()
                        }
                    }
                }
                
                Button("CANCEL", role: .cancel) {}
            } message: {
                Text("THIS ACTION CANNOT BE UNDONE.")
            }
            .onChange(of: showingDeleteConfirmation) { isShowing in
                if !isShowing && entryToDelete != nil {
                    // Reset the entry to delete when dialog is dismissed
                    entryToDelete = nil
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.toggleDecayTimeline()
                    }) {
                        Label("Memory Decay", systemImage: "chart.bar.fill")
                    }
                }
            }
        }
        .overlay(
            Group {
                if viewModel.showingDecayTimeline {
                    DecayTimelineView(viewModel: viewModel)
                        .transition(.move(edge: .bottom))
                }
            }
            .animation(.spring(), value: viewModel.showingDecayTimeline)
        )
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
            .padding(.top, 60) // Added extra top padding to account for the notch
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
    @State private var isDeleting = false
    
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
            if entry.decayLevel > 30 {
                // Use GlitchedText for higher decay levels to show decay effects
                GlitchedText(text: entry.content.count > 100 ? String(entry.content.prefix(100)) + "..." : entry.content, 
                             decayLevel: entry.decayLevel, 
                             size: 14)
                    .lineLimit(3)
                    .frame(height: 60, alignment: .top)
                    .glitchBlocks(intensity: Double(entry.decayLevel) / 200)
            } else {
                // Use regular text for lower decay levels
                Text(entry.content.count > 100 ? String(entry.content.prefix(100)) + "..." : entry.content)
                    .font(GlitchTheme.pixelFont(size: 14))
                    .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                    .opacity(TextDecayEffect.opacityEffect(for: entry.decayLevel))
                    .blur(radius: TextDecayEffect.blurEffect(for: entry.decayLevel) * 0.5)
                    .lineLimit(3)
                    .frame(height: 60, alignment: .top)
            }
            
            // Info row - fixed height
            HStack {
                Text("CREATED: \(formattedDate(entry.creationDate))")
                    .font(GlitchTheme.pixelFont(size: 10))
                    .foregroundColor(GlitchTheme.glitchYellow)
                
                Spacer()
                
                // Show indicator for photo attachments
                if !entry.photoAttachments.isEmpty {
                    let decayFactor = min(max(Double(entry.decayLevel), 0), 100) / 100.0
                    
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 10))
                            .foregroundColor(
                                entry.decayLevel > 50 ? 
                                Color.red.opacity(0.8) : 
                                GlitchTheme.glitchCyan.opacity(0.8)
                            )
                            // Apply decay effects to the photo icon
                            .opacity(max(1.0 - (decayFactor * 0.5), 0.5))
                            .blur(radius: decayFactor > 0.5 ? min(decayFactor * 1.5, 1.5) : 0)
                            .digitalNoise(intensity: min(decayFactor * 0.5, 0.5))
                        
                        Text("\(entry.photoAttachments.count)")
                            .font(GlitchTheme.pixelFont(size: 10))
                            .foregroundColor(
                                entry.decayLevel > 50 ? 
                                Color.red.opacity(0.7) : 
                                GlitchTheme.glitchCyan
                            )
                            // Apply text decay effects
                            .opacity(TextDecayEffect.opacityEffect(for: entry.decayLevel))
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(GlitchTheme.fieldBackground.opacity(0.3))
                    .cornerRadius(4)
                    
                    Spacer().frame(width: 8)
                }
                
                if let restored = entry.lastRestoredDate {
                    Text("RESTORED: \(formattedDate(restored))")
                        .font(GlitchTheme.pixelFont(size: 10))
                        .foregroundColor(GlitchTheme.glitchCyan)
                }
            }
            .frame(height: 20)
            
            // Tags row - fixed height
            if !entry.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(entry.tags.prefix(3)), id: \.self) { tag in
                        Text(tag)
                            .font(GlitchTheme.pixelFont(size: 9))
                            .foregroundColor(GlitchTheme.glitchCyan.opacity(0.8))
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(GlitchTheme.fieldBackground.opacity(0.7))
                            .cornerRadius(2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(GlitchTheme.glitchCyan.opacity(0.4), lineWidth: 0.5)
                            )
                    }
                    
                    if entry.tags.count > 3 {
                        Text("+\(entry.tags.count - 3)")
                            .font(GlitchTheme.pixelFont(size: 9))
                            .foregroundColor(GlitchTheme.glitchYellow)
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
                .frame(height: 20)
            }
        }
        .padding(10)
        .background(GlitchTheme.cardBackground)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(GlitchTheme.colorForDecayLevel(entry.decayLevel).opacity(0.3), lineWidth: 1)
        )
        .opacity(isDeleting ? 0.0 : 1.0)
        .rgbSplit(amount: isDeleting ? 6.0 : min(CGFloat(entry.decayLevel) / 100, 2.0), angle: 90)
        .digitalNoise(intensity: min(Double(entry.decayLevel) / 200, 0.2))
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yy HH:mm"
        return formatter.string(from: date)
    }
    
    func triggerDeleteAnimation() {
        withAnimation(.easeInOut(duration: 0.8)) {
            isDeleting = true
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
} 