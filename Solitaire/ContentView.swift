import SwiftUI
import UIKit

struct DragState {
    var cards: [Card]
    var source: Pile
    var location: CGPoint
}

private struct PileFrameKey: PreferenceKey {
    static var defaultValue: [Pile: CGRect] = [:]
    static func reduce(value: inout [Pile: CGRect], nextValue: () -> [Pile: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct ContentView: View {
    @State private var game = SolitaireGame()
    @State private var drag: DragState?
    @State private var pileFrames: [Pile: CGRect] = [:]
    @State private var confirmNewGame = false
    @State private var isSettling = false

    private var playAnimation: Animation {
        .spring(response: 0.42, dampingFraction: 0.78)
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = metrics(in: geo.size)
            ZStack(alignment: .topLeading) {
                felt.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    Spacer()
                        .frame(height: max(28, geo.size.height * 0.055))
                    VStack(spacing: 28) {
                        topRow(metrics: metrics)
                            .zIndex(20)
                        tableauRow(metrics: metrics)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 10)

                if let drag {
                    floatingStack(drag, metrics: metrics)
                }

                if game.isWon {
                    winOverlay
                }
            }
            .coordinateSpace(.named("board"))
            .onPreferenceChange(PileFrameKey.self) { pileFrames = $0 }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Start a new game?", isPresented: $confirmNewGame, titleVisibility: .visible) {
            Button("New Game", role: .destructive) {
                withAnimation(playAnimation) { game.newGame() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sensoryFeedback(.success, trigger: game.isWon)
    }

    private var felt: some View {
        LinearGradient(
            colors: [Felt.green, Felt.greenDeep],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            RadialGradient(
                colors: [Color.white.opacity(0.08), .clear],
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                if game.moves == 0 {
                    withAnimation(playAnimation) { game.newGame() }
                } else {
                    confirmNewGame = true
                }
            } label: {
                Label("New", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(playAnimation) { game.undo() }
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .disabled(!game.canUndo || game.isWon)
            .opacity(game.canUndo && !game.isWon ? 1 : 0.35)

            Spacer()

            TimelineView(.periodic(from: .now, by: 1)) { _ in
                Text(game.elapsed.clockString)
                    .monospacedDigit()
            }
            Text("·")
                .opacity(0.5)
            Text("\(game.moves)")
                .monospacedDigit()
            Text(game.moves == 1 ? "move" : "moves")
                .opacity(0.7)

            Menu {
                Button("Draw 1") {
                    withAnimation(playAnimation) { game.newGame(drawCount: 1) }
                }
                Button("Draw 3") {
                    withAnimation(playAnimation) { game.newGame(drawCount: 3) }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .accessibilityLabel("Game options")
        }
        .foregroundStyle(Felt.cream)
        .padding(.horizontal, 6)
    }

    private func topRow(metrics: CardSize) -> some View {
        HStack(alignment: .top, spacing: metrics.spacing) {
            stockPile(metrics: metrics)
            wastePile(metrics: metrics)
            Spacer(minLength: 8)
            ForEach(0..<4, id: \.self) { index in
                foundationPile(index, metrics: metrics)
            }
        }
    }

    private func tableauRow(metrics: CardSize) -> some View {
        HStack(alignment: .top, spacing: metrics.spacing) {
            ForEach(0..<7, id: \.self) { column in
                tableauColumn(column, metrics: metrics)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func stockPile(metrics: CardSize) -> some View {
        Button {
            withAnimation(playAnimation) { game.drawFromStock() }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                EmptyPileView(size: metrics, symbol: game.stock.isEmpty && !game.waste.isEmpty ? "↻" : nil)
                if let card = game.stock.last {
                    CardView(card: card, size: metrics)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(game.isWon || (game.stock.isEmpty && game.waste.isEmpty))
        .accessibilityLabel(game.stock.isEmpty ? "Recycle waste" : "Draw from stock")
        .reportFrame(.stock)
    }

    private func wastePile(metrics: CardSize) -> some View {
        let visible = Array(game.waste.suffix(game.drawCount == 3 ? 3 : 1))
        let extra = CGFloat(max(0, visible.count - 1)) * (metrics.width * 0.28)
        return ZStack(alignment: .leading) {
            EmptyPileView(size: metrics)
                .allowsHitTesting(visible.isEmpty)
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, card in
                let isTop = card.id == visible.last?.id
                let hidden = isHidden(card)
                CardView(card: card, size: metrics)
                    .opacity(hidden ? 0 : 1)
                    .allowsHitTesting(isTop && !hidden)
                    .highPriorityGesture(cardDrag(.waste, from: game.waste.count - 1, tapIfTop: isTop, metrics: metrics))
                    .offset(x: CGFloat(index) * (metrics.width * 0.28))
            }
        }
        .frame(width: metrics.width + extra, height: metrics.height, alignment: .leading)
        .zIndex(5)
        .reportFrame(.waste)
    }

    private func foundationPile(_ index: Int, metrics: CardSize) -> some View {
        let pile: Pile = .foundation(index)
        let cards = game.foundations[index]
        return ZStack {
            EmptyPileView(size: metrics, symbol: "A")
                .allowsHitTesting(cards.isEmpty)
            if let card = cards.last {
                let hidden = isHidden(card)
                CardView(card: card, size: metrics)
                    .opacity(hidden ? 0 : 1)
                    .allowsHitTesting(!hidden)
                    .highPriorityGesture(cardDrag(pile, from: cards.count - 1, tapIfTop: true, metrics: metrics))
            }
        }
        .reportFrame(pile)
    }

    private func tableauColumn(_ column: Int, metrics: CardSize) -> some View {
        let pile: Pile = .tableau(column)
        let cards = game.tableau[column]
        return VStack(spacing: 0) {
            Group {
                if cards.isEmpty {
                    EmptyPileView(size: metrics)
                } else {
                    VStack(spacing: metrics.peek - metrics.height) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                            let hidden = isHidden(card)
                            CardView(card: card, size: metrics)
                                .opacity(hidden ? 0 : 1)
                                .allowsHitTesting(!hidden)
                                .contentShape(Rectangle())
                                .highPriorityGesture(
                                    cardDrag(pile, from: index, tapIfTop: index == cards.count - 1, metrics: metrics),
                                    including: card.isFaceUp ? .all : .none
                                )
                                .zIndex(Double(index))
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: metrics.width, maxHeight: .infinity, alignment: .top)
        .reportFrame(pile)
    }

    private func floatingStack(_ drag: DragState, metrics: CardSize) -> some View {
        VStack(spacing: -metrics.height + metrics.peek) {
            ForEach(drag.cards) { card in
                CardView(card: card, size: metrics, lifted: true)
            }
        }
        .frame(width: metrics.width, alignment: .top)
        .offset(x: drag.location.x - metrics.width / 2, y: drag.location.y - 28)
        .allowsHitTesting(false)
        .zIndex(400)
        .transaction { transaction in
            if !isSettling {
                transaction.animation = nil
            }
        }
    }

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("You win")
                    .font(.largeTitle.bold())
                Text("\(game.elapsed.clockString)  ·  \(game.moves) moves")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Button("Play Again") {
                    withAnimation(playAnimation) { game.newGame() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Felt.gold)
                .foregroundStyle(.black)
                .padding(.top, 6)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(32)
        }
    }

    private func tap(_ pile: Pile) {
        guard drag == nil, !game.isWon else { return }
        var moved = false
        withAnimation(playAnimation) {
            moved = game.autoMoveTop(from: pile)
        }
        if moved {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func cardDrag(_ pile: Pile, from index: Int, tapIfTop: Bool, metrics: CardSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("board"))
            .onChanged { value in
                guard !isSettling else { return }
                let distance = hypot(value.translation.width, value.translation.height)
                guard distance >= 8 else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    if drag == nil {
                        guard let cards = game.cards(from: pile, startingAt: index) else { return }
                        drag = DragState(cards: cards, source: pile, location: value.location)
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } else if drag?.source == pile {
                        drag?.location = value.location
                    }
                }
            }
            .onEnded { value in
                if drag != nil {
                    finishDrag(at: value.location, metrics: metrics)
                } else if tapIfTop {
                    tap(pile)
                }
            }
    }

    private func finishDrag(at point: CGPoint, metrics: CardSize) {
        guard let current = drag, !isSettling else { return }
        let target = dropTarget(at: point, excluding: current.source)
        let legal = target.map { game.canDrop(current.cards, on: $0) } ?? false

        if let target, legal {
            isSettling = true
            withAnimation(playAnimation) {
                drag?.location = landingPoint(for: target, metrics: metrics)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    _ = game.move(from: current.source, count: current.cards.count, to: target)
                    drag = nil
                    isSettling = false
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        } else {
            isSettling = true
            withAnimation(playAnimation) {
                drag = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                isSettling = false
            }
            if target != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }

    private func landingPoint(for pile: Pile, metrics: CardSize) -> CGPoint {
        guard let frame = pileFrames[pile] else { return drag?.location ?? .zero }
        switch pile {
        case .tableau(let column):
            let count = game.tableau[column].count
            let top = frame.minY + CGFloat(count) * metrics.peek
            return CGPoint(x: frame.minX + metrics.width / 2, y: top + 28)
        case .foundation:
            return CGPoint(x: frame.midX, y: frame.minY + 28)
        default:
            return CGPoint(x: frame.midX, y: frame.minY + 28)
        }
    }

    private func dropTarget(at point: CGPoint, excluding source: Pile) -> Pile? {
        let foundations = (0..<4).compactMap { index -> (Pile, CGRect)? in
            let pile = Pile.foundation(index)
            guard let frame = pileFrames[pile], frame.insetBy(dx: -8, dy: -8).contains(point) else { return nil }
            return (pile, frame)
        }
        if let hit = foundations.first(where: { $0.0 != source }) {
            return hit.0
        }

        for column in 0..<7 {
            let pile = Pile.tableau(column)
            guard pile != source, let frame = pileFrames[pile] else { continue }
            if point.x >= frame.minX - 4 && point.x <= frame.maxX + 4 && point.y >= frame.minY - 8 {
                return pile
            }
        }
        return nil
    }

    private func isHidden(_ card: Card) -> Bool {
        guard let drag else { return false }
        return drag.cards.contains(where: { $0.id == card.id })
    }

    private func metrics(in size: CGSize) -> CardSize {
        let spacing: CGFloat = size.width < 380 ? 3 : 5
        let width = min(92, (size.width - 12 - spacing * 6) / 7)
        let height = width * 1.48
        let topReserve = max(28, size.height * 0.055) + 52 + height + 28
        let tableauHeight = max(140, size.height - topReserve - 16)
        let peek = max(20, min(32, (tableauHeight - height) / 15))
        return CardSize(width: width, height: height, peek: peek, spacing: spacing)
    }
}

private extension View {
    func reportFrame(_ pile: Pile) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: PileFrameKey.self,
                    value: [pile: proxy.frame(in: .named("board"))]
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
