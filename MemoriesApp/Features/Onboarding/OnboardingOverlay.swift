import SwiftUI

/// First-run coaching.
///
/// This used to be five cards of prose behind a scrim. It is now two
/// instructions over the live board, because the two things worth knowing —
/// *drag anything* and *tie two things together* — are gestures, and a gesture
/// is learned by doing it once, not by reading a paragraph about it.
///
/// The important property is that it is **non-blocking**. There is no scrim and
/// no modal trait: the board underneath stays fully interactive, which it has to
/// be, since performing the gesture on that board is what advances the coach.
///
/// Completion and skipping are recorded identically: both mean "don't show me
/// this again". A user who skips has made a decision, and re-asking them would
/// override it. Settings carries "Replay the tutorial" for anyone who wants it
/// back.
struct OnboardingCoach: View {

    let step: CoachStep
    let onFinish: () -> Void

    @Environment(\.motionPolicy) private var motion

    var body: some View {
        // No scrim and no background behind the card, so the only thing on this
        // layer that can take a touch is the card itself. The board keeps the
        // rest of the screen.
        card
            .frame(maxWidth: 420)
            .padding(.horizontal, Space.unit * 3)
            .animation(motion.animation(.spring(response: 0.42, dampingFraction: 0.82)), value: step)
            // Both gestures done: say so, then get out of the way on its own.
            // "Done" stays there for anyone who wants to dismiss it sooner.
            .task(id: isFinished) {
                guard isFinished else { return }
                try? await Task.sleep(nanoseconds: 2_600_000_000)
                guard !Task.isCancelled else { return }
                onFinish()
            }
    }

    private var card: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Palette.accent)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .textStyle(TypeScale.bodyMD)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.onSurface)

                Text(detail)
                    .textStyle(TypeScale.bodySM)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 10) {
                Button(step == .done ? "Done" : "Skip", action: onFinish)
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(step == .done ? Palette.accent : Palette.onSurfaceVariant)
                    .minimumHitArea()
                    .accessibilityHint("Closes the tutorial and won't show it again")

                progressDots
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .solidGlass(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .id(step)
        .transition(
            motion.isReduced
                ? .opacity
                : .asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                )
        )
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 2, id: \.self) { index in
                Capsule()
                    .fill(index <= completedCount - 1 ? Palette.neon : Palette.onSurfaceVariant.opacity(0.3))
                    .frame(width: index == completedCount ? 16 : 6, height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    private var isFinished: Bool { step == .done }

    private var completedCount: Int {
        switch step {
        case .drag: 0
        case .tie: 1
        case .done: 2
        }
    }

    private var icon: String {
        switch step {
        case .drag: "hand.draw"
        case .tie: "link"
        case .done: "checkmark.seal"
        }
    }

    private var title: String {
        switch step {
        case .drag: "Drag a memory"
        case .tie: "Now tie two together"
        case .done: "That's it."
        }
    }

    private var detail: String {
        switch step {
        case .drag:
            "Put your finger on anything on the board and move it."
        case .tie:
            "Tap the link button in the dock, pick Twine, then tap two memories."
        case .done:
            "Everything else — photos, notes, stickers, drawing — is in the dock."
        }
    }
}
