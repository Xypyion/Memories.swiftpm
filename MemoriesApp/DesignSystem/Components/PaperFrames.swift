import SwiftUI

// The physical-object vocabulary: tape, pins, mounted prints, polaroids and
// paper notes. Everything a user places on a board is one of these.

/// A torn strip of translucent tape. Deliberately imperfect — slightly rotated,
/// slightly transparent, with a soft edge.
struct TapeStrip: View {

    var width: CGFloat = 64
    var rotation: Double = -3

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.42),
                        Color.white.opacity(0.26),
                        Color.white.opacity(0.40)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: 26)
            .overlay(Rectangle().strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5))
            .background(.ultraThinMaterial)
            .rotationEffect(.degrees(rotation))
            .allowsHitTesting(false)
    }
}

/// A pushpin head, for boards that are pinned rather than taped.
struct PushPin: View {

    var color: Color = Palette.pink

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.95), color],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: 1,
                    endRadius: 14
                )
            )
            .frame(width: 22, height: 22)
            .overlay {
                Circle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: 6, height: 6)
            }
            .overlay {
                Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
            .allowsHitTesting(false)
    }
}

/// A photo mounted on paper — 12pt white border, near-square corners like a
/// real print, caption row underneath.
struct MountedPhoto: View {

    let payload: PhotoPayload
    let seed: Int
    var width: CGFloat
    var showsCaption: Bool = true

    private var imageHeight: CGFloat { width / payload.aspect }

    var body: some View {
        VStack(spacing: 0) {
            MemoryImage(payload: payload, seed: seed)
                .frame(width: width, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: Radius.print, style: .continuous))

            if showsCaption {
                HStack(spacing: 8) {
                    Text(payload.caption.isEmpty ? "Untitled" : payload.caption)
                        .textStyle(TypeScale.bodySM)
                        .fontWeight(.medium)
                        .foregroundStyle(Palette.onPaper)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if payload.isFavorite {
                        Circle()
                            .fill(Palette.pink)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().strokeBorder(Palette.paper, lineWidth: 2).padding(-2))
                    }
                }
                .frame(width: width)
                .padding(.top, 10)
            }
        }
        .padding(12)
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: Radius.eight, style: .continuous))
        .paperShadow()
    }
}

/// A polaroid — square image, deep bottom margin for the handwritten caption.
struct PolaroidPhoto: View {

    let payload: PhotoPayload
    let seed: Int
    var width: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            MemoryImage(payload: payload, seed: seed)
                .frame(width: width, height: width)
                .clipShape(RoundedRectangle(cornerRadius: Radius.print, style: .continuous))

            Text(payload.caption.isEmpty ? "…" : payload.caption)
                .textStyle(TypeScale.bodyLG)
                .italic()
                .foregroundStyle(Palette.onPaper.opacity(0.72))
                .frame(width: width, alignment: .leading)
                .rotationEffect(.degrees(-1))
                .padding(.top, 14)
                .padding(.bottom, 6)
                .lineLimit(2)
        }
        .padding(14)
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: Radius.eight, style: .continuous))
        .paperShadow()
    }
}

/// A sticky note. The pin dot in the corner is the one piece of chrome; the
/// rest is just paper and ink.
struct PaperNote: View {

    let text: String
    let color: NoteColor
    var width: CGFloat

    var body: some View {
        Text(text.isEmpty ? "Tap to write…" : text)
            .textStyle(TypeScale.headline)
            .foregroundStyle(color.ink)
            .multilineTextAlignment(.leading)
            .frame(width: width, alignment: .topLeading)
            .padding(22)
            .background(color.stock)
            .clipShape(RoundedRectangle(cornerRadius: Radius.eight, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Palette.pink)
                    .frame(width: 10, height: 10)
                    .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                    .padding(10)
            }
            .paperShadow()
    }
}

extension NoteColor {

    var stock: Color {
        switch self {
        case .blush: Palette.blush
        case .paper: Palette.paper
        case .neon: Palette.neon
        case .lilac: Palette.lilac
        }
    }

    var ink: Color {
        switch self {
        case .blush: Palette.onBlush
        case .paper: Palette.onPaper
        case .neon: Palette.onNeon
        case .lilac: Palette.onLilac
        }
    }

    var displayName: String {
        switch self {
        case .blush: "Blush"
        case .paper: "Paper"
        case .neon: "Neon"
        case .lilac: "Lilac"
        }
    }
}
