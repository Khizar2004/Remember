import SwiftUI
import PhotosUI

// MARK: - Photo Picker Component
struct PhotoPickerView: View {
    @ObservedObject var viewModel: EntryViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Text("MEMORY ATTACHMENTS")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.cyan)
                .shadow(color: .cyan.opacity(0.8), radius: 2, x: 0, y: 0)
            
            // Display existing photo attachments in a grid
            if !viewModel.photoAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.flexible())], spacing: 10) {
                        ForEach(Array(viewModel.photoAttachments.keys), id: \.self) { photoID in
                            if let photoURL = viewModel.photoAttachments[photoID] {
                                PhotoThumbnailView(photoURL: photoURL, photoID: photoID, viewModel: viewModel)
                            }
                        }
                    }
                    .frame(height: 150)
                    .padding(.horizontal)
                }
            }
            
            // Photo picker button - styled to match the aesthetic
            PhotosPicker(selection: $selectedItems, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(.body, design: .monospaced))
                    Text("ADD PHOTOS")
                        .font(.system(.body, design: .monospaced))
                }
                .foregroundColor(.green)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.green.opacity(0.7), lineWidth: 2)
                        .background(Color.black.opacity(0.3).cornerRadius(6))
                )
                .shadow(color: .green.opacity(0.5), radius: 3, x: 0, y: 0)
            }
            .onChange(of: selectedItems) { newItems in
                Task {
                    for item in newItems {
                        // Try to get the image data
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            // Add the photo attachment on the main thread
                            DispatchQueue.main.async {
                                let _ = viewModel.addPhotoAttachment(imageData: data)
                                
                                // Force view refresh by updating the view model
                                viewModel.objectWillChange.send()
                            }
                        }
                    }
                    // Reset selection
                    selectedItems = []
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Photo Thumbnail View
struct PhotoThumbnailView: View {
    let photoURL: URL
    let photoID: UUID
    @ObservedObject var viewModel: EntryViewModel
    @State private var isPresented = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Container for image with styling
            ZStack {
                if let uiImage = loadImage(from: photoURL) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ProgressView()
                        .tint(.cyan)
                }
            }
            .frame(width: 120, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.cyan.opacity(0.8), lineWidth: 2)
            )
            .shadow(color: .cyan.opacity(0.5), radius: 3, x: 0, y: 0)
            .contentShape(RoundedRectangle(cornerRadius: 6))
            .onTapGesture {
                isPresented = true
            }
            
            // Delete button
            Button(action: {
                viewModel.removePhotoAttachment(id: photoID)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                    .shadow(color: .black, radius: 1, x: 0, y: 0)
            }
            .padding(5)
        }
        .fullScreenCover(isPresented: $isPresented) {
            PhotoDetailView(photoURL: photoURL, isPresented: $isPresented)
        }
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        // Check if file exists first
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let imageData = try Data(contentsOf: url)
            return UIImage(data: imageData)
        } catch {
            return nil
        }
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let photoURL: URL
    @Binding var isPresented: Bool
    var decayLevel: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var image: UIImage? = nil
    
    var body: some View {
        // Calculate decay factor
        let decayFactor = min(max(Double(decayLevel), 0), 100) / 100.0
        
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    // Apply decay effects to full screen view - intensify for high corruption
                    .opacity(max(1.0 - (decayFactor * 0.5), 0.5)) // More aggressive opacity reduction
                    .blur(radius: decayFactor > 0.5 ? min(decayFactor * 5.0, 5.0) : 0) // Much stronger blur for high decay
                    .contrast(max(1.0 - (decayFactor * 0.7), 0.3)) // More aggressive contrast reduction
                    .saturation(max(1.0 - (decayFactor * 0.8), 0.2)) // Almost grayscale at high decay
                    .rgbSplit(amount: decayFactor > 0.3 ? min(CGFloat(decayFactor * 8), 8) : 0, angle: 90) // Much stronger RGB split
                    .digitalNoise(intensity: min(decayFactor * 0.8, 0.8)) // Stronger noise
                    // Add glitch blocks overlay for heavily corrupted images
                    .overlay(
                        Group {
                            if decayFactor > 0.7 {
                                ZStack {
                                    // Random glitch rectangles
                                    ForEach(0..<Int(decayFactor * 10), id: \.self) { _ in
                                        Rectangle()
                                            .fill(Color.cyan.opacity(0.3))
                                            .frame(
                                                width: CGFloat.random(in: 10...100),
                                                height: CGFloat.random(in: 5...30)
                                            )
                                            .offset(
                                                x: CGFloat.random(in: -150...150),
                                                y: CGFloat.random(in: -200...200)
                                            )
                                            .blendMode(.difference)
                                    }
                                    
                                    // Add horizontal scan lines for severe corruption
                                    if decayFactor > 0.9 {
                                        VStack(spacing: 4) {
                                            ForEach(0..<15, id: \.self) { _ in
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.15))
                                                    .frame(height: 1)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                }
                            }
                        }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value.magnitude
                            }
                    )
            } else {
                ProgressView()
                    .tint(GlitchTheme.colorForDecayLevel(decayLevel))
            }
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                            .shadow(color: GlitchTheme.colorForDecayLevel(decayLevel).opacity(0.6), radius: 3, x: 0, y: 0)
                            .padding(20) // Increase padding to create larger tap target
                    }
                    .buttonStyle(PlainButtonStyle()) // Ensure button styling doesn't interfere with taps
                    .contentShape(Rectangle()) // Ensure entire area is tappable
                }
                
                Spacer()
                
                // Fixed height container for corruption indicator
                ZStack {
                    // Only show text if needed, but container is always present
                    if decayLevel > 50 {
                        Text("MEMORY CORRUPTION: \(decayLevel)%")
                            .font(GlitchTheme.terminalFont(size: 16))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            .glitchBlocks(intensity: min(decayFactor * 0.6, 0.6))
                    }
                }
                .frame(height: 40) // Fixed height container
                .padding(.bottom, 20)
            }
        }
        .id(photoURL.lastPathComponent) // Ensure unique identity
        .onAppear {
            // Force immediate load on appear
            loadImageImmediate()
        }
        // Add overall glitch effect for higher decay levels - intensify for high corruption
        .modifier(GlitchTheme.NoiseModifier(intensity: min(decayFactor * 0.8, 0.8)))
        .screenFlicker(intensity: min(decayFactor * 0.6, 0.6))
        // Add a second dismiss gesture as a backup escape method
        .onTapGesture(count: 2) {
            isPresented = false
        }
    }
    
    private func loadImageImmediate() {
        DispatchQueue.global(qos: .userInitiated).async {
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
}

#Preview {
    VStack {
        PhotoPickerView(viewModel: EntryViewModel(store: JournalEntryStore()))
    }
    .padding()
    .background(Color.black)
} 