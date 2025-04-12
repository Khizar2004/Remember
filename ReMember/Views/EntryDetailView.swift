import SwiftUI
import Combine

struct EntryDetailView: View {
    @StateObject private var viewModel: EntryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditView = false
    @State private var cancellables = Set<AnyCancellable>()
    
    init(store: JournalEntryStore, entry: JournalEntry) {
        _viewModel = StateObject(wrappedValue: EntryViewModel(store: store, entry: entry))
    }
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.background.edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(10)
                            .background(AppTheme.fieldBackground)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Edit button
                    Button(action: {
                        showingEditView = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(10)
                            .background(AppTheme.fieldBackground)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Entry title
                        if let entry = viewModel.entry {
                            DecayedText(text: entry.title, decayLevel: entry.decayLevel, size: 24)
                                .padding(.bottom, 5)
                            
                            // Creation date
                            HStack {
                                Text("Created: ")
                                    .font(AppTheme.pixelFont(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Text(dateFormatter.string(from: entry.creationDate))
                                    .font(AppTheme.pixelFont(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            // Last restored date if available
                            if let restored = entry.lastRestoredDate {
                                HStack {
                                    Text("Restored: ")
                                        .font(AppTheme.pixelFont(size: 12))
                                        .foregroundColor(AppTheme.accent)
                                    
                                    Text(dateFormatter.string(from: restored))
                                        .font(AppTheme.pixelFont(size: 12))
                                        .foregroundColor(AppTheme.accent)
                                }
                            }
                            
                            Divider()
                                .background(AppTheme.textSecondary)
                                .padding(.vertical, 10)
                            
                            // Entry content
                            DecayedText(text: entry.content, decayLevel: entry.decayLevel, size: 16)
                                .lineSpacing(6)
                        }
                    }
                    .padding(.horizontal, 5)
                }
                .overlay(
                    Group {
                        if viewModel.showRestoreAnimation {
                            RestorationAnimationView(progress: viewModel.restorationProgress)
                        }
                    }
                )
                
                Spacer()
                
                // Restore Button
                if let entry = viewModel.entry, entry.decayLevel > 10 {
                    Button(action: {
                        viewModel.restoreEntry()
                    }) {
                        HStack {
                            Spacer()
                            Text("RESTORE MEMORY")
                                .font(AppTheme.pixelFont(size: 16))
                                .foregroundColor(AppTheme.background)
                            Spacer()
                        }
                        .padding()
                        .background(AppTheme.accent)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            // Static CRT overlay that doesn't block touch events
            VStack(spacing: 2) {
                ForEach(0..<100, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .frame(height: 1)
                }
            }
            .allowsHitTesting(false)
            
            // CRT vignette effect (increased intensity)
            RadialGradient(
                gradient: Gradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.4)
                    ]
                ),
                center: .center,
                startRadius: 100,
                endRadius: 300
            )
            .allowsHitTesting(false)
            
            // Add subtle screen flicker for heavily degraded entries
            if viewModel.entry?.decayLevel ?? 0 > 60 {
                Color.black.opacity(0.03)
                    .allowsHitTesting(false)
                    .animation(Animation.easeInOut(duration: 0.1).repeatForever(autoreverses: true))
            }
        }
        .background(AppTheme.background.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showingEditView) {
            if let entry = viewModel.entry {
                EntryEditView(store: viewModel.viewModelStore, entry: entry)
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

struct RestorationAnimationView: View {
    let progress: Double
    
    @State private var scanPosition: CGFloat = 0.0
    @State private var glitchOffset = CGSize.zero
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        // Ensure progress is a valid value
        let safeProgress = max(0.0, min(progress, 1.0))
        
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
            
            // Grid pattern
            VStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<10, id: \.self) { column in
                            let isRestored = Double(row * 10 + column) / 200.0 <= safeProgress
                            
                            Rectangle()
                                .fill(isRestored ? AppTheme.accent : AppTheme.textSecondary.opacity(0.3))
                                .frame(width: 15, height: 15)
                        }
                    }
                }
            }
            .blur(radius: 1)
            .offset(glitchOffset)
            
            // Scan line
            Rectangle()
                .fill(AppTheme.accent)
                .frame(height: 2)
                .opacity(0.8)
                .offset(y: scanPosition)
            
            // Progress text
            Text("MEMORY RESTORATION: \(Int(safeProgress * 100))%")
                .font(AppTheme.pixelFont(size: 18))
                .foregroundColor(AppTheme.accent)
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
        }
        .onAppear {
            // Animate scan line with a fixed offset
            withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                scanPosition = 200
            }
            
            // Fixed glitch offsets with timer
            Timer.publish(every: 0.2, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    // Use fixed small values to avoid potential calculation issues
                    let offsetX = [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0].randomElement() ?? 0.0
                    let offsetY = [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0].randomElement() ?? 0.0
                    
                    withAnimation(.easeInOut(duration: 0.1)) {
                        glitchOffset = CGSize(width: offsetX, height: offsetY)
                    }
                }
                .store(in: &cancellables)
        }
    }
} 