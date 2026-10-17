import SwiftUI
import UIKit

private struct PileFrameKey: PreferenceKey {
    static var defaultValue: [Pile: CGRect] = [:]
    static func reduce(value: inout [Pile: CGRect], nextValue: () -> [Pile: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct ActiveDrag: Equatable {
    var cards: [Card]
    var source: Pile
    var sourceIndex: Int
    var grabOffset: CGSize
    var location: CGPoint
}

private struct ScoreBurst: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var point: CGPoint
}

/// Where a single card is drawn on the board. Every card lives in one layer,
/// so any change to the game state animates each card from where it was to where it is now.
private struct Placement {
    var card: Card
    var origin: CGPoint
    var z: Double
    var faceUp: Bool
    var lifted = false
    var rotation: Double = 0
}

struct ContentView: View {
    @State private var game = SolitaireGame()
    @State private var scores = ScoreStore()
    @State private var pileFrames: [Pile: CGRect] = [:]
    @State private var boardSize: CGSize = .zero
    @State private var confirmNewGame = false
    @State private var showScores = false
    @State private var activeDrag: ActiveDrag?
    @State private var isAutoFinishing = false
    @State private var isDealing = false
    @State private var needsInitialDeal = true
    @State private var animateFrames = false
    @State private var pendingDeal: Set<UUID> = []
    @State private var gathering = false
    @State private var celebrating = false
    @State private var showWinPanel = false
    @State private var raised: [UUID: Int] = [:]
    @State private var flightSeq = 0
    @State private var recordedWinID: UUID?
    @State private var bursts: [ScoreBurst] = []
    @AppStorage("leftHandedLayout") private var leftHanded = false
    @AppStorage("tableTheme") private var tableTheme: TableTheme = .green
    @AppStorage("cardBackTheme") private var cardBackTheme: CardBackTheme = .crimson
    @AppStorage("faceTheme") private var faceTheme: FaceTheme = .classic
    @State private var showAppearance = false
    @GestureState private var isTouching = false

    var body: some View {
        GeometryReader { geo in
            let metrics = metrics(in: geo.size)
            ZStack(alignment: .topLeading) {
                FeltBackground(theme: tableTheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    PileSlots(
                        metrics: metrics,
                        leftHanded: leftHanded,
                        drawCount: game.drawCount,
                        showRecycle: game.stock.isEmpty && !game.waste.isEmpty
                    )
                    .equatable()
                    .padding(.top, 8)
                    .contentShape(Rectangle())
                    .gesture(boardDrag(metrics: metrics))
                    .simultaneousGesture(doubleTap(metrics: metrics))
                    .simultaneousGesture(stockTap())
                }
                .padding(.horizontal, 5)
                .padding(.top, 6)
                .padding(.bottom, 10)

                if let pile = hoverPile(), let frame = pileFrames[pile] {
                    RoundedRectangle(cornerRadius: metrics.corner, style: .continuous)
                        .strokeBorder(Felt.gold, lineWidth: 2.5)
                        .shadow(color: Felt.gold.opacity(0.8), radius: 8)
                        .frame(width: frame.width, height: min(frame.height, metrics.height + 8))
                        .offset(x: frame.minX, y: frame.minY)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                cardLayer(metrics: metrics)

                ForEach(bursts) { burst in
                    BurstLabel(text: burst.text)
                        .position(burst.point)
                        .allowsHitTesting(false)
                }

                if showWinPanel {
                    winOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }
            }
            .coordinateSpace(.named("board"))
            .onPreferenceChange(PileFrameKey.self) { frames in
                pileFrames = frames
                if needsInitialDeal, frames[.stock] != nil {
                    needsInitialDeal = false
                    Task { await dealIn() }
                }
            }
            .onAppear {
                boardSize = geo.size
                if needsInitialDeal {
                    pendingDeal = Set(game.tableau.flatMap { $0.map(\.id) })
                }
            }
            .onChange(of: geo.size) { _, size in boardSize = size }
            .onChange(of: isTouching) { _, touching in
                guard !touching else { return }
                // A cancelled drag never reaches onEnded; send the cards home instead of leaving them floating.
                DispatchQueue.main.async {
                    if activeDrag != nil {
                        animated(.cardSnap) { activeDrag = nil }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.cardStyle, CardStyle(back: cardBackTheme, face: faceTheme))
        .sheet(isPresented: $showScores) {
            ScoresView(store: scores)
        }
        .sheet(isPresented: $showAppearance) {
            AppearanceView(table: $tableTheme, back: $cardBackTheme, face: $faceTheme, leftHanded: $leftHanded)
        }
        .confirmationDialog("Start a new game?", isPresented: $confirmNewGame, titleVisibility: .visible) {
            Button("New Game", role: .destructive) { startNewGame() }
            Button("Cancel", role: .cancel) {}
        }
        .sensoryFeedback(.success, trigger: game.isWon)
        .onChange(of: game.isWon) { _, won in
            guard won else { return }
            recordWinIfNeeded()
            Task { await celebrate() }
        }
    }

    // MARK: - Card layer

    private func cardLayer(metrics: CardSize) -> some View {
        let placements = layout(metrics: metrics)
        return ZStack(alignment: .topLeading) {
            ForEach(Array(placements.enumerated()), id: \.element.card.id) { order, p in
                CardView(card: p.card, size: metrics, faceUp: p.faceUp, lifted: p.lifted)
                    .rotationEffect(.degrees(p.rotation))
                    .offset(x: p.origin.x, y: p.origin.y)
                    .zIndex(p.z)
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.72).delay(Double(order) * 0.012),
                        value: celebrating
                    )
            }
        }
        .animation(animateFrames ? .cardMove : nil, value: pileFrames)
        .opacity(pileFrames[.stock] == nil ? 0 : 1)
        .allowsHitTesting(false)
    }

    private func layout(metrics: CardSize) -> [Placement] {
        var result: [Placement] = []
        result.reserveCapacity(52)
        let stockOrigin = pileFrames[.stock]?.origin ?? .zero

        func stockSpot(_ i: Int) -> CGPoint {
            let depth = CGFloat(min(i, 24)) * 0.12
            return CGPoint(x: stockOrigin.x - depth, y: stockOrigin.y - depth)
        }

        func add(_ card: Card, _ origin: CGPoint, _ z: Double, faceUp: Bool? = nil) {
            if gathering {
                result.append(Placement(card: card, origin: stockSpot(0), z: z, faceUp: false))
            } else if let seq = raised[card.id] {
                result.append(Placement(card: card, origin: origin, z: 10_000 + Double(seq) * 100 + z / 10, faceUp: faceUp ?? card.isFaceUp))
            } else {
                result.append(Placement(card: card, origin: origin, z: z, faceUp: faceUp ?? card.isFaceUp))
            }
        }

        for (i, card) in game.stock.enumerated() {
            add(card, stockSpot(i), 100 + Double(i))
        }

        let visible = min(game.drawCount == 3 ? 3 : 1, game.waste.count)
        for (i, card) in game.waste.enumerated() {
            let fromTop = game.waste.count - 1 - i
            add(card, wasteOrigin(fanSlot: min(fromTop, max(0, visible - 1)), visible: visible, metrics: metrics), 200 + Double(i))
        }

        for f in 0..<4 {
            let origin = pileFrames[.foundation(f)]?.origin ?? .zero
            for (i, card) in game.foundations[f].enumerated() {
                add(card, origin, 300 + Double(i))
            }
        }

        var dealOrder = 0
        for column in 0..<7 {
            let frame = pileFrames[.tableau(column)] ?? .zero
            let cards = game.tableau[column]
            for (i, card) in cards.enumerated() {
                if pendingDeal.contains(card.id) {
                    dealOrder += 1
                    add(card, stockSpot(game.stock.count), 160 + Double(dealOrder), faceUp: false)
                } else {
                    add(card, CGPoint(x: frame.minX, y: frame.minY + metrics.stackOffset(at: i, in: cards)), 400 + Double(i))
                }
            }
        }

        if let drag = activeDrag {
            let peek: CGFloat = {
                if case .tableau(let column) = drag.source { return metrics.peeks(for: game.tableau[column]).face }
                return metrics.facePeek
            }()
            for (k, card) in drag.cards.enumerated() {
                guard let idx = result.firstIndex(where: { $0.card.id == card.id }) else { continue }
                result[idx].origin = CGPoint(x: drag.location.x, y: drag.location.y + CGFloat(k) * peek)
                result[idx].z = 1_000_000 + Double(k)
                result[idx].lifted = true
            }
        }

        if celebrating {
            let center = CGPoint(x: boardSize.width / 2, y: boardSize.height / 2)
            let radius = min(boardSize.width, boardSize.height) * 0.30
            for i in result.indices {
                let angle = Double(i) / Double(result.count) * 2 * .pi - .pi / 2
                result[i].origin = CGPoint(
                    x: center.x + radius * cos(angle) - metrics.width / 2,
                    y: center.y + radius * sin(angle) - metrics.height / 2
                )
                result[i].rotation = angle * 180 / .pi + 90
                result[i].faceUp = true
                result[i].z = Double(i)
            }
        }
        return result
    }

    /// `fanSlot` counts from the top card (0) down into the fan.
    private func wasteOrigin(fanSlot: Int, visible: Int, metrics: CardSize) -> CGPoint {
        guard let frame = pileFrames[.waste] else { return .zero }
        if leftHanded {
            let position = max(0, visible - 1 - fanSlot)
            return CGPoint(x: frame.minX + CGFloat(position) * metrics.fanStep, y: frame.minY)
        }
        return CGPoint(x: frame.maxX - metrics.width - CGFloat(fanSlot) * metrics.fanStep, y: frame.minY)
    }

    /// Runs a state change so that every card whose position changes glides there
    /// and stays above the rest of the board until it lands.
    private func animated(_ animation: Animation = .cardMove, _ change: () -> Void) {
        let metrics = metrics(in: boardSize)
        var before: [UUID: CGPoint] = [:]
        for p in layout(metrics: metrics) { before[p.card.id] = p.origin }
        flightSeq += 1
        let seq = flightSeq
        var moved: [UUID] = []
        withAnimation(animation) {
            change()
            for p in layout(metrics: metrics) where before[p.card.id] != p.origin {
                moved.append(p.card.id)
                raised[p.card.id] = seq
            }
        } completion: {
            for id in moved where raised[id] == seq {
                raised.removeValue(forKey: id)
            }
        }
    }

    // MARK: - Header

    /// Narrow screens (a phone held upright) get icon-only buttons so nothing wraps.
    private var compactHeader: Bool { boardSize.width < 560 }

    private var header: some View {
        HStack(spacing: compactHeader ? 6 : 8) {
            headerButton("New", systemImage: "arrow.counterclockwise") {
                if game.moves == 0 || game.isWon {
                    startNewGame()
                } else {
                    confirmNewGame = true
                }
            }

            headerButton("Undo", systemImage: "arrow.uturn.backward") {
                animated { game.undo() }
            }
            .disabled(!game.canUndo || isBusy)
            .opacity(game.canUndo && !isBusy ? 1 : 0.38)

            if game.canAutoFinish && !game.isWon {
                Button {
                    Task { await runAutoFinish() }
                } label: {
                    Group {
                        if compactHeader {
                            Image(systemName: "sparkles")
                                .frame(width: 36, height: 36)
                                .background(Felt.gold.gradient, in: Circle())
                        } else {
                            Label("Finish", systemImage: "sparkles")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Felt.gold.gradient, in: Capsule())
                        }
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .shadow(color: Felt.gold.opacity(0.5), radius: 6)
                }
                .buttonStyle(PressableStyle())
                .disabled(isAutoFinishing)
                .accessibilityLabel("Finish")
                .transition(.scale.combined(with: .opacity))
            }

            Spacer(minLength: 4)

            statsCapsule

            Button {
                showScores = true
            } label: {
                Image(systemName: "trophy.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Felt.gold)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("High scores")

            Menu {
                Section("New game") {
                    Button("Draw 1") { startNewGame(drawCount: 1) }
                    Button("Draw 3") { startNewGame(drawCount: 3) }
                }
                Button {
                    showAppearance = true
                } label: {
                    Label("Appearance…", systemImage: "paintpalette")
                }
                Toggle("Left-Handed Layout", isOn: $leftHanded)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.bold))
                    .foregroundStyle(Felt.cream)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Game options")
        }
        .padding(.horizontal, 4)
        .frame(height: 40)
        .animation(.cardSnap, value: game.canAutoFinish)
    }

    private var isBusy: Bool { isAutoFinishing || isDealing }

    private func headerButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if compactHeader {
                    Image(systemName: systemImage)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                } else {
                    Label(title, systemImage: systemImage)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Felt.cream)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(title)
    }

    private var statsCapsule: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            HStack(spacing: compactHeader ? 8 : 10) {
                labeledStat("Score", value: "\(game.currentScore)")
                divider
                labeledStat("Time", value: game.elapsed.clockString)
                divider
                labeledStat("Moves", value: "\(game.moves)")
            }
            .padding(.horizontal, compactHeader ? 10 : 12)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .fixedSize()
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Felt.cream.opacity(0.22))
            .frame(width: 1, height: 14)
    }

    private func labeledStat(_ title: String, value: String) -> some View {
        VStack(spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(Felt.cream.opacity(0.55))
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(Felt.cream)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
    }

    // MARK: - Win

    private var winOverlay: some View {
        let recorded = scores.scores.first(where: { $0.id == recordedWinID })
        let rank = recorded.flatMap { scores.rank(of: $0, on: .allTime) }
        return VStack(spacing: 16) {
            Text("You win")
                .font(.system(.largeTitle, design: .serif).bold())
                .foregroundStyle(Felt.cream)
            if let rank {
                Text(rank == 1 ? "New best score" : "Top 10  ·  #\(rank)")
                    .font(.headline)
                    .foregroundStyle(Felt.gold)
            }
            HStack(spacing: 18) {
                winStat("Score", "\(game.currentScore)")
                winStat("Time", game.elapsed.clockString)
                winStat("Moves", "\(game.moves)")
            }
            HStack(spacing: 10) {
                Button("Scores") { showScores = true }
                    .buttonStyle(.bordered)
                    .tint(Felt.cream)
                Button("Play Again") { startNewGame() }
                    .buttonStyle(.borderedProminent)
                    .tint(Felt.gold)
                    .foregroundStyle(.black)
            }
            .padding(.top, 4)
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 30, y: 12)
        .frame(width: boardSize.width, height: boardSize.height)
        .zIndex(2_000_000)
    }

    private func winStat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
        }
        .frame(minWidth: 72)
    }

    private func celebrate() async {
        try? await Task.sleep(for: .milliseconds(450))
        guard game.isWon else { return }
        celebrating = true
        try? await Task.sleep(for: .milliseconds(900))
        guard game.isWon else { return }
        withAnimation(.cardSnap) { showWinPanel = true }
    }

    // MARK: - Gestures

    private func boardDrag(metrics: CardSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("board"))
            .updating($isTouching) { _, state, _ in state = true }
            .onChanged { value in
                guard !isBusy, !game.isWon else { return }
                if activeDrag == nil {
                    guard let pick = pickCard(at: value.startLocation, metrics: metrics) else { return }
                    guard let cards = game.cards(from: pick.pile, startingAt: pick.index) else { return }
                    let origin = cardOrigin(pile: pick.pile, index: pick.index, metrics: metrics)
                    let grab = CGSize(width: value.startLocation.x - origin.x, height: value.startLocation.y - origin.y)
                    // Pick up with a quick spring so the stack visibly lifts under the finger.
                    withAnimation(.cardSnap) {
                        activeDrag = ActiveDrag(
                            cards: cards,
                            source: pick.pile,
                            sourceIndex: pick.index,
                            grabOffset: grab,
                            location: CGPoint(x: value.location.x - grab.width, y: value.location.y - grab.height)
                        )
                    }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } else if var drag = activeDrag {
                    drag.location = CGPoint(
                        x: value.location.x - drag.grabOffset.width,
                        y: value.location.y - drag.grabOffset.height
                    )
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { activeDrag = drag }
                }
            }
            .onEnded { value in
                finishDrag(at: value.location, metrics: metrics)
            }
    }

