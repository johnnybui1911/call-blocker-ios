import SwiftUI

/// The animated shield at the top of the home screen.
///
/// Protected: two rings pulse outward. Not protected: the shield rocks slowly and the
/// mark becomes an exclamation point, so the state never depends on colour alone.
/// With Reduce Motion on, nothing loops and the stamp is a plain state change.
struct ShieldView: View {
    let isProtected: Bool
    /// Changes when a number was just blocked; the shield answers with a stamp.
    let stampTrigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .largeTitle) private var scaledWidth: CGFloat = 124
    @State private var stampScale: CGFloat = 1
    @State private var stampTilt: Double = 0

    /// Not protected: lean left and come back, rest, lean right and come back, rest, repeat.
    private static let tiltLean = 1.4, tiltRest = 0.4, tiltAmplitude = 5.0
    private static func tilt(at t: TimeInterval) -> Double {
        let period = 2 * (tiltLean + tiltRest)
        let x = t.truncatingRemainder(dividingBy: period)
        if x < tiltLean { return -tiltAmplitude * sin(.pi * x / tiltLean) }
        let y = x - tiltLean - tiltRest
        if y >= 0 && y < tiltLean { return tiltAmplitude * sin(.pi * y / tiltLean) }
        return 0
    }

    private var width: CGFloat { min(scaledWidth, 168) }
    private var tint: Color { isProtected ? Theme.protected : Theme.danger }
    private var glow: Color { isProtected ? Theme.glowOn : Theme.glowOff }

    var body: some View {
        ZStack {
            if isProtected { pulse }
            tiltedShield
                .scaleEffect(stampScale)
                .rotationEffect(.degrees(stampTilt))
        }
        .frame(width: width * 1.9, height: width * 1.9)
        .onChange(of: stampTrigger) { _ in stamp() }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var tiltedShield: some View {
        if isProtected || reduceMotion {
            shield
        } else {
            TimelineView(.animation(minimumInterval: nil, paused: scenePhase != .active)) { context in
                shield.rotationEffect(.degrees(Self.tilt(at: context.date.timeIntervalSinceReferenceDate)))
            }
        }
    }

    private var shield: some View {
        ZStack {
            ShieldShape().fill(tint)
            ShieldShineShape().fill(Color.white.opacity(0.22))
            Circle()
                .fill(Theme.shieldCore)
                .frame(width: width * 60 / 132, height: width * 60 / 132)
                .offset(y: -width * 2 / 132)
            ShieldMarkShape(isProtected: isProtected)
                .stroke(tint, style: StrokeStyle(lineWidth: width * 8 / 132, lineCap: .round, lineJoin: .round))
        }
        .frame(width: width, height: width * 148 / 132)
        .shadow(color: glow, radius: 13)
        .shadow(color: glow, radius: 7, y: 10)
        .animation(reduceMotion ? nil : Theme.Motion.fast, value: isProtected)
    }

    /// Soft halo plus two rings that expand and fade, offset by half a period
    /// (mockup `ring`: scale 0.75 -> 1.55, opacity 0.6 -> 0, 2.4 s ease-out, second ring 1.2 s later).
    /// Driven by a timeline instead of a repeating animation so it is paused whenever the
    /// app is not active or the view is off screen; Reduce Motion keeps one still ring.
    private var pulse: some View {
        TimelineView(.animation(minimumInterval: nil, paused: reduceMotion || scenePhase != .active)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [tint.opacity(0.28), tint.opacity(0)],
                                         center: .center, startRadius: width * 0.3, endRadius: width * 0.95))
                    .frame(width: width * 1.9, height: width * 1.9)
                if reduceMotion {
                    ringShape(progress: 0.3)
                } else {
                    ringShape(progress: Self.progress(t, delay: 0))
                    ringShape(progress: Self.progress(t, delay: Theme.Motion.shieldPulse / 2))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func ringShape(progress: Double) -> some View {
        let eased = 1 - pow(1 - progress, 2.2)
        return Ellipse()
            .stroke(tint, lineWidth: 3)
            .frame(width: width * 120 / 124, height: width * 122 / 124)
            .scaleEffect(0.75 + 0.8 * eased)
            .opacity(0.6 * (1 - eased))
            .shadow(color: glow, radius: 6)
    }

    /// 0...1 position inside the current period; the negative-delay ring starts mid-cycle.
    private static func progress(_ t: TimeInterval, delay: Double) -> Double {
        let period = Theme.Motion.shieldPulse
        let x = (t - delay).truncatingRemainder(dividingBy: period)
        return (x < 0 ? x + period : x) / period
    }

    /// Mockup keyframes over 620 ms: 1 -> 0.72 (-8°) at 35% -> 1.18 (4°) at 70% -> 1.
    private func stamp() {
        guard !reduceMotion else { return }
        withAnimation(.easeIn(duration: 0.217)) { stampScale = 0.72; stampTilt = -8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.217) {
            withAnimation(.easeInOut(duration: 0.217)) { stampScale = 1.18; stampTilt = 4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.434) {
            withAnimation(Theme.Motion.overshoot(0.186)) { stampScale = 1; stampTilt = 0 }
        }
    }
}

/// Outline taken from the approved mockup (132 × 148 box).
private struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        let p = scaler(rect)
        var path = Path()
        path.move(to: p(66, 4))
        path.addLine(to: p(120, 24))
        path.addLine(to: p(120, 70))
        path.addCurve(to: p(66, 144), control1: p(120, 106), control2: p(97, 130))
        path.addCurve(to: p(12, 70), control1: p(35, 130), control2: p(12, 106))
        path.addLine(to: p(12, 24))
        path.closeSubpath()
        return path
    }
}

private struct ShieldShineShape: Shape {
    func path(in rect: CGRect) -> Path {
        let p = scaler(rect)
        var path = Path()
        path.move(to: p(66, 4))
        path.addLine(to: p(12, 24))
        path.addLine(to: p(12, 70))
        path.addCurve(to: p(31, 119), control1: p(12, 90), control2: p(19, 106))
        path.addCurve(to: p(66, 4), control1: p(28, 96), control2: p(30, 54))
        path.closeSubpath()
        return path
    }
}

/// A check when protected, an exclamation point when not.
private struct ShieldMarkShape: Shape {
    let isProtected: Bool

    func path(in rect: CGRect) -> Path {
        let p = scaler(rect)
        var path = Path()
        if isProtected {
            path.move(to: p(52, 73))
            path.addLine(to: p(62, 83))
            path.addLine(to: p(81, 62))
        } else {
            path.move(to: p(66, 54))
            path.addLine(to: p(66, 76))
            path.move(to: p(66, 88))
            path.addLine(to: p(66, 90))
        }
        return path
    }
}

private func scaler(_ rect: CGRect) -> (CGFloat, CGFloat) -> CGPoint {
    { x, y in CGPoint(x: rect.minX + x / 132 * rect.width, y: rect.minY + y / 148 * rect.height) }
}
