import SwiftUI

/// Transient confirmation.
///
/// Saving something and getting no acknowledgement is the single most common way
/// an app makes a user doubt it worked. This is the app's one answer to that,
/// used everywhere a change is committed, so the feedback is identical whether
/// you renamed a board or changed your handle.
struct ToastMessage: Identifiable, Equatable {

    enum Tone {
        case success, warning

        var icon: String {
            switch self {
            case .success: "checkmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .success: Palette.accent
            case .warning: Palette.pinkAccent
            }
        }
    }

    let id = UUID()
    var text: String
    var tone: Tone = .success
}

private struct ToastModifier: ViewModifier {

    @Binding var message: ToastMessage?
    @Environment(\.motionPolicy) private var motion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message {
                    banner(message)
                        .padding(.top, Space.unit * 2)
                        .transition(
                            motion.isReduced
                                ? .opacity
                                : .move(edge: .top).combined(with: .opacity)
                        )
                        .task(id: message.id) {
                            try? await Task.sleep(for: .seconds(2.4))
                            withAnimation(motion.animation(.spring(response: 0.4, dampingFraction: 0.85))) {
                                self.message = nil
                            }
                        }
                }
            }
            .animation(motion.animation(.spring(response: 0.4, dampingFraction: 0.85)), value: message)
    }

    private func banner(_ message: ToastMessage) -> some View {
        HStack(spacing: 10) {
            Image(systemName: message.tone.icon)
                .symbolStyle(TypeScale.bodySM, size: 15, weight: .semibold)
                .foregroundStyle(message.tone.tint)

            Text(message.text)
                .textStyle(TypeScale.bodySM)
                .fontWeight(.medium)
                .foregroundStyle(Palette.onSurface)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .solidGlass(Capsule(style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

extension View {
    func toast(_ message: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}

/// Inline validation text under a field. Reserves no space when there is no
/// problem, so forms don't jump as the user types.
struct FieldError: View {

    let text: String?

    var body: some View {
        if let text {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .symbolStyle(TypeScale.bodySM, size: 11, weight: .semibold)
                Text(text)
                    .textStyle(TypeScale.bodySM)
            }
            .foregroundStyle(Palette.pinkAccent)
            .accessibilityElement(children: .combine)
        }
    }
}
