import SwiftUI

struct DecayTimelineView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Memory Decay Timeline")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.toggleDecayTimeline()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding([.horizontal, .top])
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.entriesByDecayLevel) { group in
                        if !group.entries.isEmpty {
                            DecayGroupView(group: group, viewModel: viewModel)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }
}

struct DecayGroupView: View {
    let group: DecayGroup
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(group.color)
                    .frame(width: 12, height: 12)
                
                Text(group.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(group.entries.count) memories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            ForEach(group.entries) { entry in
                DecayEntryRow(entry: entry, viewModel: viewModel)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct DecayEntryRow: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.title)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Spacer()
                
                // Display a badge showing exact decay level
                Text("\(entry.decayLevel)%")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(decayColor.opacity(0.2))
                    .foregroundColor(decayColor)
                    .cornerRadius(4)
            }
            
            // Decay bar visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    // Decay progress
                    Rectangle()
                        .fill(decayColor)
                        .frame(width: CGFloat(entry.decayLevel) / 100 * geometry.size.width, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            .padding(.top, 2)
            
            // Last restored date
            if let lastRestored = entry.lastRestoredDate {
                Text("Last Restored: \(dateFormatter.string(from: lastRestored))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Buttons for actions
            HStack {
                Spacer()
                
                Button(action: {
                    viewModel.restoreEntry(id: entry.id)
                }) {
                    Label("Restore", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.blue)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var decayColor: Color {
        switch entry.decayLevel {
        case 0..<25: return .green
        case 25..<50: return .yellow
        case 50..<75: return .orange
        case 75...100: return .red
        default: return .gray
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    DecayTimelineView(viewModel: HomeViewModel())
        .environment(\.colorScheme, .dark)
        .previewLayout(.sizeThatFits)
} 