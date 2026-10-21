import SwiftUI
import UIKit

struct AchievementsView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var category: AchievementCategory?
    @State private var domain: AchievementDomain = .books

    private var domainDefinitions: [AchievementDefinition] {
        AchievementCatalog.all.filter { $0.domain == domain }
    }

    private var definitions: [AchievementDefinition] {
        domainDefinitions.filter { category == nil || $0.category == category }
    }

    var body: some View {
        let snapshot = store.achievementSnapshot(for: domain)
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("Başarım türü", selection: $domain) {
                        ForEach(AchievementDomain.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    profileCard
                    categoryPicker
                    LazyVStack(spacing: 12) {
                        ForEach(definitions) { achievement in
                            AchievementRow(achievement: achievement, progress: snapshot.value(for: achievement.metric))
                        }
                    }
                }
                .padding()
            }
            .bookHubSurface(when: domain == .books)
            .comicHubSurface(when: domain == .comics && store.activeReaderProfile == .comics)
            .navigationTitle("Başarımlar")
        }
        .onAppear {
            domain = store.activeReaderProfile == .books ? .books : .comics
            store.evaluateAchievements()
        }
        .onChange(of: domain) { _, _ in category = nil }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SEVİYE \(store.achievementProfile.level)").font(.caption.bold()).foregroundStyle(.secondary)
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
            Text("\(domainDefinitions.filter { store.achievementProfile.unlockedIDs.contains($0.id) }.count) / \(domainDefinitions.count) \(domain == .books ? "kitap" : "çizgi roman") başarımı kazanıldı")
                .font(.subheadline).foregroundStyle(.secondary)
            Text("Seviye ve XP tüm başarımların toplamıdır.").font(.caption).foregroundStyle(.secondary)
        }
        .padding(18)
        .background {
            if domain == .books { RoundedRectangle(cornerRadius: 22).fill(BookHubPalette.surface) }
            else if store.activeReaderProfile == .comics { RoundedRectangle(cornerRadius: 22).fill(ComicHubPalette.surface) }
            else { RoundedRectangle(cornerRadius: 22).fill(.thinMaterial) }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button("Tümü") { category = nil }
                    .buttonStyle(.borderedProminent)
                    .tint(category == nil ? .accentColor : .gray.opacity(0.35))
                ForEach(AchievementCategory.allCases.filter { item in domainDefinitions.contains { $0.category == item } }) { item in
                    Button(item.label) { category = item }
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
    let progress: Double

    private var unlocked: Bool { store.achievementProfile.unlockedIDs.contains(achievement.id) }

    private var isClassicAward: Bool {
        if case .classicStage = achievement.metric { return true }
        return false
    }

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
                Text(achievement.hidden && !unlocked ? "Gizli başarım" : achievement.detail)
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                if !unlocked {
                    if isClassicAward {
                        Text("Henüz kazanılmadı").font(.caption2).foregroundStyle(.tertiary)
                    } else {
                        ProgressView(value: min(1, progress / max(1, achievement.target)))
                    }
                    if !achievement.hidden && !isClassicAward {
                        Text("\(Int(progress)) / \(Int(achievement.target))")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                } else if let date = store.achievementProfile.unlockedAt[achievement.id] {
                    Text("Kazanıldı: \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(14)
        .background {
            if achievement.domain == .books { RoundedRectangle(cornerRadius: 18).fill(BookHubPalette.surface) }
            else if store.activeReaderProfile == .comics { RoundedRectangle(cornerRadius: 18).fill(ComicHubPalette.surface) }
            else { RoundedRectangle(cornerRadius: 18).fill(.regularMaterial) }
        }
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
                    Text("BAŞARIM KAZANILDI")
                        .font(.caption2.bold())
                        .tracking(0.8)
                    Text(achievement.tier.label.uppercased())
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
        .accessibilityLabel("Başarım kazanıldı, \(achievement.title), \(achievement.tier.label), \(achievement.xp) XP")
    }
}
