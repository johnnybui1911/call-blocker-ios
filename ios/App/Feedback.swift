import SwiftUI
import UIKit

/// Press feedback for the main buttons: a small squish on a spring.
struct PressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : Theme.Motion.spring, value: configuration.isPressed)
    }
}

enum Haptics {
    static func blocked() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

/// The message that drops from the top after an action.
struct ToastView: View {
    let banner: RuleStore.Banner
    let onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .font(Theme.font(.subheadline, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            if let onRetry {
                Button("Thử lại", action: onRetry)
                    .font(Theme.font(.subheadline, weight: .heavy))
                    .underline()
            }
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: Theme.Size.touchTarget)
        .background(background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Theme.shadow, radius: 12, y: 6)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }

    private var text: String {
        switch banner {
        case .error(let value), .success(let value), .warning(let value):
            return value
        }
    }

    private var background: Color {
        switch banner {
        case .success: return Theme.toastBg
        case .warning, .error: return Theme.sheet
        }
    }

    private var foreground: Color {
        switch banner {
        case .success: return Theme.toastInk
        case .warning: return Theme.warnText
        case .error: return Theme.dangerText
        }
    }
}

/// A short burst of confetti in the mode's colours. Shown once per blocked number.
struct ConfettiBurst: View {
    let trigger: Int
    @State private var flying = false
    @State private var visible = false

    private let colors = [Theme.confetti1, Theme.confetti2, Theme.confetti3, Theme.confetti4]

    var body: some View {
        ZStack {
            if visible {
                ForEach(0..<16, id: \.self) { index in
                    let angle = Double(index) / 16 * 2 * Double.pi
                    let reach = 90 + Double(index % 3) * 40
                    RoundedRectangle(cornerRadius: 3)
                        .fill(colors[index % colors.count])
                        .frame(width: 10, height: 14)
                        .rotationEffect(.degrees(flying ? Double(index * 47) : 0))
                        .offset(x: flying ? cos(angle) * reach : 0, y: flying ? sin(angle) * reach : 0)
                        .opacity(flying ? 0 : 1)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _ in burst() }
    }

    private func burst() {
        flying = false
        visible = true
        withAnimation(.easeOut(duration: 0.9)) { flying = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) { visible = false }
    }
}
