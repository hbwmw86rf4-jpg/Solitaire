import Foundation
import SwiftUI

enum Suit: Int, CaseIterable, Codable, Sendable {
    case spades, hearts, diamonds, clubs

    var isRed: Bool { self == .hearts || self == .diamonds }

    var symbol: String {
        switch self {
        case .spades: "♠"
        case .hearts: "♥"
        case .diamonds: "♦"
        case .clubs: "♣"
        }
    }

    var name: String {
        switch self {
        case .spades: "spades"
        case .hearts: "hearts"
        case .diamonds: "diamonds"
        case .clubs: "clubs"
        }
    }
}

enum Rank: Int, CaseIterable, Codable, Comparable, Sendable {
    case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    var display: String {
        switch self {
        case .ace: "A"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        default: String(rawValue)
        }
    }

    var name: String {
        switch self {
        case .ace: "ace"
        case .jack: "jack"
        case .queen: "queen"
        case .king: "king"
        default: String(rawValue)
        }
    }
}

struct Card: Identifiable, Equatable, Hashable, Codable, Sendable {
    let id: UUID
    let suit: Suit
    let rank: Rank
    var isFaceUp: Bool

    static func == (lhs: Card, rhs: Card) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var accessibilityLabel: String {
        if isFaceUp {
            "\(rank.name) of \(suit.name)"
        } else {
            "face down card"
        }
    }
}

enum Pile: Hashable, Sendable {
    case stock
    case waste
    case foundation(Int)
    case tableau(Int)
}

struct GameSnapshot {
    var stock: [Card]
    var waste: [Card]
    var foundations: [[Card]]
    var tableau: [[Card]]
    var moves: Int
    var baseScore: Int
    var lastDelta: Int
}

@MainActor
@Observable
final class SolitaireGame {
    var stock: [Card] = []
    var waste: [Card] = []
    var foundations: [[Card]] = [[], [], [], []]
    var tableau: [[Card]] = Array(repeating: [], count: 7)
    var moves = 0
    var drawCount = 1
    var startDate = Date()
    var winDate: Date?
    var isWon = false
    var dealGeneration = 0
    var baseScore = 0
    var lastDelta = 0
    var finalScore: Int?

    private var history: [GameSnapshot] = []

    var canUndo: Bool { !history.isEmpty && !isWon }

    var elapsed: TimeInterval {
        (winDate ?? Date()).timeIntervalSince(startDate)
    }

    var timePenalty: Int {
        let extra = max(0, elapsed - 30)
        return Int(extra / 10) * 2
    }

    var timeBonus: Int {
        guard isWon else { return 0 }
        return max(0, 500 - Int(elapsed) * 2)
    }

    var currentScore: Int {
        if let finalScore { return finalScore }
        return max(0, baseScore - timePenalty)
    }

    var allTableauRevealed: Bool {
        tableau.allSatisfy { $0.allSatisfy(\.isFaceUp) }
    }

    var canAutoFinish: Bool {
        !isWon && stock.isEmpty && allTableauRevealed && simulatedFoundationWin()
    }

    init() {
        deal()
    }

    func newGame(drawCount newDrawCount: Int? = nil) {
        if let newDrawCount {
            drawCount = newDrawCount
        }
        history.removeAll()
        moves = 0
        baseScore = 0
        lastDelta = 0
        finalScore = nil
        isWon = false
        winDate = nil
        startDate = Date()
        dealGeneration += 1
        deal()
    }

    func undo() {
        guard let snapshot = history.popLast() else { return }
        apply(snapshot)
        isWon = false
        winDate = nil
        finalScore = nil
    }

    func drawFromStock() {
        guard !isWon else { return }
        if stock.isEmpty {
            guard !waste.isEmpty else { return }
            pushUndo()
            stock = waste.reversed().map { card in
                var copy = card
                copy.isFaceUp = false
                return copy
            }
            waste.removeAll()
            if drawCount == 3 {
                applyScore(-20)
            } else {
                lastDelta = 0
            }
            moves += 1
            return
        }

        pushUndo()
        let n = min(drawCount, stock.count)
        for _ in 0..<n {
            var card = stock.removeLast()
            card.isFaceUp = true
            waste.append(card)
        }
        moves += 1
    }

