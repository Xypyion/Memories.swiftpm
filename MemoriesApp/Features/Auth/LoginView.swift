import SwiftUI

/// Sign in.
///
/// **There is no auth backend.** This screen is the real UI and the real state
/// machine — a session that can be absent, created, validated and restored — with
/// a local store where the network call belongs. Swapping in a real identity
/// provider is a change inside `AccountStore.signIn`, not a change to this view
/// or to anything that asks who the user is.
///
/// It is honest about that on screen rather than pretending to check a password.
/// Asking for a password we do not verify would teach the user their credentials
/// mean something here, which is the beginning of a real security problem.
struct LoginView: View {

    @EnvironmentObject private var account: AccountStore
    @Environment(\.motionPolicy) private var motion

    @State private var username = ""
    @State private var displayName = ""
    @State private var driftIn = false

    private var canSubmit: Bool {
        AccountValidator.usernameProblem(AccountValidator.normalisedUsername(username)) == nil
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backdrop(size: geo.size)

                ScrollView {
                    VStack(spacing: Space.unit * 4) {
                        Spacer(minLength: geo.size.height * 0.08)

                        brand
                        card
                        guestButton

                        Spacer(minLength: Space.unit * 4)
                    }
                    .frame(maxWidth: 460)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Space.unit * 3)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background(Palette.void)
        .onAppear {
            withAnimation(motion.animation(.spring(response: 0.9, dampingFraction: 0.8))) {
                driftIn = true
            }
        }
    }

    // MARK: Pieces

    private func backdrop(size: CGSize) -> some View {
        ZStack {
            Palette.void

            // Three objects on an otherwise empty board — the product's whole
            // idea, stated before a single word of copy.
            DecorationView(kind: .star, size: 74, color: Palette.accent)
                .rotationEffect(.degrees(driftIn ? 12 : 2))
                .position(x: size.width * 0.16, y: size.height * 0.26)
                .opacity(0.55)

            DecorationView(kind: .squiggle, size: 110, color: Palette.pinkAccent)
                .position(x: size.width * 0.84, y: size.height * 0.18)
                .opacity(0.45)

            StickerBadge(text: "since 2026", style: .neon, rotation: driftIn ? -8 : -2, shape: .pill)
                .position(x: size.width * 0.82, y: size.height * 0.74)
                .opacity(0.85)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var brand: some View {
        VStack(spacing: 10) {
            Text("Memories")
                .textStyle(TypeScale.displayLG)
                .foregroundStyle(Palette.onSurface)

            Text("A board for everything worth keeping.")
                .textStyle(TypeScale.bodyLG)
                .foregroundStyle(Palette.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 18) {
            field(
                title: "Username",
                prompt: "yourname",
                text: $username,
                icon: "at",
                autocapitalise: false
            )

            field(
                title: "Display name",
                prompt: "What friends should see",
                text: $displayName,
                icon: "person",
                autocapitalise: true
            )

            if let error = account.authError {
                FieldError(text: error)
            }

            NeonButton(title: "Start keeping memories", icon: "arrow.right") {
                account.signIn(username: username, displayName: displayName)
            }
            .frame(maxWidth: .infinity)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.45)

            Text("No password, no email, no server. Your account lives on this iPad only — this is the identity layer a real backend would slot into.")
                .textStyle(TypeScale.bodySM)
                .foregroundStyle(Palette.onSurfaceVariant.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .glassPanel(cornerRadius: Radius.panel)
    }

    private func field(
        title: String,
        prompt: String,
        text: Binding<String>,
        icon: String,
        autocapitalise: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .textStyle(TypeScale.labelTiny)
                .foregroundStyle(Palette.onSurfaceVariant)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Palette.onSurfaceVariant)

                TextField(prompt, text: text)
                    .textFieldStyle(.plain)
                    .textStyle(TypeScale.bodyMD)
                    .foregroundStyle(Palette.onSurface)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(autocapitalise ? .words : .never)
                    .submitLabel(.next)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Palette.charcoal, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            }
        }
    }

    private var guestButton: some View {
        VStack(spacing: 10) {
            Button {
                account.continueAsGuest()
            } label: {
                Text("Look around first")
                    .textStyle(TypeScale.bodyMD)
                    .fontWeight(.medium)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.white.opacity(0.05)))
                    .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())

            Text("You can claim a username later without losing anything.")
                .textStyle(TypeScale.labelTiny)
                .foregroundStyle(Palette.onSurfaceVariant.opacity(0.8))
        }
    }
}
