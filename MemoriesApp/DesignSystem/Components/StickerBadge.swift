import SwiftUI

/// A vinyl sticker. Hard offset shadow, dark keyline, always slightly rotated —
/// the three things that separate "sticker stuck on the board" from "label
/// printed in the layout".
struct StickerBadge: View {

    let text: String
    var style: StickerStyle = .neon
    var rotation: Double = -2
    var icon: String? = nil
    var shape: BadgeShape = .rect

    enum BadgeShape {
        case rect
        case pill
    }

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .symbolStyle(TypeScale.sticker, size: 13, weight: .bold)
            }
            Text(text.uppercased())
                .textStyle(TypeScale.sticker)
        }
        .foregroundStyle(style.foreground)
        .padding(.horizontal, Space.stickerPadding)
        .padding(.vertical, 6)
        .background {
            switch shape {
            case .rect:
                RoundedRectangle(cornerRadius: Radius.eight, style: .continuous)
                    .fill(style.background)
            case .pill:
                Capsule(style: .continuous)
                    .fill(style.background)
            }
        }
        .overlay {
            if style.needsKeyline {
                keyline
            }
        }
        .stickerShadow()
        .rotationEffect(.degrees(rotation))
        .fixedSize()
    }

    @ViewBuilder
    private var keyline: some View {
        switch shape {
        case .rect:
            RoundedRectangle(cornerRadius: Radius.eight, style: .continuous)
                .strokeBorder(Palette.ink, lineWidth: 2)
        case .pill:
            Capsule(style: .continuous)
                .strokeBorder(Palette.ink, lineWidth: 2)
        }
    }
}

extension StickerStyle {

    var background: Color {
        switch self {
        case .neon: Palette.neon
        case .pink: Palette.pink
        case .paper: Palette.paper
        case .ink: Palette.ink
        case .blush: Palette.blush
        case .lilac: Palette.lilac
        }
    }

    var foreground: Color {
        switch self {
        case .neon: Palette.onNeon
        case .pink: Palette.onPink
        case .paper: Palette.onPaper
        case .ink: Palette.neon
        case .blush: Palette.onBlush
        case .lilac: Palette.onLilac
        }
    }

    /// The dark keyline only helps on light stickers; on the black sticker it
    /// would disappear, so it's suppressed.
    var needsKeyline: Bool {
        self != .ink
    }

    var displayName: String {
        switch self {
        case .neon: "Neon"
        case .pink: "Pink"
        case .paper: "Paper"
        case .ink: "Ink"
        case .blush: "Blush"
        case .lilac: "Lilac"
        }
    }
}
