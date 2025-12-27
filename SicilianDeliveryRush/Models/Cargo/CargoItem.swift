import Foundation

struct CargoItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: CargoType
    var isLost: Bool = false
    var condition: Float = 1.0

    var pointValue: Int {
        Int(Float(type.pointValue) * condition)
    }

    var weight: Float {
        type.weight
    }

    var fragility: Float {
        type.fragility
    }

    var displayName: String {
        type.displayName
    }

    init(type: CargoType) {
        self.id = UUID()
        self.type = type
    }

    mutating func applyDamage(_ amount: Float) {
        condition = max(0, condition - amount)
    }

    static func == (lhs: CargoItem, rhs: CargoItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct CargoContainer {
    private(set) var items: [CargoItem] = []
    let maxCapacity: Int

    var count: Int { items.count }
    var isEmpty: Bool { items.isEmpty }
    var isFull: Bool { items.count >= maxCapacity }

    var totalWeight: Float {
        items.reduce(0) { $0 + $1.weight }
    }

    var totalValue: Int {
        items.reduce(0) { $0 + $1.pointValue }
    }

    var lostItems: [CargoItem] {
        items.filter { $0.isLost }
    }

    var intactItems: [CargoItem] {
        items.filter { !$0.isLost }
    }

    init(capacity: Int) {
        self.maxCapacity = capacity
    }

    mutating func add(_ item: CargoItem) -> Bool {
        guard !isFull else { return false }
        items.append(item)
        return true
    }

    mutating func remove(_ item: CargoItem) -> CargoItem? {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return nil
        }
        return items.remove(at: index)
    }

    mutating func markAsLost(_ itemId: UUID) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].isLost = true
        }
    }

    mutating func clear() {
        items.removeAll()
    }
}
