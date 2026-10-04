import SwiftUI
import UIKit

struct AchievementsView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var category: AchievementCategory?

    private var definitions: [AchievementDefinition] {
        AchievementCatalog.all.filter { category == nil || $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    profileCard
                    categoryPicker
                    LazyVStack(spacing: 12) {
                        ForEach(definitions) { achievement in
                            AchievementRow(achievement: achievement)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("LEVEL \(store.achievementProfile.level)").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("\(store.achievementProfile.totalXP) XP").font(.largeTitle.bold())
                }
                Spacer()
                ZStack {
                    Circle().fill(.thinMaterial)
                    Image(systemName: "trophy.fill").font(.system(size: 34))
                }
                .frame(width: 72, height: 72)
            }
            ProgressView(value: Double(store.achievementProfile.xpIntoLevel), total: Double(store.achievementProfile.xpForNextLevel))
            Text("\(store.achievementProfile.unlockedIDs.count) / \(AchievementCatalog.all.count) unlocked")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button("All") { category = nil }
                    .buttonStyle(.borderedProminent)
                    .tint(category == nil ? .accentColor : .gray.opacity(0.35))
                ForEach(AchievementCategory.allCases) { item in
                    Button(item.rawValue) { category = item }
                        .buttonStyle(.borderedProminent)
                        .tint(category == item ? .accentColor : .gray.opacity(0.35))
                }
            }
        }
    }
}

private struct AchievementRow: View {
    @EnvironmentObject var store: LibraryStore
    let achievement: AchievementDefinition

    private var unlocked: Bool { store.achievementProfile.unlockedIDs.contains(achievement.id) }
    private var progress: Double { store.achievementProgress(for: achievement) }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(.quaternary)
                Image(systemName: unlocked ? achievement.tier.systemImage : "lock.fill")
                    .font(.title2)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(achievement.hidden && !unlocked ? "???" : achievement.title).font(.headline)
                    Spacer()
                    Text("+\(achievement.xp) XP").font(.caption.bold()).foregroundStyle(.secondary)
                }
                Text(achievement.hidden && !unlocked ? "Hidden achievement" : achievement.detail)
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                if !unlocked {
                    ProgressView(value: min(1, progress / max(1, achievement.target)))
                    if !achievement.hidden {
                        Text("\(Int(progress)) / \(Int(achievement.target))")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                } else if let date = store.achievementProfile.unlockedAt[achievement.id] {
                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .opacity(unlocked ? 1 : 0.78)
    }
}

struct AchievementBanner: View {
    let achievement: AchievementDefinition

    private var rarityColor: Color {
        switch achievement.tier {
        case .bronze: return Color(red: 0.76, green: 0.40, blue: 0.18)
        case .silver: return Color(red: 0.72, green: 0.76, blue: 0.82)
        case .gold: return Color(red: 0.96, green: 0.72, blue: 0.18)
        case .platinum: return Color(red: 0.25, green: 0.78, blue: 0.92)
        case .legendary: return Color(red: 0.65, green: 0.34, blue: 0.95)
        }
    }

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(rarityColor.opacity(0.20))
                    .frame(width: 48, height: 48)
                Image(systemName: achievement.tier.systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(rarityColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text("ACHIEVEMENT UNLOCKED")
                        .font(.caption2.bold())
                        .tracking(0.8)
                    Text(achievement.tier.rawValue.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(rarityColor)
                }

                Text(achievement.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(achievement.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text("+\(achievement.xp) XP")
                .font(.caption.bold())
                .foregroundStyle(rarityColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(rarityColor.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(rarityColor.opacity(0.85), lineWidth: 1.4)
        }
        .shadow(color: rarityColor.opacity(0.18), radius: 10, y: 5)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Achievement unlocked, \(achievement.title), \(achievement.tier.rawValue), plus \(achievement.xp) XP")
    }
}

