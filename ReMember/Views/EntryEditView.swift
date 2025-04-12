import SwiftUI

struct EntryEditView: View {
    @StateObject private var viewModel: EntryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var cursorVisible = true
    @State private var randomGlitches = false
    
    init(store: JournalEntryStore, entry: JournalEntry? = nil) {
        _viewModel = StateObject(wrappedValue: EntryViewModel(store: store, entry: entry))
    }
    
    var body: some View {
        ZStack {
            // Glitched terminal background
            GlitchTheme.background.edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(alignment: .leading) {
                // Header with system status display
                HStack {
                    // Back button with terminal styling
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.backward")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(GlitchTheme.terminalGreen)
                                
                            Text("ABORT")
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
                    
                    // System status
                    HStack {
                        Circle()
                            .fill(GlitchTheme.glitchCyan)
                            .frame(width: 8, height: 8)
                            .screenFlicker(intensity: 0.2)
                        
                        Text(viewModel.isEditing ? "EDITOR.SYS [MODIFY]" : "EDITOR.SYS [CREATE]")
                            .font(GlitchTheme.terminalFont(size: 14))
                            .foregroundColor(GlitchTheme.glitchCyan)
                    }
                    
                    Spacer()
                    
                    // Save button with terminal styling
                    Button(action: {
                        // Trigger random glitch effects on save
                        randomGlitches = true
                        
                        // Return to normal after a delay and save
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            randomGlitches = false
                            viewModel.saveEntry()
                            
                            // Dismiss this view after saving
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(GlitchTheme.glitchCyan)
                                
                            Text("SAVE")
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
                    .disabled(viewModel.title.isEmpty || viewModel.content.isEmpty)
                    .opacity(viewModel.title.isEmpty || viewModel.content.isEmpty ? 0.5 : 1.0)
                }
                .padding(.top, 20)
                
                // Session info
                HStack(spacing: 4) {
                    Text("TIMESTAMP: \(currentDateFormatted)")
                        .font(GlitchTheme.terminalFont(size: 12))
                        .foregroundColor(GlitchTheme.glitchYellow)
                    
                    Spacer()
                    
                    // Blinking cursor to indicate active input
                    if cursorVisible {
                        Rectangle()
                            .fill(GlitchTheme.terminalGreen)
                            .frame(width: 5, height: 12)
                    }
                }
                .padding(.top, 10)
                
                // Content area with glitched terminal styling
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title input field with system prompt
                        VStack(alignment: .leading, spacing: 5) {
                            Text("MEMORY DESIGNATION:")
                                .font(GlitchTheme.terminalFont(size: 12))
                                .foregroundColor(GlitchTheme.glitchYellow.opacity(0.7))
                                
                            TextField("ENTER MEMORY TITLE", text: $viewModel.title)
                                .font(GlitchTheme.terminalFont(size: 20))
                                .foregroundColor(GlitchTheme.terminalGreen)
                                .accentColor(GlitchTheme.glitchCyan)
                                .padding(10)
                                .background(GlitchTheme.fieldBackground)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(GlitchTheme.terminalGreen.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .padding(.vertical, 10)
                        
                        // Separator
                        HStack {
                            Text("MEMORY CONTENT EDITOR")
                                .font(GlitchTheme.terminalFont(size: 12))
                                .foregroundColor(GlitchTheme.glitchYellow.opacity(0.7))
                            
                            Rectangle()
                                .fill(GlitchTheme.glitchYellow.opacity(0.3))
                                .frame(height: 1)
                        }
                        
                        // Memory content with system styling
                        ZStack(alignment: .topLeading) {
                            // Text editor with glitched terminal style
                            TextEditor(text: $viewModel.content)
                                .font(GlitchTheme.terminalFont(size: 16))
                                .foregroundColor(GlitchTheme.terminalGreen)
                                .accentColor(GlitchTheme.glitchCyan)
                                .frame(minHeight: 300)
                                .padding(10)
                                .background(GlitchTheme.fieldBackground)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(GlitchTheme.terminalGreen.opacity(0.5), lineWidth: 1)
                                )
                            
                            // Placeholder text
                            if viewModel.content.isEmpty {
                                Text("ENTER MEMORY CONTENT")
                                    .font(GlitchTheme.terminalFont(size: 16))
                                    .foregroundColor(GlitchTheme.terminalGreen.opacity(0.5))
                                    .padding(15)
                                    .padding(.top, 10)
                                    .allowsHitTesting(false)
                            }
                        }
                        
                        // System info display
                        HStack {
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("BUFFER: \(viewModel.content.count) BYTES")
                                    .font(GlitchTheme.terminalFont(size: 12))
                                    .foregroundColor(GlitchTheme.glitchCyan)
                                
                                Text("EDIT MODE: ACTIVE")
                                    .font(GlitchTheme.terminalFont(size: 12))
                                    .foregroundColor(viewModel.isEditing ? GlitchTheme.glitchYellow : GlitchTheme.glitchCyan)
                                    .screenFlicker(intensity: 0.3)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.vertical, 10)
                }
            }
            .padding(.horizontal)
            
            // Apply glitch effects on save
            if randomGlitches {
                // Full screen glitch effect
                Color.clear
                    .rgbSplit(amount: 3.0, angle: 90)
                    .glitchBlocks(intensity: 0.7)
                    .allowsHitTesting(false)
                    .compositingGroup()
                    .blendMode(.screen)
            }
            
            // Static CRT overlay
            Color.black.opacity(0.02)
                .allowsHitTesting(false)
                .screenFlicker(intensity: 0.1)
                .ignoresSafeArea()
            
            // Screen edge distortion and vignette
            RadialGradient(
                gradient: Gradient(
                    colors: [
                        Color.clear,
                        GlitchTheme.background.opacity(0.5)
                    ]
                ),
                center: .center,
                startRadius: 150,
                endRadius: 350
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
        .crtEffect(intensity: 0.8)
        .background(GlitchTheme.background)
        .onAppear {
            // Ensures TextEditor has the same background color as its container
            UITextView.appearance().backgroundColor = .clear
            
            // Start cursor blinking
            startCursorBlink()
        }
        .onDisappear {
            // Double-check to ensure the home view refreshes
            if viewModel.entrySaved {
                viewModel.viewModelStore.loadEntries()
            }
        }
    }
    
    // Create blinking cursor effect
    private func startCursorBlink() {
        Timer.publish(every: 0.6, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                cursorVisible.toggle()
            }
    }
    
    private var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}

#Preview {
    EntryEditView(store: JournalEntryStore())
} 