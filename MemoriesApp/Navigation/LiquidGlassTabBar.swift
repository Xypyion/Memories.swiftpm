import SwiftUI

/// The floating dock.
///
/// It replaces the iPad sidebar on purpose: a sidebar would permanently claim
/// ~320pt of the creative workspace, and this product's whole argument is that
/// the canvas should run to the edges of the display. A floating capsule costs
/// roughly 90pt of *overlay*, not layout, and content bleeds behind it.
///
/// **Why it stopped being laggy.** Three things, all of which were compositing
/// costs rather than layout costs:
///
/// 1. A `.shadow()` behind a `Material` forces the capsule into an offscreen
///    render pass every frame the content behind it moves. Gone.
/// 2. The border was a `LinearGradient` stroke, a second gradient evaluation per
///    frame on top of the blur. Now a flat hairline.
/// 3. `matchedGeometryEffect` animated the neon pill between items. It looked
///    good and cost a geometry resolution pass on every render; a plain
///    background on the selected item is indistinguishable at this size.
///
/// **Why the labels stay readable.** The dock floats over arbitrary content — a
/// black cover photo while the app is in light mode. A pure `Material` samples
/// whatever is behind it, so the backdrop could go dark while the label stayed
/// dark. `solidGlass` lays an opaque theme surface over the blur, which fixes
/// the contrast in both directions.
struct LiquidGlassTabBar: View {

    @Binding var selection: AppTab
    var badges: Set<AppTab> = []

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                item(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .solidGlass(Capsule(style: .continuous))
        .padding(.bottom, Space.unit * 3)
        // A fixed capsule floating over the canvas: it grows with the reader's
        // text size, but only to the last non-accessibility step. Past that it
        // would be wider than the iPad.
        .fixedLayoutTypeCeiling()
    }

    private func item(for tab: AppTab) -> some View {
        let isSelected = selection == tab

        return Button {
            guard selection != tab else { return }
            selection = tab
        } label: {
            VStack(spacing: 5) {
                Image(systemName: isSelected ? tab.filledIcon : tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .frame(height: 24)
                    .overlay(alignment: .topTrailing) {
                        if badges.contains(tab) {
                            Circle()
                                .fill(Palette.pink)
                                .frame(width: 8, height: 8)
                                .offset(x: 7, y: -2)
                        }
                    }

                Text(tab.title.uppercased())
                    .textStyle(TypeScale.labelTiny)
            }
            .foregroundStyle(isSelected ? Palette.onNeon : Palette.onSurfaceVariant)
            // Minimums rather than fixed dimensions, so a scaled-up label
            // widens its own pill instead of being clipped by it.
            .frame(minWidth: 86, minHeight: 58)
            .background {
                if isSelected {
                    Capsule(style: .continuous).fill(Palette.neon)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
