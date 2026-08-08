import SwiftUI
import UIKit

/// A person, drawn procedurally from their name so the app has a populated
/// social graph with no bundled portrait assets.
///
/// The ring is load-bearing: neon means *on the board right now*, pink means
/// *recently active*, none means offline. Presence is communicated by the ring
/// alone, so the same component works at 24pt in a face-pile and at 180pt on
/// the profile.
struct AvatarView: View {

    let name: String
    let seed: Int
    var size: CGFloat = 48
    var ring: RingStyle = .offline
    var imageName: String? = nil

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }

    var body: some View {
        ZStack {
            if let imageName, let image = ImageStore.image(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                MemoryTexture(seed: seed)
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .padding(ring == .offline ? 0 : 2.5)
        .overlay {
            if let ringColor = ring.color {
                Circle().strokeBorder(ringColor, lineWidth: 2.5)
            }
        }
    }
}

extension RingStyle {
    var color: Color? {
        switch self {
        case .neon: Palette.neon
        case .pink: Palette.pink
        case .offline: nil
        }
    }
}

/// Overlapping avatars with an overflow counter. Used in the board header to
/// answer "who is on this board" at a glance.
struct FacePile: View {

    let people: [Friend]
    var size: CGFloat = 40
    var maxVisible: Int = 3
    var borderColor: Color = Palette.void

    private var visible: [Friend] { Array(people.prefix(maxVisible)) }
    private var overflow: Int { max(0, people.count - maxVisible) }

    var body: some View {
        HStack(spacing: -size * 0.28) {
            ForEach(visible.indices, id: \.self) { index in
                let person = visible[index]

                AvatarView(
                    name: person.name,
                    seed: person.seed,
                    size: size,
                    ring: person.ringStyle,
                    imageName: person.avatarImageName
                )
                .background(Circle().fill(borderColor).padding(-2.5))
                .zIndex(Double(visible.count - index))
            }

            if overflow > 0 {
                Text("+\(overflow)")
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .frame(width: size, height: size)
                    .background(Circle().fill(Palette.containerHigh))
                    .overlay(Circle().strokeBorder(borderColor, lineWidth: 2.5))
            }
        }
    }
}

/// A live presence dot. Pulses, because presence is the one thing on screen
/// that is genuinely changing in real time.
struct PresenceDot: View {

    var color: Color = Palette.neon
    var size: CGFloat = 10

    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(pulsing ? 2.4 : 1)
                    .opacity(pulsing ? 0 : 0.9)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    pulsing = true
                }
            }
    }
}
