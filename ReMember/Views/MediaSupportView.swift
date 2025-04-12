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
    @State private var scale: CGFloat = 1.0
    @State private var image: UIImage? = nil
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value.magnitude
                            }
                    )
            } else {
                ProgressView()
                    .tint(.cyan)
            }
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.6), radius: 3, x: 0, y: 0)
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
        .id(photoURL.lastPathComponent) // Ensure unique identity
        .onAppear {
            // Force immediate load on appear
            loadImageImmediate()
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