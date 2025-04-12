import SwiftUI
import Combine

struct EntryDetailView: View {
    @StateObject private var viewModel: EntryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditView = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var glitchIntensity = 0.0
    
    init(store: JournalEntryStore, entry: JournalEntry) {
        _viewModel = StateObject(wrappedValue: EntryViewModel(store: store, entry: entry))
    }
    
    var body: some View {
        ZStack {
            // Deep background
            GlitchTheme.background.edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(alignment: .leading, spacing: 20) {
                // Terminal-style header
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
                    
                    // Memory fragment ID
                    if let entry = viewModel.entry {
                        Text("FRAGMENT #\(entry.id.uuidString.prefix(8))")
                            .font(GlitchTheme.terminalFont(size: 12))
                            .foregroundColor(GlitchTheme.glitchYellow)
                            .screenFlicker(intensity: 0.2)
                    }
                    
                    Spacer()
                    
                    // Edit button with terminal styling
                    Button(action: {
                        showingEditView = true
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
                
                // Display content as a corrupted memory terminal
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title with glitch effect
                        if let entry = viewModel.entry {
                            // Status header
                            HStack {
                                // Corruption status indicator
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                        .frame(width: 8, height: 8)
                                        .screenFlicker(intensity: Double(entry.decayLevel) / 100.0)
                                    
                                    Text("MEMORY STABILITY: \(100 - entry.decayLevel)%")
                                        .font(GlitchTheme.terminalFont(size: 14))
                                        .foregroundColor(GlitchTheme.colorForDecayLevel(entry.decayLevel))
                                }
                                
                                Spacer()
                                
                                // Technical readout
                                Text("SYS.DECRYPT STATUS: \(entry.decayLevel > 50 ? "DEGRADED" : "NOMINAL")")
                                    .font(GlitchTheme.terminalFont(size: 10))
                                    .foregroundColor(entry.decayLevel > 50 ? GlitchTheme.glitchRed : GlitchTheme.glitchCyan)
                            }
                            .padding(.vertical, 5)
                            
                            // Title display with high emphasis
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ENTRY DESIGNATION:")
                                    .font(GlitchTheme.terminalFont(size: 12))
                                    .foregroundColor(GlitchTheme.glitchYellow.opacity(0.7))
                                
                                GlitchedText(text: entry.title, decayLevel: entry.decayLevel, size: 28)
                                    .padding(.vertical, 4)
                            }
                            .padding(.vertical, 5)
                            
                            // Creation info with terminal styling
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Text("TIMESTAMP:")
                                        .font(GlitchTheme.terminalFont(size: 12))
                                        .foregroundColor(GlitchTheme.glitchYellow.opacity(0.7))
                                    
                                    Text(formattedDate(entry.creationDate))
                                        .font(GlitchTheme.terminalFont(size: 12))
                                        .foregroundColor(GlitchTheme.terminalGreen)
                                }
                                
                                // Last restored info if available
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
                            
                            // Divider with terminal styling
                            Rectangle()
                                .fill(GlitchTheme.colorForDecayLevel(entry.decayLevel).opacity(0.3))
                                .frame(height: 1)
                                .padding(.vertical, 10)
                            
                            // Data visualization representation
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
                            
                            // Entry content with glitch effects
                            VStack(alignment: .leading, spacing: 6) {
                                Text("MEMORY CONTENT:")
                                    .font(GlitchTheme.terminalFont(size: 12))
                                    .foregroundColor(GlitchTheme.glitchYellow.opacity(0.7))
                                
                                GlitchedText(text: entry.content, decayLevel: entry.decayLevel, size: 16)
                                    .lineSpacing(6)
                                    .glitchBlocks(intensity: Double(entry.decayLevel) / 200)
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                }
                .overlay(
                    Group {
                        if viewModel.showRestoreAnimation {
                            EnhancedRestorationView(progress: viewModel.restorationProgress)
                        }
                    }
                )
                
                Spacer()
                
                // Enhanced restore button
                if let entry = viewModel.entry, entry.decayLevel > 10 {
                    Button(action: {
                        viewModel.restoreEntry()
                        
                        // Add glitch effect animation on restore
                        withAnimation(.easeInOut(duration: 0.3)) {
                            glitchIntensity = 3.0
                        }
                        
                        // Return to normal after animation
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
                            
                            // Add technical detail for immersion
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
                }
            }
            .padding(.horizontal)
            
            // Apply CRT effects and static
            Color.black.opacity(0.03)
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .screenFlicker(intensity: 0.2)
            
            // Add RGB split for heavily degraded entries or when restoring
            if let entry = viewModel.entry, entry.decayLevel > 60 || glitchIntensity > 0 {
                Color.clear
                    .allowsHitTesting(false)
                    .rgbSplit(amount: max(CGFloat(entry.decayLevel) / 50, CGFloat(glitchIntensity)), angle: 0)
                    .ignoresSafeArea()
                    .compositingGroup()
                    .blendMode(.screen)
            }
        }
        .crtEffect(intensity: 1.0)
        .background(GlitchTheme.background.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showingEditView) {
            if let entry = viewModel.entry {
                EntryEditView(store: viewModel.viewModelStore, entry: entry)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

#Preview {
    EntryDetailView(store: JournalEntryStore(), entry: JournalEntry(title: "Test Memory", content: "This is a test memory fragment with some content that will display in the detail view.", decayLevel: 40))
} 