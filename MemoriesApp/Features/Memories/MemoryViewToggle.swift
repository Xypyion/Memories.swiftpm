import SwiftUI

/// Segmented control for how the Memories tab is organised.
///
/// Driven by `MemoryGrouping.allCases`, so a new scheme appears here the moment
/// it's added to the enum — there is no list of options to keep in sync.
struct MemoryViewToggle: View {

    @Binding var grouping: MemoryGrouping

    @Namespace private var indicator
    @Environment(\.motionPolicy) private var motion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MemoryGrouping.allCases) { option in
                segment(option)
            }
        }
        .padding(4)
        .background(Palette.charcoal, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
        .fixedSize()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Organise memories")
    }

    private func segment(_ option: MemoryGrouping) -> some View {
        let isSelected = grouping == option

        return Button {
            guard grouping != option else { return }
            withAnimation(motion.animation(.spring(response: 0.35, dampingFraction: 0.82))) {
                grouping = option
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: option.icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(option.title)
                    .textStyle(TypeScale.sticker)
            }
            .foregroundStyle(isSelected ? Palette.onNeon : Palette.onSurfaceVariant)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Palette.neon)
                        .matchedGeometryEffect(id: "memory.grouping", in: indicator)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// The heading above each run of memories. One component for both schemes, so a
/// date header and a topic header can never drift apart visually.
struct MemorySectionHeader: View {

    let section: MemorySection

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(section.tint)
                .frame(width: 32, height: 32)
                .background(Circle().fill(section.tint.opacity(0.14)))

            VStack(alignment: .leading, spacing: 1) {
                Text(section.title)
                    .textStyle(TypeScale.headline)
                    .foregroundStyle(Palette.onSurface)
                    .lineLimit(1)

                Text(section.subtitle.uppercased())
                    .textStyle(TypeScale.labelTiny)
                    .foregroundStyle(Palette.onSurfaceVariant)
            }

            Spacer(minLength: 8)
        }
        .padding(.bottom, 2)
        .accessibilityElement(children: .combine)
    }
}
