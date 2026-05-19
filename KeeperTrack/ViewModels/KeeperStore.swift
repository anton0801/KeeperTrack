import Foundation
import Combine

class KeeperStore: ObservableObject {
    @Published var keepers: [Keeper] = []
    private let saveKey = "keeper_profiles"

    init() { load() }

    func add(_ keeper: Keeper) {
        keepers.append(keeper)
        save()
    }

    func update(_ keeper: Keeper) {
        if let idx = keepers.firstIndex(where: { $0.id == keeper.id }) {
            var updated = keeper
            updated.updatedAt = Date()
            keepers[idx] = updated
            save()
        }
    }

    func delete(_ keeper: Keeper) {
        keepers.removeAll { $0.id == keeper.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(keepers) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Keeper].self, from: data) {
            keepers = decoded
        }
    }
}
