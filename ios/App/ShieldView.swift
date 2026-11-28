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
    @ScaledMetric(relativeTo: .largeTitle) private var scaledWidth: CGFloat = 124
    @State private var pulsing = false
    @State private var rocking = false
    @State private var stampScale: CGFloat = 1

    private var width: CGFloat { min(scaledWidth, 168) }
    private var tint: Color { isProtected ? Theme.protected : Theme.danger }
    private var glow: Color { isProtected ? Theme.glowOn : Theme.glowOff }

    var body: some View {
        ZStack {
            if isProtected {
                ring(delay: 0)
                ring(delay: Theme.Motion.shieldPulse / 2)
            }
            shield
                .rotationEffect(.degrees(!isProtected && rocking ? 5 : (!isProtected && !reduceMotion ? -5 : 0)))
                .scaleEffect(stampScale)
        }
        .frame(width: width * 1.6, height: width * 148 / 132 * 1.25)
        .onAppear(perform: startLoops)
        .onChange(of: isProtected) { _ in startLoops() }
        .onChange(of: stampTrigger) { _ in stamp() }
        .accessibilityHidden(true)
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
        .shadow(color: glow, radius: 22)
        .shadow(color: glow, radius: 10, y: 8)
        .animation(reduceMotion ? nil : Theme.Motion.fast, value: isProtected)
    }

    private func ring(delay: Double) -> some View {
        Circle()
            .stroke(tint, lineWidth: 3)
            .frame(width: width, height: width)
            .scaleEffect(reduceMotion ? 1.2 : (pulsing ? 1.55 : 0.75))
            .opacity(reduceMotion ? 0.25 : (pulsing ? 0 : 0.6))
            .animation(
                reduceMotion ? nil : .easeOut(duration: Theme.Motion.shieldPulse).repeatForever(autoreverses: false).delay(delay),
                value: pulsing
            )
    }

    private func startLoops() {
        pulsing = false
        rocking = false
        guard !reduceMotion else { return }
        DispatchQueue.main.async {
            if isProtected {
                pulsing = true
            } else {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { rocking = true }
            }
        }
    }

    private func stamp() {
        guard !reduceMotion else { return }
        withAnimation(.easeIn(duration: 0.12)) { stampScale = 0.74 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(Theme.Motion.spring) { stampScale = 1 }
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
