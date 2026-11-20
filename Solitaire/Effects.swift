import SwiftUI

// MARK: - Per-card reactions

/// A quick bounce whenever `pop` changes and a sideways "no" shake whenever `shake` changes.
struct CardReactions: ViewModifier {
    var pop: Int
    var shake: Int

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: 1.0, trigger: pop) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(1.14, duration: 0.12, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.42, spring: .bouncy)
                }
            }
            .keyframeAnimator(initialValue: 0.0, trigger: shake) { view, x in
                view.offset(x: x)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-9, duration: 0.06)
                    CubicKeyframe(8, duration: 0.08)
                    CubicKeyframe(-6, duration: 0.08)
                    CubicKeyframe(4, duration: 0.07)
                    CubicKeyframe(0, duration: 0.08)
                }
            }
    }
}

// MARK: - Pile highlights

/// The outline on a pile that will accept the cards being dragged. It breathes so it reads as live.
struct TargetGlow: View {
    var corner: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .strokeBorder(Felt.gold, lineWidth: 2.5)
            .phaseAnimator([false, true]) { view, bright in
                view
                    .shadow(color: Felt.gold.opacity(bright ? 0.95 : 0.5), radius: bright ? 13 : 6)
                    .opacity(bright ? 1 : 0.8)
            } animation: { _ in
                .easeInOut(duration: 0.5)
            }
    }
}

/// A gold flash and an expanding ring on a foundation as a card lands. A finished suit
/// gets a stronger flash and a second, wider ring.
struct LandingRipple: View {
    var size: CGSize
    var corner: CGFloat
    var strong: Bool
    @State private var spread = false
    @State private var echo = false

    static func duration(strong: Bool) -> Double { strong ? 1.3 : 0.75 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        ZStack {
            shape.fill(Felt.gold.opacity(spread ? 0 : (strong ? 0.45 : 0.28)))
            shape.strokeBorder(Felt.gold, lineWidth: strong ? 3 : 2)
                .scaleEffect(spread ? (strong ? 1.45 : 1.22) : 1)
                .opacity(spread ? 0 : 1)
            if strong {
                shape.strokeBorder(Felt.cream, lineWidth: 1.5)
                    .scaleEffect(echo ? 1.9 : 1)
                    .opacity(echo ? 0 : 0.85)
            }
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: Felt.gold.opacity(0.75), radius: 10)
        .onAppear {
            withAnimation(.easeOut(duration: strong ? 0.85 : 0.6)) { spread = true }
            if strong {
                withAnimation(.easeOut(duration: 1.1).delay(0.12)) { echo = true }
            }
        }
    }
}

// MARK: - Hints

/// Shows a suggested move: the cards to pick up glow, a ghost of them glides to where they
/// would land, and the landing spot is outlined. With no landing spot (the stock) only the glow shows.
struct HintHighlight: View {
    var source: CGRect
    var landing: CGRect?
    var corner: CGFloat
    var reduceMotion: Bool

    private struct Travel {
        var progress = 0.0
        var opacity = 0.0
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        ZStack(alignment: .topLeading) {
            if let landing {
                shape
                    .strokeBorder(Felt.gold.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .background(shape.fill(Felt.gold.opacity(0.10)))
                    .frame(width: landing.width, height: landing.height)
                    .offset(x: landing.minX, y: landing.minY)

                if !reduceMotion {
                    shape
                        .fill(Felt.gold.opacity(0.30))
                        .overlay(shape.strokeBorder(Felt.cream.opacity(0.9), lineWidth: 1.5))
                        .frame(width: source.width, height: source.height)
                        .shadow(color: Felt.gold.opacity(0.6), radius: 8)
                        .keyframeAnimator(initialValue: Travel(), repeating: true) { view, travel in
                            view
                                .opacity(travel.opacity)
                                .offset(
                                    x: source.minX + (landing.minX - source.minX) * travel.progress,
                                    y: source.minY + (landing.minY - source.minY) * travel.progress
                                )
                        } keyframes: { _ in
                            KeyframeTrack(\.progress) {
                                LinearKeyframe(0, duration: 0.2)
                                CubicKeyframe(1, duration: 0.7)
                                LinearKeyframe(1, duration: 0.45)
                            }
                            KeyframeTrack(\.opacity) {
                                LinearKeyframe(1, duration: 0.2)
                                LinearKeyframe(1, duration: 0.7)
                                LinearKeyframe(0, duration: 0.3)
                                LinearKeyframe(0, duration: 0.15)
                            }
                        }
                }
            }

            TargetGlow(corner: corner)
                .frame(width: source.width, height: source.height)
                .offset(x: source.minX, y: source.minY)
        }
        .allowsHitTesting(false)
    }
}

/// The line of text that says what a hint is suggesting.
struct HintToast: View {
    var text: String
    var found: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: found ? "lightbulb.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(found ? Felt.gold : Color.orange)
            Text(text)
                .foregroundStyle(Felt.cream)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 5)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Particles

/// Confetti fired from both bottom corners for a win, or a small burst of sparks from a point.
struct ParticleBurst: View {
    enum Style {
        case confetti
        case sparks(at: CGPoint, scale: CGFloat)
    }

    static let confettiDuration = 3.6
    static let sparksDuration = 1.2