    private func stockTap() -> some Gesture {
        SpatialTapGesture(count: 1, coordinateSpace: .named("board"))
            .onEnded { event in
                guard activeDrag == nil, !isBusy, !game.isWon else { return }
                guard let frame = pileFrames[.stock], expanded(frame).contains(event.location) else { return }
                animated { game.drawFromStock() }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if game.lastDelta != 0, let frame = pileFrames[.waste] {
                    spawnBurst(at: CGPoint(x: frame.midX, y: frame.minY), delta: game.lastDelta)
                }
            }
    }

    private func doubleTap(metrics: CardSize) -> some Gesture {
        SpatialTapGesture(count: 2, coordinateSpace: .named("board"))
            .onEnded { event in
                guard activeDrag == nil, !isBusy, !game.isWon else { return }
                guard let pick = pickCard(at: event.location, metrics: metrics) else { return }
                let count: Int = {
                    if case .tableau(let column) = pick.pile {
                        return game.tableau[column].count - pick.index
                    }
                    return 1
                }()
                guard let dest = game.suggestedMove(from: pick.pile, count: count) else { return }
                performMove(from: pick.pile, count: count, to: dest, metrics: metrics)
            }
    }

    private func finishDrag(at point: CGPoint, metrics: CardSize) {
        guard let drag = activeDrag else { return }
        let target = dropTarget(at: point, excluding: drag.source)
        let legal = target.map { game.canDrop(drag.cards, on: $0) } ?? false

        if let target, legal {
            performMove(from: drag.source, count: drag.cards.count, to: target, metrics: metrics) {
                activeDrag = nil
            }
        } else {
            animated(.cardSnap) { activeDrag = nil }
            if target != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }

    private func performMove(from source: Pile, count: Int, to dest: Pile, metrics: CardSize, alongside: () -> Void = {}) {
        let landing = cardOrigin(pile: dest, index: destinationIndex(for: dest), metrics: metrics)
        var moved = false
        animated {
            moved = game.move(from: source, count: count, to: dest)
            alongside()
        }
        if moved {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            spawnBurst(at: CGPoint(x: landing.x + metrics.width / 2, y: landing.y), delta: game.lastDelta)
        }
    }

    private func runAutoFinish() async {
        guard game.canAutoFinish else { return }
        isAutoFinishing = true
        game.beginAutoFinish()
        while !game.isWon {
            guard let (source, dest) = game.nextFoundationMove() else { break }
            animated(.cardDeal) { _ = game.move(from: source, count: 1, to: dest, recordUndo: false) }
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
            try? await Task.sleep(for: .milliseconds(85))
        }
        isAutoFinishing = false
    }

    // MARK: - Dealing

    private func dealIn() async {
        isDealing = true
        try? await Task.sleep(for: .milliseconds(150))
        animateFrames = true
        for row in 0..<7 {
            for column in row..<7 {
                guard game.tableau[column].indices.contains(row) else { continue }
                let id = game.tableau[column][row].id
                animated(.cardDeal) { _ = pendingDeal.remove(id) }
                try? await Task.sleep(for: .milliseconds(40))
            }
        }
        pendingDeal.removeAll()
        try? await Task.sleep(for: .milliseconds(250))
        isDealing = false
    }

    private func startNewGame(drawCount: Int? = nil) {
        guard !isDealing else { return }
        Task {
            isDealing = true
            withAnimation(.easeOut(duration: 0.2)) { showWinPanel = false }
            bursts.removeAll()
            activeDrag = nil
            if celebrating || game.moves > 0 {
                animated(.cardMove) {
                    celebrating = false
                    gathering = true
                }
                try? await Task.sleep(for: .milliseconds(380))
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                recordedWinID = nil
                celebrating = false
                game.newGame(drawCount: drawCount)
                pendingDeal = Set(game.tableau.flatMap { $0.map(\.id) })
                gathering = false
                raised.removeAll()
            }
            await dealIn()
        }
    }

    private func recordWinIfNeeded() {
        guard recordedWinID == nil else { return }
        let entry = GameScore(
            points: game.currentScore,
            elapsed: game.elapsed,
            moves: game.moves,
            drawCount: game.drawCount
        )
        recordedWinID = entry.id
        scores.record(entry)
    }

    private func spawnBurst(at point: CGPoint, delta: Int) {
        guard delta != 0 else { return }
        let burst = ScoreBurst(text: delta > 0 ? "+\(delta)" : "\(delta)", point: point)
        bursts.append(burst)
        Task {
            try? await Task.sleep(for: .milliseconds(1000))
            bursts.removeAll { $0.id == burst.id }
        }
    }

    // MARK: - Hit testing

    private func hoverPile() -> Pile? {
        guard let drag = activeDrag else { return nil }
        let point = CGPoint(x: drag.location.x + drag.grabOffset.width, y: drag.location.y + drag.grabOffset.height)
        guard let target = dropTarget(at: point, excluding: drag.source) else { return nil }
        return game.canDrop(drag.cards, on: target) ? target : nil
    }

    private func destinationIndex(for pile: Pile) -> Int {
        switch pile {
        case .tableau(let column): game.tableau[column].count
        case .foundation(let i): max(0, game.foundations[i].count - 1)
        case .waste: max(0, game.waste.count - 1)
        case .stock: 0
        }
    }

    private func pickCard(at point: CGPoint, metrics: CardSize) -> (pile: Pile, index: Int)? {
        if !game.waste.isEmpty {
            let visible = min(game.drawCount == 3 ? 3 : 1, game.waste.count)
            let top = wasteOrigin(fanSlot: 0, visible: visible, metrics: metrics)
            let topFrame = CGRect(x: top.x, y: top.y, width: metrics.width, height: metrics.height)
            if expanded(topFrame).contains(point) {
                return (.waste, game.waste.count - 1)
            }
        }

        for i in 0..<4 {
            let pile = Pile.foundation(i)
            if let frame = pileFrames[pile], frame.contains(point), !game.foundations[i].isEmpty {
                return (pile, game.foundations[i].count - 1)
            }
        }

        for column in 0..<7 {
            let pile = Pile.tableau(column)
            guard let frame = pileFrames[pile] else { continue }
            let cards = game.tableau[column]
            for index in stride(from: cards.count - 1, through: 0, by: -1) {
                guard cards[index].isFaceUp else { continue }
                let y = frame.minY + metrics.stackOffset(at: index, in: cards)
                let cardFrame = CGRect(
                    x: frame.minX,
                    y: y,
                    width: metrics.width,
                    height: metrics.exposedPeek(at: index, in: cards)
                )
                if cardFrame.contains(point) {
                    return (pile, index)
                }
            }
        }
        return nil
    }

    private func cardOrigin(pile: Pile, index: Int, metrics: CardSize) -> CGPoint {
        switch pile {
        case .tableau(let column):
            guard let frame = pileFrames[pile] else { return .zero }
            return CGPoint(
                x: frame.minX,
                y: frame.minY + metrics.stackOffset(at: index, in: game.tableau[column])
            )
        case .waste:
            let visible = min(game.drawCount == 3 ? 3 : 1, game.waste.count)
            return wasteOrigin(fanSlot: 0, visible: visible, metrics: metrics)
        default:
            return pileFrames[pile]?.origin ?? .zero
        }
    }

    private func dropTarget(at point: CGPoint, excluding source: Pile) -> Pile? {
        for i in 0..<4 {
            let pile = Pile.foundation(i)
            if pile != source, let frame = pileFrames[pile], frame.insetBy(dx: -12, dy: -12).contains(point) {
                return pile
            }
        }
        for column in 0..<7 {
            let pile = Pile.tableau(column)
            guard pile != source, let frame = pileFrames[pile] else { continue }
            if point.x >= frame.minX - 6, point.x <= frame.maxX + 6, point.y >= frame.minY - 10 {
                return pile
            }
        }
        return nil
    }

    private func expanded(_ frame: CGRect) -> CGRect {
        frame.insetBy(dx: -8, dy: -8)
    }

    private func metrics(in size: CGSize) -> CardSize {
        let spacing: CGFloat = 4
        let width = (size.width - 10 - spacing * 6) / 7
        let height = width * 1.46
        // Everything above the tableau: top padding, header, gap, top row, row spacing, bottom padding.
        let tableauHeight = max(height * 2, size.height - 6 - 40 - 8 - height - 22 - 12)
        let indexBand = width * 0.50 * faceTheme.indexScale + 4
        return CardSize(
            width: width,
            height: height,
            facePeek: max(indexBand, height * 0.52),
            backPeek: max(10, height * 0.27),
            spacing: spacing,
            minFacePeek: indexBand,
            minBackPeek: max(5, height * 0.07),
            tableauHeight: tableauHeight
        )
    }
}

// MARK: - Static board pieces

/// Empty pile outlines. They never change during play, and their frames tell the
/// card layer and the gestures where each pile sits.
private struct PileSlots: View, Equatable {
    var metrics: CardSize
    var leftHanded: Bool
    var drawCount: Int
    var showRecycle: Bool

