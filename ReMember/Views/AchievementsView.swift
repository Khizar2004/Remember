import SwiftUI

struct AchievementsView: View {
    @ObservedObject var userAchievements: UserAchievements
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            GlitchTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("ACHIEVEMENTS")
                        .font(GlitchTheme.terminalFont(size: 24))
                        .foregroundColor(GlitchTheme.glitchCyan)
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(GlitchTheme.glitchRed)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Stats section
                VStack(spacing: 5) {
                    HStack {
                        statsCard(
                            title: "CURRENT STREAK",
                            value: "\(userAchievements.currentStreak)",
                            icon: "flame.fill",
                            color: GlitchTheme.glitchRed
                        )
                        
                        statsCard(
                            title: "LONGEST STREAK",
                            value: "\(userAchievements.longestStreak)",
                            icon: "crown.fill",
                            color: GlitchTheme.glitchYellow
                        )
                    }
                    
                    HStack {
                        statsCard(
                            title: "MEMORIES RESTORED",
                            value: "\(userAchievements.totalMemoriesRestored)",
                            icon: "brain.head.profile",
                            color: GlitchTheme.glitchCyan
                        )
                        
                        statsCard(
                            title: "CHALLENGES COMPLETED",
                            value: "\(userAchievements.totalChallengesCompleted)",
                            icon: "checkmark.shield.fill",
                            color: GlitchTheme.terminalGreen
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Achievements section
                Text("MEMORY RECOVERY MILESTONES")
                    .font(GlitchTheme.terminalFont(size: 16))
                    .foregroundColor(GlitchTheme.terminalGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                
                // Achievements list
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(userAchievements.achievements, id: \.id) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // Stats card component
    private func statsCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(GlitchTheme.terminalFont(size: 12))
                    .foregroundColor(GlitchTheme.terminalGreen)
            }
            
            Text(value)
                .font(GlitchTheme.terminalFont(size: 28))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(GlitchTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// Achievement card component
struct AchievementCard: View {
    var achievement: Achievement
    
    var body: some View {
        HStack(spacing: 15) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? GlitchTheme.glitchCyan.opacity(0.2) : GlitchTheme.cardBackground)
                    .frame(width: 60, height: 60)
                
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(GlitchTheme.glitchCyan)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(GlitchTheme.glitchYellow.opacity(0.5))
                }
            }
            
            // Achievement details
            VStack(alignment: .leading, spacing: 5) {
                Text(achievement.title)
                    .font(GlitchTheme.terminalFont(size: 16))
                    .foregroundColor(achievement.isUnlocked ? GlitchTheme.glitchCyan : GlitchTheme.terminalGreen)
                
                Text(achievement.description)
                    .font(GlitchTheme.terminalFont(size: 12))
                    .foregroundColor(GlitchTheme.terminalGreen.opacity(0.8))
                    .lineLimit(2)
                
                if let unlockDate = achievement.unlockDate, achievement.isUnlocked {
                    Text("Unlocked: \(formatDate(unlockDate))")
                        .font(GlitchTheme.terminalFont(size: 10))
                        .foregroundColor(GlitchTheme.glitchYellow)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Progress or completion indicator
            if achievement.isUnlocked {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(GlitchTheme.glitchYellow)
            } else {
                let progress = calculateProgress(for: achievement)
                Text("\(Int(progress * 100))%")
                    .font(GlitchTheme.terminalFont(size: 16))
                    .foregroundColor(GlitchTheme.glitchYellow)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GlitchTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            achievement.isUnlocked ? 
                                GlitchTheme.glitchCyan.opacity(0.5) : 
                                GlitchTheme.terminalGreen.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // Calculate progress towards achievement
    private func calculateProgress(for achievement: Achievement) -> Double {
        let currentProgress: Double
        
        switch achievement.type {
        case .memoriesRestored:
            currentProgress = Double(UserDefaults.standard.integer(forKey: "totalMemoriesRestored"))
        case .streak:
            currentProgress = Double(UserDefaults.standard.integer(forKey: "currentStreak"))
        }
        
        let requiredProgress = Double(achievement.requiredCount)
        return min(currentProgress / requiredProgress, 1.0)
    }
    
    // Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
} 