import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showingNewEntryView = false
    @State private var selectedEntry: JournalEntry?
    @State private var refreshTrigger = false // For forced refreshes
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                VStack(spacing: 15) {
                    // Header - fixed height to prevent layout shifts
                    Text("RE:MEMBER")
                        .font(AppTheme.pixelFont(size: 28))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.top, 20)
                        .frame(height: 40)
                    
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("Search", text: $viewModel.searchText)
                            .font(AppTheme.pixelFont(size: 16))
                            .foregroundColor(AppTheme.textPrimary)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        // Add refresh button
                        Button(action: {
                            viewModel.refreshEntries()
                            refreshTrigger.toggle() // Force view update
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.textSecondary)
                                .opacity(viewModel.isLoading ? 0.5 : 1.0)
                                .rotationEffect(Angle(degrees: viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                        }
                    }
                    .padding(10)
                    .background(AppTheme.fieldBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Entry count text
                    HStack {
                        Text("\(viewModel.store.entries.count) MEMORIES")
                            .font(AppTheme.pixelFont(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal)
                        Spacer()
                    }
                    
                    // Entries list
                    if viewModel.filteredEntries.isEmpty {
                        Spacer()
                        VStack {
                            Text("NO ENTRIES FOUND")
                                .font(AppTheme.pixelFont(size: 18))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding()
                                .frame(height: 30)
                            
                            Button(action: {
                                showingNewEntryView = true
                            }) {
                                Text("CREATE ENTRY")
                                    .font(AppTheme.pixelFont(size: 16))
                                    .foregroundColor(AppTheme.accent)
                                    .padding()
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(8)
                            }
                        }
                        Spacer()
                    } else {
                        // Use a fixed size for the scroll view area to prevent layout shifts
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredEntries) { entry in
                                    EntryCard(entry: entry)
                                        .onTapGesture {
                                            selectedEntry = entry
                                        }
                                        // Give card a fixed height based on content
                                        .frame(minHeight: 100)
                                }
                            }
                            .padding()
                            .id(refreshTrigger) // Force rebuild on refresh
                        }
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
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.background)
                                .frame(width: 60, height: 60)
                                .background(AppTheme.accent)
                                .clipShape(Circle())
                                .shadow(color: AppTheme.accent.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding([.bottom, .trailing], 30)
                    }
                }
            }
            // Use a modified version of CRT screen that doesn't animate
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .overlay(
                // Static scanlines instead of animated ones
                VStack(spacing: 2) {
                    ForEach(0..<50, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.1))
                            .frame(height: 1)
                    }
                }
                .mask(Rectangle())
                .allowsHitTesting(false)
            )
            .navigationBarHidden(true)
            .onAppear {
                print("HomeView appeared - refreshing entries")
                viewModel.refreshEntries()
            }
            .sheet(isPresented: $showingNewEntryView, onDismiss: {
                // Refresh the entries list when returning from the new entry view
                print("New entry sheet dismissed - refreshing entries")
                viewModel.refreshEntries()
                refreshTrigger.toggle() // Force view update
            }) {
                EntryEditView(store: viewModel.store)
            }
            .sheet(item: $selectedEntry, onDismiss: {
                // Refresh the entries list when returning from the detail view
                print("Detail sheet dismissed - refreshing entries")
                viewModel.refreshEntries()
                refreshTrigger.toggle() // Force view update
            }) { entry in
                EntryDetailView(store: viewModel.store, entry: entry)
            }
        }
    }
}

struct EntryCard: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Title - Simplified to avoid NaN errors
                Text(entry.title)
                    .font(AppTheme.pixelFont(size: 18))
                    .foregroundColor(AppTheme.colorForDecayLevel(entry.decayLevel))
                    .lineLimit(1)
                
                Spacer()
                
                // Decay indicator
                ZStack {
                    Circle()
                        .fill(AppTheme.colorForDecayLevel(entry.decayLevel))
                        .frame(width: 12, height: 12)
                    
                    if entry.decayLevel > 50 {
                        Circle()
                            .stroke(AppTheme.colorForDecayLevel(entry.decayLevel), lineWidth: 1)
                            .frame(width: 16, height: 16)
                            .opacity(0.7)
                    }
                }
            }
            
            // Preview content - Simplified to avoid NaN errors
            if !entry.content.isEmpty {
                Text(entry.content.count > 100 ? String(entry.content.prefix(100)) + "..." : entry.content)
                    .font(AppTheme.pixelFont(size: 14))
                    .foregroundColor(AppTheme.colorForDecayLevel(entry.decayLevel))
                    .opacity(TextDecayEffect.opacityEffect(for: entry.decayLevel))
                    .lineLimit(3)
            }
            
            // Date display
            HStack {
                Text(dateFormatter.string(from: entry.creationDate))
                    .font(AppTheme.pixelFont(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                if let restored = entry.lastRestoredDate {
                    Text("Restored: \(dateFormatter.string(from: restored))")
                        .font(AppTheme.pixelFont(size: 10))
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(10)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
} 