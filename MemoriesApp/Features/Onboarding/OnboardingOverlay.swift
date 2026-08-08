import SwiftUI

/// First-run introduction.
///
/// Five cards, shown once. It explains the one idea the app is built on — a
/// board is a surface, not a folder — and then names each tab, because the
/// floating dock is unusual enough that a first-time user benefits from being
/// told what the four destinations are.
///
/// Completion and skipping are recorded identically: both mean "don't show me
/// this again". A user who skips has made a decision, and re-asking them would
/// override it. Settings carries "Replay the tutorial" for anyone who wants it
/// back.
struct OnboardingOverlay: View {

    let onFinish: () -> Void

    @Environment(\.motionPolicy) private var motion
    @State private var index = 0

    private var steps: [OnboardingStep] { OnboardingStep.all }
    private var step: OnboardingStep { steps[min(index, steps.count - 1)] }
    private var isLast: Bool { index == steps.count - 1 }

    var body: some View {
        ZStack {
            scrim

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                card
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Space.unit * 3)
        }
        .accessibilityAddTraits(.isModal)
    }

    private var scrim: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Palette.void.opacity(0.55))
            .ignoresSafeArea()
            // Tapping outside must not dismiss: skipping is a decision that gets
            // recorded, so it needs a deliberate control, not an accident.
            .contentShape(Rectangle())
            .onTapGesture {}
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            illustration
            copy
            progressDots
            controls
        }
        .padding(28)
        .frame(maxWidth: 460)
        .liquidGlass(
            RoundedRectangle(cornerRadius: Radius.panel, style: .continuous),
            tint: 0.07,
            shadowRadius: 40
        )
    }

    private var header: some View {
        HStack {
            Text("Step \(index + 1) of \(steps.count)")
                .textStyle(TypeScale.labelTiny)
                .foregroundStyle(Palette.onSurfaceVariant)

            Spacer()

            Button("Skip", action: finish)
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onSurfaceVariant)
                .accessibilityHint("Closes the tutorial and won't show it again")
        }
    }

    /// A small tactile vignette per step, rather than an icon. The product's
    /// argument is physical, so the tutorial should look like the thing it is
    /// describing.
    private var illustration: some View {
        ZStack {
            GlowBlob(color: step.tint, size: 190, opacity: 0.28)

            Image(systemName: step.icon)
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Palette.onSurface)

            StickerBadge(text: step.badge, style: step.badgeStyle, rotation: -7, shape: .pill)
                .offset(x: 78, y: -46)
                .scaleEffect(0.9)
        }
        .frame(height: 132)
        .frame(maxWidth: .infinity)
        .id(step.id)
        .transition(motion.isReduced ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(step.title)
                .textStyle(TypeScale.headline)
                .foregroundStyle(Palette.onSurface)

            Text(step.body)
                .textStyle(TypeScale.bodyMD)
                .foregroundStyle(Palette.onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(step.id)
        .transition(.opacity)
    }

    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(steps.indices, id: \.self) { dot in
                Capsule()
                    .fill(dot == index ? Palette.neon : Palette.onSurfaceVariant.opacity(0.3))
                    .frame(width: dot == index ? 22 : 7, height: 7)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: back) {
                Text("Back")
                    .textStyle(TypeScale.sticker)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                    .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(index == 0)
            .opacity(index == 0 ? 0.35 : 1)

            Spacer(minLength: 0)

            NeonButton(
                title: isLast ? "Finish" : "Next",
                icon: isLast ? "checkmark" : "arrow.right"
            ) {
                if isLast { finish() } else { advance() }
            }
        }
    }

    // MARK: Actions

    private func advance() {
        withAnimation(motion.animation(.spring(response: 0.4, dampingFraction: 0.82))) {
            index = min(index + 1, steps.count - 1)
        }
    }

    private func back() {
        withAnimation(motion.animation(.spring(response: 0.4, dampingFraction: 0.82))) {
            index = max(index - 1, 0)
        }
    }

    private func finish() {
        withAnimation(motion.animation(.easeOut(duration: 0.25))) {
            onFinish()
        }
    }
}

struct OnboardingStep: Identifiable {

    let id: Int
    let icon: String
    let badge: String
    let badgeStyle: StickerStyle
    let tint: Color
    let title: String
    let body: String

    static let all: [OnboardingStep] = [
        OnboardingStep(
            id: 0,
            icon: "square.on.square.dashed",
            badge: "the idea",
            badgeStyle: .neon,
            tint: Palette.pink,
            title: "This is a scrapbook, not a gallery",
            body: """
            Most photo apps sort your pictures into a grid and call it a memory. \
            Here you get a board — a free surface where things overlap, sit \
            crooked, and get tied together. How you arrange it is part of what \
            you're keeping.
            """
        ),
        OnboardingStep(
            id: 1,
            icon: "hand.draw",
            badge: "boards",
            badgeStyle: .neon,
            tint: Palette.neon,
            title: "Open a board and move things",
            body: """
            Drag anything, anytime — nothing snaps to a grid. Tap an object to \
            select it, then pinch to resize and twist to rotate. Double-tap to \
            edit it. The + button adds prints, polaroids, notes and stickers, \
            and the link tool ties two memories together with twine.
            """
        ),
        OnboardingStep(
            id: 2,
            icon: "photo.on.rectangle.angled",
            badge: "memories",
            badgeStyle: .pink,
            tint: Palette.pink,
            title: "Every photo, in one place",
            body: """
            The Memories tab flattens every board into one view. Sort it by day \
            to walk back through time, or by topic to see everything from school, \
            travel or friends together. Search finds a caption or a board name.
            """
        ),
        OnboardingStep(
            id: 3,
            icon: "person.2",
            badge: "friends",
            badgeStyle: .pink,
            tint: Palette.pink,
            title: "Boards are better shared",
            body: """
            Friends shows who's on a board right now, what they've just added, \
            and the boards you have in common. Tap anyone to see their profile, \
            what you share, and to add them to a board.
            """
        ),
        OnboardingStep(
            id: 4,
            icon: "person.crop.circle",
            badge: "you",
            badgeStyle: .neon,
            tint: Palette.neon,
            title: "Your profile is a board too",
            body: """
            Set a status, put a record on, and stick whatever you're into on the \
            locker door. Edit profile changes any of it, and Settings — top \
            right, on every screen — holds light mode, motion and privacy.
            """
        )
    ]
}