    func cards(from pile: Pile, startingAt index: Int) -> [Card]? {
        switch pile {
        case .tableau(let column):
            guard tableau.indices.contains(column), tableau[column].indices.contains(index) else { return nil }
            let slice = Array(tableau[column][index...])
            return isValidTableauRun(slice) ? slice : nil
        case .waste:
            guard index == waste.count - 1, let card = waste.last, card.isFaceUp else { return nil }
            return [card]
        case .foundation(let i):
            guard foundations.indices.contains(i),
                  index == foundations[i].count - 1,
                  let card = foundations[i].last
            else { return nil }
            return [card]
        case .stock:
            return nil
        }
    }

    func canDrop(_ cards: [Card], on pile: Pile) -> Bool {
        guard let first = cards.first else { return false }
        switch pile {
        case .stock, .waste:
            return false
        case .foundation(let i):
            guard cards.count == 1, foundations.indices.contains(i) else { return false }
            let dest = foundations[i]
            if dest.isEmpty { return first.rank == .ace }
            guard let top = dest.last else { return false }
            return top.suit == first.suit && first.rank.rawValue == top.rank.rawValue + 1
        case .tableau(let column):
            guard tableau.indices.contains(column) else { return false }
            let dest = tableau[column]
            if dest.isEmpty { return first.rank == .king }
            guard let top = dest.last, top.isFaceUp else { return false }
            return top.suit.isRed != first.suit.isRed && first.rank.rawValue == top.rank.rawValue - 1
        }
    }

    @discardableResult
    func move(from source: Pile, count: Int, to dest: Pile, recordUndo: Bool = true) -> Bool {
        guard !isWon, source != dest, count > 0 else { return false }
        guard let moving = peek(from: source, count: count), canDrop(moving, on: dest) else { return false }
        let willFlip = willFlipExposed(in: source, count: count)
        if recordUndo { pushUndo() }
        _ = pop(from: source, count: count)
        append(moving, to: dest)
        flipExposed(in: source)
        scoreMove(from: source, to: dest, flipped: willFlip)
        moves += 1
        checkWin()
        return true
    }

    func suggestedMove(from pile: Pile, count: Int) -> Pile? {
        guard count > 0, let cards = peek(from: pile, count: count) else { return nil }
        if count == 1 {
            for i in 0..<4 where canDrop(cards, on: .foundation(i)) {
                return .foundation(i)
            }
        }
        for column in 0..<7 {
            let dest = Pile.tableau(column)
            if dest != pile, canDrop(cards, on: dest) {
                return dest
            }
        }
        return nil
    }

    @discardableResult
    func autoMove(from pile: Pile, count: Int) -> Bool {
        guard count > 0, let cards = peek(from: pile, count: count) else { return false }
        if count == 1 {
            for i in 0..<4 {
                if canDrop(cards, on: .foundation(i)) {
                    return move(from: pile, count: 1, to: .foundation(i))
                }
            }
        }
        for column in 0..<7 {
            let dest = Pile.tableau(column)
            if dest != pile, canDrop(cards, on: dest) {
                return move(from: pile, count: count, to: dest)
            }
        }
        return false
    }

    func nextFoundationMove() -> (Pile, Pile)? {
        if let card = waste.last {
            for i in 0..<4 where canDrop([card], on: .foundation(i)) {
                return (.waste, .foundation(i))
            }
        }
        for column in 0..<7 {
            guard let card = tableau[column].last else { continue }
            for i in 0..<4 where canDrop([card], on: .foundation(i)) {
                return (.tableau(column), .foundation(i))
            }
        }
        return nil
    }

    func beginAutoFinish() {
        guard canAutoFinish else { return }
        pushUndo()
    }

    @discardableResult
    func applyNextAutoFinishStep() -> Bool {
        guard let (source, dest) = nextFoundationMove() else { return false }
        return move(from: source, count: 1, to: dest, recordUndo: false)
    }

    func topCard(of pile: Pile) -> Card? {
        switch pile {
        case .stock: stock.last
        case .waste: waste.last
        case .foundation(let i): foundations[i].last
        case .tableau(let column): tableau[column].last
        }
    }

    func isHiddenByDrag(_ card: Card, dragIDs: Set<UUID>) -> Bool {
        dragIDs.contains(card.id)
    }

