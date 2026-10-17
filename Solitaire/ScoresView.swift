import SwiftUI

struct ScoresView: View {
    var store: ScoreStore
    @State private var board: ScoreBoard = .allTime

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Board", selection: $board) {
                    ForEach(ScoreBoard.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                let rows = store.top10(on: board)
                if rows.isEmpty {
                    emptyState
                } else {
                    list(rows)
                }
            }
            .background(Felt.greenDeep.ignoresSafeArea())
            .navigationTitle("High Scores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Felt.green.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "trophy")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(Felt.gold)
            Text("No scores yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Felt.cream)
            Text(emptyCopy)
                .font(.subheadline)
                .foregroundStyle(Felt.cream.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var emptyCopy: String {
        switch board {
        case .allTime: "Win a game to land on the board."
        case .weekly: "No wins in the last 7 days."
        case .monthly: "No wins this month yet."
        }
    }

    private func list(_ rows: [GameScore]) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, score in
                    ScoreRow(rank: index + 1, score: score)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

private struct ScoreRow: View {
    let rank: Int
    let score: GameScore

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(rank <= 3 ? Felt.gold : Felt.cream.opacity(0.7))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(score.points)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(Felt.cream)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Felt.cream.opacity(0.65))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(score.elapsed.clockString)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Felt.cream)
                Text(score.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundStyle(Felt.cream.opacity(0.55))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(rank == 1 ? 0.12 : 0.07))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var subtitle: String {
        let draw = score.drawCount == 3 ? "Draw 3" : "Draw 1"
        let moves = score.moves == 1 ? "1 move" : "\(score.moves) moves"
        return "\(draw)  ·  \(moves)"
    }
}
