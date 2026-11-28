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

/// The round icon used for the header buttons. It is one accessibility element named
/// `title`; the glyph keeps a fixed size so the header never overflows, and the Large
/// Content Viewer shows it full size on long press.
struct CircleIcon: View {
    let systemName: String
    let title: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.protectedText)
            .frame(width: Theme.Size.touchTarget, height: Theme.Size.touchTarget)
            .background(Theme.surface, in: Circle())
            .shadow(color: Theme.shadow, radius: 8, y: 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityShowsLargeContentViewer { Label(title, systemImage: systemName) }
    }
}

/// A list row that slides left to show "Sửa" and "Bỏ chặn".
///
/// Each row is a native horizontal scroll view, so iOS itself tells a sideways swipe
/// from a vertical scroll of the list. The actions sit inside the row's own bounds, so
/// the card that clips the list also shapes them.
struct SwipeRow<Content: View>: View {
    /// Width of the card the row sits in.
    let width: CGFloat
    let onEdit: () -> Void
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .subheadline) private var scaledActionWidth: CGFloat = 88

    private var actionWidth: CGFloat { min(scaledActionWidth, 120) }
    private static var contentID: String { "content" }

    var body: some View {
        if width <= 0 {
            content()
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        content()
                            .frame(width: width)
                            .id(Self.contentID)
                        action("Sửa", background: Theme.field, foreground: Theme.ink) { close(proxy); onEdit() }
                        action("Bỏ chặn", background: Theme.danger, foreground: Theme.onDanger) { close(proxy); onDelete() }
                    }
                    .modifier(SnapTargets())
                }
                .modifier(SnapToTargets())
            }
        }
    }

    private func action(_ title: String, background: Color, foreground: Color, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Text(title)
                .font(Theme.font(.subheadline, weight: .heavy))
                .foregroundStyle(foreground)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
                .background(background)
        }
        .buttonStyle(.plain)
        // VoiceOver reaches these through the row's custom actions instead.
        .accessibilityHidden(true)
    }

    private func close(_ proxy: ScrollViewProxy) {
        withAnimation(reduceMotion ? nil : Theme.Motion.spring) {
            proxy.scrollTo(Self.contentID, anchor: .leading)
        }
    }
}

/// Rows settle fully open or fully closed on iOS 17 and later. iOS 16 has no snapping
/// API, so there the row rests where the finger leaves it.
private struct SnapTargets: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollTargetLayout()
        } else {
            content
        }
    }
}

private struct SnapToTargets: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollTargetBehavior(.viewAligned)
        } else {
            content
        }
    }
}

/// Reports the width of the list card so rows can size their content to it.
struct CardWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