    private func deal() {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(id: UUID(), suit: suit, rank: rank, isFaceUp: false))
            }
        }
        deck.shuffle()

        foundations = [[], [], [], []]
        tableau = Array(repeating: [], count: 7)
        for column in 0..<7 {
            for row in 0...column {
                var card = deck.removeLast()
                card.isFaceUp = row == column
                tableau[column].append(card)
            }
        }
        stock = deck
        waste = []
    }

    private func isValidTableauRun(_ cards: [Card]) -> Bool {
        guard !cards.isEmpty, cards.allSatisfy(\.isFaceUp) else { return false }
        for i in 1..<cards.count {
            let upper = cards[i - 1]
            let lower = cards[i]
            if upper.suit.isRed == lower.suit.isRed { return false }
            if upper.rank.rawValue != lower.rank.rawValue + 1 { return false }
        }
        return true
    }

    private func peek(from pile: Pile, count: Int) -> [Card]? {
        switch pile {
        case .waste:
            guard count == 1, let card = waste.last else { return nil }
            return [card]
        case .foundation(let i):
            guard count == 1, let card = foundations[i].last else { return nil }
            return [card]
        case .tableau(let column):
            guard tableau[column].count >= count else { return nil }
            let slice = Array(tableau[column].suffix(count))
            return isValidTableauRun(slice) ? slice : nil
        case .stock:
            return nil
        }
    }

    private func pop(from pile: Pile, count: Int) -> [Card] {
        switch pile {
        case .waste:
            return [waste.removeLast()]
        case .foundation(let i):
            return [foundations[i].removeLast()]
        case .tableau(let column):
            let index = tableau[column].count - count
            let cards = Array(tableau[column][index...])
            tableau[column].removeSubrange(index...)
            return cards
        case .stock:
            return []
        }
    }

    private func append(_ cards: [Card], to pile: Pile) {
        switch pile {
        case .waste:
            waste.append(contentsOf: cards)
        case .foundation(let i):
            foundations[i].append(contentsOf: cards)
        case .tableau(let column):
            tableau[column].append(contentsOf: cards)
        case .stock:
            stock.append(contentsOf: cards)
        }
    }

    private func willFlipExposed(in pile: Pile, count: Int) -> Bool {
        guard case .tableau(let column) = pile else { return false }
        let remaining = tableau[column].count - count
        guard remaining > 0 else { return false }
        return !tableau[column][remaining - 1].isFaceUp
    }

    private func flipExposed(in pile: Pile) {
        guard case .tableau(let column) = pile, var last = tableau[column].last, !last.isFaceUp else { return }
        last.isFaceUp = true
        tableau[column][tableau[column].count - 1] = last
    }

    private func scoreMove(from source: Pile, to dest: Pile, flipped: Bool) {
        var delta = 0
        switch dest {
        case .foundation:
            delta += 10
        case .tableau:
            switch source {
            case .waste: delta += 5
            case .foundation: delta -= 15
            default: break
            }
        default:
            break
        }
        if flipped { delta += 5 }
        applyScore(delta)
    }

    private func applyScore(_ delta: Int) {
        lastDelta = delta
        baseScore = max(0, baseScore + delta)
    }

    private func checkWin() {
        if foundations.allSatisfy({ $0.count == 13 }) {
            isWon = true
            winDate = Date()
            finalScore = max(0, baseScore - timePenalty) + timeBonus
        }
    }

    private func pushUndo() {
        history.append(
            GameSnapshot(
                stock: stock,
                waste: waste,
                foundations: foundations,
                tableau: tableau,
                moves: moves,
                baseScore: baseScore,
                lastDelta: lastDelta
            )
        )
        if history.count > 80 {
            history.removeFirst()
        }
    }

    private func apply(_ snapshot: GameSnapshot) {
        stock = snapshot.stock
        waste = snapshot.waste
        foundations = snapshot.foundations
        tableau = snapshot.tableau
        moves = snapshot.moves
        baseScore = snapshot.baseScore
        lastDelta = snapshot.lastDelta
    }

    private func simulatedFoundationWin() -> Bool {
        var waste = waste
        var tableau = tableau
        var foundations = foundations

        func foundationIndex(for card: Card) -> Int? {
            for i in 0..<4 {
                let dest = foundations[i]
                if dest.isEmpty { if card.rank == .ace { return i } }
                else if let top = dest.last,
                        top.suit == card.suit,
                        card.rank.rawValue == top.rank.rawValue + 1 {
                    return i
                }
            }
            return nil
        }

        while true {
            if let card = waste.last, let i = foundationIndex(for: card) {
                waste.removeLast()
                foundations[i].append(card)
                continue
            }
            var moved = false
            for column in 0..<7 {
                guard let card = tableau[column].last, let i = foundationIndex(for: card) else { continue }
                tableau[column].removeLast()
                foundations[i].append(card)
                moved = true
                break
            }
            if moved { continue }
            break
        }

        return foundations.allSatisfy { $0.count == 13 }
    }
}

extension TimeInterval {
    var clockString: String {
        let total = max(0, Int(self))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
