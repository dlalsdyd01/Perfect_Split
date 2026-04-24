import Foundation
import Observation

@Observable
final class ProgressStore {
    private(set) var stars: [String: Int]
    private(set) var divineStageIDs: Set<String>
    private(set) var divisionRewardedStageIDs: Set<String>
    private(set) var divisionUnlockedStageKeys: Set<String>
    private(set) var adEarnedDivisionShardCount: Int

    private static let storageKey = "perfect_split.progress.v2"
    private static let divineStorageKey = "perfect_split.divineStages.v1"
    private static let divisionRewardStorageKey = "perfect_split.divisionRewards.v1"
    private static let divisionUnlockStorageKey = "perfect_split.divisionUnlocks.v1"
    private static let adDivisionShardStorageKey = "perfect_split.adDivisionShards.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.stars = decoded
        } else {
            self.stars = [:]
        }

        if let data = UserDefaults.standard.data(forKey: Self.divineStorageKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.divineStageIDs = decoded
        } else {
            self.divineStageIDs = []
        }

        if let data = UserDefaults.standard.data(forKey: Self.divisionRewardStorageKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.divisionRewardedStageIDs = decoded
        } else {
            self.divisionRewardedStageIDs = []
        }

        if let data = UserDefaults.standard.data(forKey: Self.divisionUnlockStorageKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.divisionUnlockedStageKeys = decoded
        } else {
            self.divisionUnlockedStageKeys = []
        }

        self.adEarnedDivisionShardCount = UserDefaults.standard.integer(forKey: Self.adDivisionShardStorageKey)

        migrateDivisionRewardsFromDivineHistory()
    }

    func stars(for stage: Stage, mode: GameMode) -> Int {
        stars[progressKey(for: stage, mode: mode)] ?? legacyStars(for: stage, mode: mode)
    }

    func isDivine(_ stage: Stage, mode: GameMode) -> Bool {
        divineStageIDs.contains(progressKey(for: stage, mode: mode)) || legacyDivine(for: stage, mode: mode)
    }

    func record(stars count: Int, for stage: Stage, mode: GameMode) {
        let key = progressKey(for: stage, mode: mode)
        let current = stars(for: stage, mode: mode)
        guard count > current else { return }
        stars[key] = count
        save()
    }

    @discardableResult
    func recordDivine(for stage: Stage, mode: GameMode) -> Bool {
        let key = progressKey(for: stage, mode: mode)
        let alreadyRecorded = divineStageIDs.contains(key)
        if !alreadyRecorded {
            divineStageIDs.insert(key)
            saveDivineStages()
        }

        let awardedNewShard = divisionRewardedStageIDs.insert(stage.id).inserted
        if awardedNewShard {
            saveDivisionRewards()
        }
        return awardedNewShard
    }

    func isStageUnlocked(_ stage: Stage, mode: GameMode) -> Bool {
        guard stage != StageCatalog.firstStage else {
            return true
        }

        let key = progressKey(for: stage, mode: mode)
        if divisionUnlockedStageKeys.contains(key) {
            return true
        }

        guard let previous = StageCatalog.stage(before: stage) else {
            return false
        }
        return stars(for: previous, mode: mode) > 0
    }

    var divisionShardCount: Int {
        max(divisionRewardedStageIDs.count + adEarnedDivisionShardCount - divisionUnlockedStageKeys.count, 0)
    }

    func awardDivisionShardFromAd() {
        adEarnedDivisionShardCount += 1
        UserDefaults.standard.set(adEarnedDivisionShardCount, forKey: Self.adDivisionShardStorageKey)
    }

    func canUnlockWithDivision(_ stage: Stage, mode: GameMode) -> Bool {
        guard !isStageUnlocked(stage, mode: mode) else { return false }
        guard divisionShardCount > 0 else { return false }
        guard let previous = StageCatalog.stage(before: stage) else { return false }
        return isStageUnlocked(previous, mode: mode)
    }

    func canUnlockWithAd(_ stage: Stage, mode: GameMode) -> Bool {
        !isStageUnlocked(stage, mode: mode)
    }

    @discardableResult
    func unlockStageWithDivision(_ stage: Stage, mode: GameMode) -> Bool {
        guard canUnlockWithDivision(stage, mode: mode) else { return false }
        return unlockStage(stage, mode: mode)
    }

    @discardableResult
    func unlockStageWithAd(_ stage: Stage, mode: GameMode) -> Bool {
        guard canUnlockWithAd(stage, mode: mode) else { return false }
        return unlockStage(stage, mode: mode)
    }

    @discardableResult
    private func unlockStage(_ stage: Stage, mode: GameMode) -> Bool {
        let key = progressKey(for: stage, mode: mode)
        let inserted = divisionUnlockedStageKeys.insert(key).inserted
        if inserted {
            saveDivisionUnlocks()
        }
        return inserted
    }

    func resetAllProgress() {
        stars = [:]
        divineStageIDs = []
        divisionRewardedStageIDs = []
        divisionUnlockedStageKeys = []
        adEarnedDivisionShardCount = 0
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        UserDefaults.standard.removeObject(forKey: Self.divineStorageKey)
        UserDefaults.standard.removeObject(forKey: Self.divisionRewardStorageKey)
        UserDefaults.standard.removeObject(forKey: Self.divisionUnlockStorageKey)
        UserDefaults.standard.removeObject(forKey: Self.adDivisionShardStorageKey)
    }

    private func progressKey(for stage: Stage, mode: GameMode) -> String {
        "\(mode.rawValue):\(stage.id)"
    }

    private func legacyStars(for stage: Stage, mode: GameMode) -> Int {
        mode == .easy ? stars[stage.id] ?? 0 : 0
    }

    private func legacyDivine(for stage: Stage, mode: GameMode) -> Bool {
        mode == .easy && divineStageIDs.contains(stage.id)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(stars) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func saveDivineStages() {
        if let data = try? JSONEncoder().encode(divineStageIDs) {
            UserDefaults.standard.set(data, forKey: Self.divineStorageKey)
        }
    }

    private func saveDivisionRewards() {
        if let data = try? JSONEncoder().encode(divisionRewardedStageIDs) {
            UserDefaults.standard.set(data, forKey: Self.divisionRewardStorageKey)
        }
    }

    private func saveDivisionUnlocks() {
        if let data = try? JSONEncoder().encode(divisionUnlockedStageKeys) {
            UserDefaults.standard.set(data, forKey: Self.divisionUnlockStorageKey)
        }
    }

    private func migrateDivisionRewardsFromDivineHistory() {
        let migratedStageIDs = Set(divineStageIDs.map(canonicalStageID(from:)))
        guard !migratedStageIDs.isEmpty else { return }
        let before = divisionRewardedStageIDs.count
        divisionRewardedStageIDs.formUnion(migratedStageIDs)
        if divisionRewardedStageIDs.count != before {
            saveDivisionRewards()
        }
    }

    private func canonicalStageID(from key: String) -> String {
        let parts = key.split(separator: ":", maxSplits: 1)
        if parts.count == 2 {
            return String(parts[1])
        }
        return key
    }
}
