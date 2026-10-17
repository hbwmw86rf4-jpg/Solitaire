import Foundation

struct GameScore: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var points: Int
    var elapsed: TimeInterval
    var moves: Int
    var date: Date
    var drawCount: Int

    init(
        id: UUID = UUID(),
        points: Int,
        elapsed: TimeInterval,
        moves: Int,
        date: Date = Date(),
        drawCount: Int
    ) {
        self.id = id
        self.points = points
        self.elapsed = elapsed
        self.moves = moves
        self.date = date
        self.drawCount = drawCount
    }
}

enum ScoreBoard: String, CaseIterable, Identifiable {
    case allTime
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allTime: "Best"
        case .weekly: "Week"
        case .monthly: "Month"
        }
    }
}

@MainActor
@Observable
final class ScoreStore {
    private(set) var scores: [GameScore] = []
    private let key = "solitaire.scores.v1"
    private let limit = 50

    init() {
        load()
    }

    func record(_ score: GameScore) {
        scores.append(score)
        scores.sort { lhs, rhs in
            if lhs.points != rhs.points { return lhs.points > rhs.points }
            if lhs.elapsed != rhs.elapsed { return lhs.elapsed < rhs.elapsed }
            return lhs.date > rhs.date
        }
        if scores.count > limit {
            scores = Array(scores.prefix(limit))
        }
        save()
    }

    func top10(on board: ScoreBoard, now: Date = Date()) -> [GameScore] {
        filtered(on: board, now: now).prefix(10).map { $0 }
    }

    func rank(of score: GameScore, on board: ScoreBoard, now: Date = Date()) -> Int? {
        let list = top10(on: board, now: now)
        return list.firstIndex(where: { $0.id == score.id }).map { $0 + 1 }
    }

    func best(on board: ScoreBoard, now: Date = Date()) -> GameScore? {
        top10(on: board, now: now).first
    }

    private func filtered(on board: ScoreBoard, now: Date) -> [GameScore] {
        let calendar = Calendar.current
        switch board {
        case .allTime:
            return scores
        case .weekly:
            guard let start = calendar.date(byAdding: .day, value: -7, to: now) else { return scores }
            return scores.filter { $0.date >= start }
        case .monthly:
            let comps = calendar.dateComponents([.year, .month], from: now)
            guard let start = calendar.date(from: comps) else { return scores }
            return scores.filter { $0.date >= start }
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        scores = (try? JSONDecoder().decode([GameScore].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(scores) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
