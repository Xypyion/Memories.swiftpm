import SwiftUI

/// The Liquid Glass dock.
///
/// It replaces the iPad sidebar on purpose: a sidebar would permanently claim
/// ~320pt of the creative workspace, and this product's whole argument is that
/// the canvas should run to the edges of the display. A floating capsule costs
/// roughly 90pt of *overlay*, not layout, and content bleeds behind it.
struct LiquidGlassTabBar: View {

    @Binding var selection: AppTab
    var badges: Set<AppTab> = []

    @Namespace private var indicator

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                item(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .liquidGlass(Capsule(style: .continuous), tint: 0.05, strokeOpacity: 0.20, shadowRadius: 32)
        .padding(.bottom, Space.unit * 3)
    }

    private func item(for tab: AppTab) -> some View {
        let isSelected = selection == tab

        return Button {
            guard selection != tab else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                selection = tab
            }
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
            .frame(width: 86, height: 58)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Palette.neon)
                        .matchedGeometryEffect(id: "tab.indicator", in: indicator)
                        .neonGlow(radius: 18, opacity: 0.45)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
