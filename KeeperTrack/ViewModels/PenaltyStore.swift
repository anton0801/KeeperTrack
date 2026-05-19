import Foundation
import Combine

class PenaltyStore: ObservableObject {
    @Published var penalties: [PenaltyRecord] = []
    private let saveKey = "penalty_records"

    init() { load() }

    func add(_ penalty: PenaltyRecord) {
        penalties.append(penalty)
        save()
    }

    func update(_ penalty: PenaltyRecord) {
        if let idx = penalties.firstIndex(where: { $0.id == penalty.id }) {
            penalties[idx] = penalty
            save()
        }
    }

    func delete(_ penalty: PenaltyRecord) {
        penalties.removeAll { $0.id == penalty.id }
        save()
    }

    func penalties(for keeperID: UUID) -> [PenaltyRecord] {
        penalties.filter { $0.keeperID == keeperID }
    }

    func saveRate(for keeperID: UUID) -> Double {
        let records = penalties(for: keeperID)
        guard !records.isEmpty else { return 0 }
        let saves = records.filter { $0.outcome == .saved }.count
        return Double(saves) / Double(records.count) * 100
    }

    func analytics(for keeperID: UUID) -> AnalyticsSummary {
        let records = penalties(for: keeperID)
        let saves = records.filter { $0.outcome == .saved }.count
        let scored = records.filter { $0.outcome == .scored }.count
        let missed = records.filter { $0.outcome == .missed }.count
        let leftDive = records.filter { $0.diveDirection == .left }.count
        let centerDive = records.filter { $0.diveDirection == .center }.count
        let rightDive = records.filter { $0.diveDirection == .right }.count

        var heatData: [PenaltyZone: Int] = [:]
        var savesByZone: [PenaltyZone: Int] = [:]
        for zone in PenaltyZone.allCases {
            let zoneRecords = records.filter { $0.shotZone == zone }
            heatData[zone] = zoneRecords.count
            savesByZone[zone] = zoneRecords.filter { $0.outcome == .saved }.count
        }

        var saveRateByZone: [PenaltyZone: Double] = [:]
        for zone in PenaltyZone.allCases {
            let total = heatData[zone] ?? 0
            let zoneSaves = savesByZone[zone] ?? 0
            saveRateByZone[zone] = total > 0 ? Double(zoneSaves) / Double(total) * 100 : 0
        }

        // Build weekly data (last 6 weeks)
        let calendar = Calendar.current
        let now = Date()
        var weeklyPoints: [AnalyticsSummary.WeeklyPoint] = []
        for i in (0..<6).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            let weekRecords = records.filter { $0.date >= weekStart && $0.date < weekEnd }
            let label = i == 0 ? "Now" : "W-\(i)"
            weeklyPoints.append(.init(label: label, saves: weekRecords.filter { $0.outcome == .saved }.count, total: weekRecords.count))
        }

        return AnalyticsSummary(
            totalPenalties: records.count,
            saves: saves, scored: scored, missed: missed,
            leftDiveCount: leftDive, centerDiveCount: centerDive, rightDiveCount: rightDive,
            zoneHeatData: heatData, saveRateByZone: saveRateByZone, weeklyData: weeklyPoints
        )
    }

    // Global analytics
    func globalAnalytics() -> AnalyticsSummary {
        let records = penalties
        let saves = records.filter { $0.outcome == .saved }.count
        let scored = records.filter { $0.outcome == .scored }.count
        let missed = records.filter { $0.outcome == .missed }.count
        let leftDive = records.filter { $0.diveDirection == .left }.count
        let centerDive = records.filter { $0.diveDirection == .center }.count
        let rightDive = records.filter { $0.diveDirection == .right }.count

        var heatData: [PenaltyZone: Int] = [:]
        var saveRateByZone: [PenaltyZone: Double] = [:]
        for zone in PenaltyZone.allCases {
            let zoneRecords = records.filter { $0.shotZone == zone }
            let total = zoneRecords.count
            heatData[zone] = total
            let zoneSaves = zoneRecords.filter { $0.outcome == .saved }.count
            saveRateByZone[zone] = total > 0 ? Double(zoneSaves) / Double(total) * 100 : 0
        }

        let calendar = Calendar.current
        let now = Date()
        var weeklyPoints: [AnalyticsSummary.WeeklyPoint] = []
        for i in (0..<6).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            let weekRecords = records.filter { $0.date >= weekStart && $0.date < weekEnd }
            weeklyPoints.append(.init(label: i == 0 ? "Now" : "W-\(i)", saves: weekRecords.filter { $0.outcome == .saved }.count, total: weekRecords.count))
        }

        return AnalyticsSummary(
            totalPenalties: records.count, saves: saves, scored: scored, missed: missed,
            leftDiveCount: leftDive, centerDiveCount: centerDive, rightDiveCount: rightDive,
            zoneHeatData: heatData, saveRateByZone: saveRateByZone, weeklyData: weeklyPoints
        )
    }

    private func save() {
        if let data = try? JSONEncoder().encode(penalties) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([PenaltyRecord].self, from: data) {
            penalties = decoded
        }
    }
}