    var body: some View {
        VStack(spacing: 22) {
            topRow
            HStack(alignment: .top, spacing: metrics.spacing) {
                ForEach(0..<7, id: \.self) { column in
                    EmptyPileView(size: metrics)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .reportFrame(.tableau(column))
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: metrics.spacing) {
            if leftHanded {
                stockSlot
                wasteSlot
                Spacer(minLength: 6)
                foundations
            } else {
                foundations
                Spacer(minLength: 6)
                wasteSlot
                stockSlot
            }
        }
    }

    private var foundations: some View {
        ForEach(0..<4, id: \.self) { index in
            EmptyPileView(size: metrics, symbol: "A")
                .reportFrame(.foundation(index))
        }
    }

    private var stockSlot: some View {
        EmptyPileView(size: metrics, systemImage: showRecycle ? "arrow.clockwise" : nil)
            .accessibilityLabel(showRecycle ? "Recycle waste" : "Draw from stock")
            .accessibilityAddTraits(.isButton)
            .reportFrame(.stock)
    }

    private var wasteSlot: some View {
        let extra = drawCount == 3 ? metrics.fanStep * 2 : 0
        return EmptyPileView(size: metrics)
            .frame(width: metrics.width + extra, alignment: leftHanded ? .leading : .trailing)
            .reportFrame(.waste)
    }
}

private struct FeltBackground: View {
    var theme: TableTheme

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.colors, startPoint: .top, endPoint: .bottom)
                .animation(.easeInOut(duration: 0.35), value: theme)
            RadialGradient(
                colors: [Color.white.opacity(0.14), .clear],
                center: UnitPoint(x: 0.5, y: 0.25),
                startRadius: 10,
                endRadius: 620
            )
            Canvas { context, size in
                // Fine, deterministic speckle so the table reads as cloth rather than a flat fill.
                var seed: UInt64 = 0x9E3779B97F4A7C15
                func next() -> CGFloat {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    return CGFloat(seed >> 33) / CGFloat(UInt32.max >> 1)
                }
                let count = Int(size.width * size.height / 90)
                for _ in 0..<count {
                    let rect = CGRect(x: next() * size.width, y: next() * size.height, width: 1, height: 1)
                    let light = next() > 0.5
                    context.fill(Path(rect), with: .color(light ? .white.opacity(0.035) : .black.opacity(0.06)))
                }
            }
            .drawingGroup()
            RadialGradient(
                colors: [.clear, .black.opacity(0.45)],
                center: .center,
                startRadius: 220,
                endRadius: 900
            )
        }
    }
}

private struct BurstLabel: View {
    let text: String
    @State private var risen = false

    var body: some View {
        Text(text)
            .font(.system(.headline, design: .rounded).weight(.heavy).monospacedDigit())
            .foregroundStyle(text.hasPrefix("-") ? Color.orange : Felt.gold)
            .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
            .scaleEffect(risen ? 1 : 0.5)
            .offset(y: risen ? -34 : 0)
            .opacity(risen ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) { risen = true }
            }
    }
}

private struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
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
