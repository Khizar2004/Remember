import SwiftUI
import Combine

struct EntryDetailView: View {
    @StateObject private var viewModel: EntryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditView = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var glitchIntensity = 0.0
    @State private var showingEditWarning = false
    
    // Define decay threshold beyond which editing is disallowed
    private let editDecayThreshold = 70
    
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
                            
                            // Display attached photos if any
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
                            
                            // Tags section
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
                        viewModel.initiateRestoration()
                        
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
        // Add warning alert for heavily corrupted memories
        .alert(isPresented: $showingEditWarning) {
            Alert(
                title: Text("MEMORY CORRUPTION CRITICAL"),
                message: Text("Memory fragment too degraded for modification. Stability below acceptable parameters.\n\nDefragment memory to restore edit access."),
                primaryButton: .default(Text("UNDERSTOOD")) {
                    showingEditWarning = false
                },
                secondaryButton: .cancel(Text("DEFRAGMENT")) {
                    // Initiate defragmentation when chosen
                    showingEditWarning = false
                    viewModel.initiateRestoration()
                    
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
                }
            )
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter.string(from: date)
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