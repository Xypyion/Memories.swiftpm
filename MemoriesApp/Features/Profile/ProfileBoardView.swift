import SwiftUI
import UIKit

/// The Personality Board.
///
/// A profile in this product is not a settings page with an avatar on top — it
/// is the user's own board, made of the same objects as everything else:
/// stickers, paper, tilted photos, a spinning record. Everything here is
/// something the user chose to put down, which is why there are no read-only
/// statistics rows.
struct ProfileBoardView: View {

    @EnvironmentObject private var store: AppStore

    @State private var showsCustomize = false
    @State private var didCopyHandle = false

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 780

            ScrollView {
                VStack(spacing: Space.unit * 5) {
                    hero
                    actionRow
                    widgets(isWide: isWide)
                }
                .padding(.horizontal, isWide ? Space.canvasMargin : Space.unit * 2.5)
                .padding(.top, Space.unit * 7)
                .padding(.bottom, Space.dockClearance)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background {
                ZStack {
                    Palette.void
                    GlowBlob(color: Palette.pink, size: 420, opacity: 0.16)
                        .offset(x: -geo.size.width * 0.3, y: -120)
                    GlowBlob(color: Palette.neon, size: 360, opacity: 0.10)
                        .offset(x: geo.size.width * 0.35, y: 260)
                }
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showsCustomize) {
            CustomizeProfileSheet(profile: $store.profile)
        }
    }

    // MARK: Hero

    private var hero: some View {
        ZStack(alignment: .top) {
            // Avatar, hand-placed rather than centred-and-squared.
            AvatarView(
                name: store.profile.displayName,
                seed: store.profile.avatarSeed,
                size: 180,
                ring: .neon,
                imageName: store.profile.avatarImageName
            )
            .rotationEffect(.degrees(2))
            .tactileShadow()
            .padding(.top, 24)

            // Status bubble — a physical speech bubble, tail and all.
            StatusBubble(text: store.profile.statusText)
                .offset(x: 118, y: -6)
                .rotationEffect(.degrees(-6))

            // Streak badge, deliberately overlapping the avatar's lower edge.
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("\(store.profile.streak)")
                        .textStyle(TypeScale.labelCaps)
                        .fontWeight(.bold)
                }
                Text(store.profile.displayName)
                    .textStyle(TypeScale.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Palette.onPink)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Palette.pink))
            .stickerShadow()
            .rotationEffect(.degrees(3))
            .offset(y: 196)
        }
        .frame(height: 290)
        .frame(maxWidth: .infinity)
    }

    // MARK: Actions

    private var actionRow: some View {
        HStack(spacing: 14) {
            Button {
                showsCustomize = true
            } label: {
                Text("customize profile")
                    .textStyle(TypeScale.bodyLG)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.onPaper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .fill(Palette.paper)
                    )
                    .paperShadow()
            }
            .buttonStyle(PressableButtonStyle())

            GlassIconButton(
                icon: didCopyHandle ? "checkmark" : "square.and.arrow.up",
                size: 56,
                isActive: didCopyHandle
            ) {
                UIPasteboard.general.string = store.profile.handle
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    didCopyHandle = true
                }
            }
            .accessibilityLabel("Copy handle")
        }
        .frame(maxWidth: 460)
    }

    // MARK: Widgets

    private func widgets(isWide: Bool) -> some View {
        VStack(spacing: Space.objectGap) {
            if isWide {
                HStack(alignment: .top, spacing: Space.objectGap) {
                    VinylWidget(nowPlaying: store.profile.nowPlaying)
                        .frame(maxWidth: .infinity)

                    VStack(spacing: Space.objectGap) {
                        pinnedRow
                        hobbyPanel
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VinylWidget(nowPlaying: store.profile.nowPlaying)
                pinnedRow
                hobbyPanel
            }

            boardsStrip
        }
    }

    private var pinnedRow: some View {
        HStack(spacing: Space.objectGap) {
            ForEach(store.profile.pinnedArtists) { artist in
                VStack(spacing: 10) {
                    MemoryTexture(seed: artist.seed)
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

            FlowRow(spacing: 10) {
                ForEach(store.profile.hobbies, id: \.self) { hobby in
                    StickerBadge(
                        text: hobby,
                        style: hobbyStyle(for: hobby),
                        rotation: Double((hobby.count % 5) - 2),
                        shape: .pill
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: Radius.widget)
    }

    private func hobbyStyle(for hobby: String) -> StickerStyle {
        let styles: [StickerStyle] = [.neon, .pink, .paper, .ink]
        return styles[abs(Int.seed(from: hobby)) % styles.count]
    }

    private var boardsStrip: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Boards")
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onSurfaceVariant)

            ScrollView(.horizontal) {
                HStack(spacing: Space.objectGap) {
                    ForEach(store.boards) { board in
                        Button {
                            store.openBoardID = board.id
                            store.tab = .board
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                BoardCollage(board: board)
                                    .frame(width: 150, height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))

                                Text(board.title)
                                    .textStyle(TypeScale.bodySM)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Palette.onSurface)
                                    .lineLimit(1)
                            }
                            .frame(width: 150, alignment: .leading)
                        }
                        .buttonStyle(LiftButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: Radius.widget)
    }

}

/// The speech bubble from the profile hero. The trailing dots are the tail —
/// three shrinking circles, the way a comic draws a thought.
struct StatusBubble: View {

    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .textStyle(TypeScale.bodyMD)
                .fontWeight(.medium)
                .foregroundStyle(Palette.onPaper)
                .multilineTextAlignment(.center)
                .frame(width: 168)
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
    }
}

/// The record widget. The disc spins continuously as an ambient signal of
/// "current vibe" — it is a display of what the user set, not a player, so it
/// carries no transport controls it could not honour.
struct VinylWidget: View {

    let nowPlaying: NowPlaying

    @State private var angle: Double = 0

    var body: some View {
        VStack(spacing: 22) {
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

                MemoryTexture(seed: nowPlaying.artSeed)
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
                    .overlay {
                        Circle().fill(Palette.void).frame(width: 12, height: 12)
                    }
                    .overlay {
                        Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    }
            }
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.6), radius: 20, y: 12)
            .onAppear {
                withAnimation(.linear(duration: 16).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }

            VStack(spacing: 4) {
                Text(nowPlaying.title)
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