    /// Kept for the life of the view. The canvas renderer reads it directly, so the particles
    /// and the start time must live in a reference, not in values set after the view appears.
    @State private var burst: Burst

    init(style: Style) {
        _burst = State(initialValue: Burst(style: style))
    }

    var body: some View {
        let burst = burst
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(burst.start)
                for particle in burst.particles {
                    particle.draw(in: context, size: size, at: t)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private final class Burst {
        let style: Style
        let start = Date.now
        /// Built on first draw; the parent may re-create this view's struct many times before then.
        lazy var particles: [Particle] = {
            switch style {
            case .confetti: Particle.confetti()
            case .sparks(let point, let scale): Particle.sparks(at: point, scale: scale)
            }
        }()

        init(style: Style) { self.style = style }
    }
}

private struct Particle {
    enum Kind { case confetti(side: Double), spark(origin: CGPoint) }

    var kind: Kind
    /// Confetti: launch speed as fractions of the board (x of width, y of height). Sparks: points per second.
    var velocity: CGVector
    var drag: Double
    /// Confetti: fraction of the board height per second². Sparks: points per second².
    var gravity: Double
    var color: Color
    var size: CGSize
    var spin: Double
    var tumble: Double
    var phase: Double
    var sway: Double
    var delay: Double
    var life: Double

    func draw(in context: GraphicsContext, size board: CGSize, at time: Double) {
        let t = time - delay
        guard t >= 0, t < life else { return }

        let origin: CGPoint
        var vx = Double(velocity.dx)
        var vy = Double(velocity.dy)
        var g = gravity
        switch kind {
        case .confetti(let side):
            origin = CGPoint(x: side * board.width, y: board.height + 10)
            vx *= Double(board.width)
            vy *= Double(board.height)
            g *= Double(board.height)
        case .spark(let point):
            origin = point
        }

        // Ballistic flight with air drag, solved in closed form so every frame is independent.
        let k = drag
        let eased = (1 - exp(-k * t)) / k
        let x = Double(origin.x) + vx * eased + sway * sin(t * 3.2 + phase) * min(t, 1)
        let y = Double(origin.y) + g / k * t + (vy - g / k) * eased

        var ctx = context
        ctx.opacity = min(1, (life - t) / 0.45)
        ctx.translateBy(x: x, y: y)
        ctx.rotate(by: .radians(spin * t + phase))

        switch kind {
        case .confetti:
            // Squashing one axis fakes a flake tumbling end over end.
            ctx.scaleBy(x: 1, y: CGFloat(cos(tumble * t + phase)))
            let rect = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(color))
        case .spark:
            ctx.blendMode = .plusLighter
            let twinkle = 0.7 + 0.3 * cos(t * 18 + phase)
            ctx.fill(Self.star(radius: size.width * twinkle), with: .color(color))
        }
    }

    private static func star(radius r: CGFloat) -> Path {
        var path = Path()
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4 - .pi / 2
            let reach = i.isMultiple(of: 2) ? r : r * 0.3
            let point = CGPoint(x: cos(angle) * reach, y: sin(angle) * reach)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    static func confetti() -> [Particle] {
        let palette: [Color] = [
            Felt.gold, Felt.cream, Felt.red,
            Color(red: 0.36, green: 0.74, blue: 1.0),
            Color(red: 0.52, green: 0.88, blue: 0.46),
            Color(red: 1.0, green: 0.56, blue: 0.76),
        ]
        var result: [Particle] = []
        for side in [0.0, 1.0] {
            let inward = side == 0 ? 1.0 : -1.0
            for _ in 0..<75 {
                let drag = Double.random(in: 1.2...1.7)
                result.append(Particle(
                    kind: .confetti(side: side),
                    // Horizontal reach is velocity / drag, so this lands each flake 20–85% across.
                    velocity: CGVector(dx: inward * Double.random(in: 0.2...0.85) * drag, dy: -Double.random(in: 2.3...3.3)),
                    drag: drag,
                    gravity: 1.8,
                    color: palette.randomElement()!,
                    size: CGSize(width: .random(in: 6...10), height: .random(in: 10...16)),
                    spin: .random(in: -6...6),
                    tumble: .random(in: 6...14),
                    phase: .random(in: 0...(2 * .pi)),
                    sway: .random(in: 6...18),
                    delay: .random(in: 0...0.3),
                    life: ParticleBurst.confettiDuration - 0.35
                ))
            }
        }
        return result
    }

    static func sparks(at point: CGPoint, scale: CGFloat) -> [Particle] {
        let palette: [Color] = [Felt.gold, Felt.cream, .white]
        let count = 28
        let unit = Double(scale)
        return (0..<count).map { i in
            let angle = Double(i) / Double(count) * 2 * .pi + .random(in: -0.12...0.12)
            let speed = unit * .random(in: 2.6...5.8)
            return Particle(
                kind: .spark(origin: point),
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed - unit * 1.2),
                drag: 3.2,
                gravity: unit * 4,
                color: palette.randomElement()!,
                size: CGSize(width: scale * .random(in: 0.07...0.13), height: 0),
                spin: .random(in: -4...4),
                tumble: 0,
                phase: .random(in: 0...(2 * .pi)),
                sway: 0,
                delay: .random(in: 0...0.08),
                life: .random(in: 0.65...1.05)
            )
        }
    }
}
