import SwiftUI

struct EntryEditView: View {
    @StateObject private var viewModel: EntryViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(store: JournalEntryStore, entry: JournalEntry? = nil) {
        _viewModel = StateObject(wrappedValue: EntryViewModel(store: store, entry: entry))
    }
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.background.edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(alignment: .leading) {
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
                    
                    Text(viewModel.isEditing ? "EDIT MEMORY" : "NEW MEMORY")
                        .font(AppTheme.pixelFont(size: 18))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        // Save the entry and refresh the store
                        viewModel.saveEntry()
                        
                        // Dismiss this view after saving
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.accent)
                            .padding(10)
                            .background(AppTheme.fieldBackground)
                            .cornerRadius(8)
                    }
                    .disabled(viewModel.title.isEmpty)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Title field
                Text("TITLE")
                    .font(AppTheme.pixelFont(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.leading, 4)
                    .padding(.top, 10)
                
                TextField("", text: $viewModel.title)
                    .font(AppTheme.pixelFont(size: 18))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(10)
                    .background(AppTheme.fieldBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
                    )
                
                // Content field
                Text("CONTENT")
                    .font(AppTheme.pixelFont(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.leading, 4)
                    .padding(.top, 10)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.content)
                        .font(AppTheme.pixelFont(size: 16))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineSpacing(5)
                        .background(AppTheme.fieldBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    if viewModel.content.isEmpty {
                        Text("Start typing your memory...")
                            .font(AppTheme.pixelFont(size: 16))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                            .padding(.leading, 5)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
                
                Spacer()
                
                // Today's date display
                Text("DATE: \(currentDateFormatted)")
                    .font(AppTheme.pixelFont(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal)
            
            // Static CRT overlay that doesn't block touch events - much more subtle
            VStack(spacing: 4) {
                ForEach(0..<50, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 1)
                }
            }
            .allowsHitTesting(false)
            
            // Very subtle vignette
            RadialGradient(
                gradient: Gradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.1)
                    ]
                ),
                center: .center,
                startRadius: 150,
                endRadius: 350
            )
            .allowsHitTesting(false)
        }
        .background(AppTheme.background)
        .onAppear {
            // Ensures TextEditor has the same background color as its container
            UITextView.appearance().backgroundColor = .clear
        }
        // Force manual dismissal on save for better reliability
        .onDisappear {
            // Double-check to ensure the home view refreshes
            if viewModel.entrySaved {
                viewModel.viewModelStore.loadEntries()
            }
        }
    }
    
    private var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

#Preview {
    EntryEditView(store: JournalEntryStore())
} 