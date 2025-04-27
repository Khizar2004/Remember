import SwiftUI

struct TagView: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Text(tag)
            .font(GlitchTheme.pixelFont(size: 12))
            .foregroundColor(isSelected ? GlitchTheme.background : GlitchTheme.glitchCyan)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isSelected ? GlitchTheme.glitchCyan : GlitchTheme.cardBackground
            )
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(GlitchTheme.glitchCyan.opacity(0.6), lineWidth: 1)
            )
            .onTapGesture {
                onTap()
                HapticFeedback.light()
            }
    }
}

struct TagsContainerView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showingTagInput = false
    @State private var newTagText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FILTER BY TAGS")
                    .font(GlitchTheme.terminalFont(size: 12))
                    .foregroundColor(GlitchTheme.glitchYellow)
                
                Spacer()
                
                if !viewModel.selectedTags.isEmpty {
                    Button(action: {
                        viewModel.clearTagSelection()
                        HapticFeedback.light()
                    }) {
                        Text("CLEAR")
                            .font(GlitchTheme.terminalFont(size: 12))
                            .foregroundColor(GlitchTheme.glitchCyan)
                    }
                    .padding(.trailing, 8)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.availableTags, id: \.self) { tag in
                        TagView(
                            tag: tag,
                            isSelected: viewModel.selectedTags.contains(tag),
                            onTap: { viewModel.toggleTag(tag) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(GlitchTheme.background.opacity(0.6))
    }
}

// Preview
struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TagView(tag: "IMPORTANT", isSelected: true, onTap: {})
            TagView(tag: "WORK", isSelected: false, onTap: {})
            
            TagsContainerView(viewModel: HomeViewModel())
        }
        .padding()
        .background(GlitchTheme.background)
    }
} 