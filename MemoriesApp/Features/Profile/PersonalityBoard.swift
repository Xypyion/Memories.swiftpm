import SwiftUI

/// The expressive half of a profile: status bubble, record, pinned artists,
/// hobby stickers.
///
/// Extracted from the old `ProfileBoardView` so it can be *composed* rather than
/// being the whole tab. Your own profile shows it under your identity header; a
/// friend's profile shows the same thing, read-only. One component, two
/// contexts — which is also the guarantee that a friend's board never drifts
/// away from how yours looks.
struct PersonalityBoardSection: View {

    let profile: UserProfile
    var isEditable: Bool = false
    var onEdit: (() -> Void)?

    var body: some View {
        VStack(spacing: Space.objectGap) {
            statusRow

            VinylWidget(nowPlaying: profile.nowPlaying)

            if !profile.pinnedArtists.isEmpty {
                pinnedRow
            }

            if !profile.hobbies.isEmpty || isEditable {
                hobbyPanel
            }
        }
    }

    private var statusRow: some View {
        HStack(alignment: .top, spacing: 14) {
            StatusBubble(text: profile.statusText)

            Spacer(minLength: 0)

            if isEditable, let onEdit {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .textStyle(TypeScale.sticker)
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Palette.neon.opacity(0.14)))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private var pinnedRow: some View {
        HStack(spacing: Space.objectGap) {
            ForEach(profile.pinnedArtists) { artist in
                VStack(spacing: 10) {
                    MemoryTexture(seed: artist.seed, detail: .thumbnail)
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                        .rotationEffect(.degrees(artist.seed.isMultiple(of: 2) ? 6 : -4))
                        .paperShadow()

                    Text(artist.name)
                        .textStyle(TypeScale.bodySM)
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.onSurface)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .glassPanel(cornerRadius: Radius.widget)
    }

    private var hobbyPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("The locker door")
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onSurfaceVariant)

            if profile.hobbies.isEmpty {
                Text("Nothing on the door yet.")
                    .textStyle(TypeScale.bodyMD)
                    .foregroundStyle(Palette.onSurfaceVariant)
            } else {
                FlowRow(spacing: 10) {
                    ForEach(profile.hobbies, id: \.self) { hobby in
                        StickerBadge(
                            text: hobby,
                            style: PersonalityBoardSection.hobbyStyle(for: hobby),
                            rotation: Double((hobby.count % 5) - 2),
                            shape: .pill
                        )
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: Radius.widget)
    }

    /// Deterministic from the text, so a sticker keeps its colour forever.
    static func hobbyStyle(for hobby: String) -> StickerStyle {
        let styles: [StickerStyle] = [.neon, .pink, .paper, .ink]
        return styles[Int.seed(from: hobby) % styles.count]
    }
}

/// The speech bubble from the profile hero. The trailing dots are the tail —
/// three shrinking circles, the way a comic draws a thought.
struct StatusBubble: View {

    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text.isEmpty ? "…" : text)
                .textStyle(TypeScale.bodyMD)
                .fontWeight(.medium)
                .foregroundStyle(Palette.onPaper)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 210)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Palette.paper)
                )
                .paperShadow()

            HStack(spacing: 3) {
                Circle().fill(Palette.paper).frame(width: 11, height: 11)
                Circle().fill(Palette.paper).frame(width: 7, height: 7)
                Circle().fill(Palette.paper).frame(width: 4, height: 4)
            }
            .offset(x: -46, y: 4)
        }
        .rotationEffect(.degrees(-2))
    }
}

/// The record widget. The disc spins continuously as an ambient signal of
/// "current vibe" — it is a display of what the user set, not a player, so it
/// carries no transport controls it could not honour.
///
/// The spin stops entirely under reduced motion: a continuously rotating element
/// is exactly the kind of thing that setting exists to switch off.
struct VinylWidget: View {

    let nowPlaying: NowPlaying

    @Environment(\.motionPolicy) private var motion
    @State private var angle: Double = 0

    var body: some View {
        VStack(spacing: 22) {
            disc
                .rotationEffect(.degrees(angle))
                .shadow(color: Palette.shadowHeavy, radius: 20, y: 12)
                .onAppear(perform: startSpin)
                .onChange(of: motion.isReduced) { _, _ in startSpin() }

            VStack(spacing: 4) {
                Text(nowPlaying.title.isEmpty ? "Nothing playing" : nowPlaying.title)
                    .textStyle(TypeScale.bodyLG)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.onPink)
                    .lineLimit(1)

                Text(nowPlaying.artist)
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onPink.opacity(0.8))
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Radius.widget, style: .continuous)
                .fill(Palette.pink)
        )
        .tactileShadow()
    }

    private var disc: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0x1A1A1A), Color(hex: 0x050505)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 200, height: 200)

            ForEach(1 ... 5, id: \.self) { ring in
                Circle()
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    .frame(width: 200 - CGFloat(ring) * 18, height: 200 - CGFloat(ring) * 18)
            }

            MemoryTexture(seed: nowPlaying.artSeed, detail: .thumbnail)
                .frame(width: 84, height: 84)
                .clipShape(Circle())
                .overlay {
                    Circle().fill(Palette.ink).frame(width: 12, height: 12)
                }
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                }
        }
    }

    private func startSpin() {
        guard !motion.isReduced else {
            // Straighten the record instantly. Animating the *stop* would be
            // motion too, which is the one thing this branch exists to avoid.
            angle = 0
            return
        }
        withAnimation(.linear(duration: 16).repeatForever(autoreverses: false)) {
            angle = 360
        }
    }
}

/// Minimal wrapping row layout. `LazyVGrid` cannot wrap variable-width pills
/// without leaving ragged gaps, and stickers must sit shoulder to shoulder.
struct FlowRow: Layout {

    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
