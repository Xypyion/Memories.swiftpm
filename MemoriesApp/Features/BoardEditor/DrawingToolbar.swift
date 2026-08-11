import SwiftUI

/// The palette that appears while the pen is out.
///
/// It replaces the creation dock rather than stacking on top of it: while you
/// are drawing, "add a polaroid" is not the thing you are about to do, and two
/// floating bars competing for the bottom of the screen is worse than one that
/// changes.
struct DrawingToolbar: View {

    @Binding var tool: DrawingTool
    let canUndo: Bool
    let onUndo: () -> Void
    let onClear: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            colorRow
            controlRow
        }
        .padding(12)
        .solidGlass(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
    }

    private var colorRow: some View {
        HStack(spacing: 10) {
            ForEach(DrawingTool.palette, id: \.self) { hex in
                Button {
                    tool.colorHex = hex
                    if tool.mode == .eraser { tool.mode = .pen }
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 26, height: 26)
                        .overlay {
                            Circle().strokeBorder(Palette.hairlineBright, lineWidth: 1)
                        }
                        .overlay {
                            if tool.colorHex == hex, tool.mode != .eraser {
                                Circle()
                                    .strokeBorder(Palette.onSurface, lineWidth: 2)
                                    .padding(-4)
                            }
                        }
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(Color(hex: hex).description)
            }
        }
        .padding(.horizontal, 4)
    }

    private var controlRow: some View {
        HStack(spacing: 8) {
            ForEach(DrawingTool.Mode.allCases) { mode in
                Button {
                    tool.mode = mode
                } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(tool.mode == mode ? Palette.onNeon : Palette.onSurfaceVariant)
                        .frame(width: 42, height: 38)
                        .background {
                            if tool.mode == mode {
                                RoundedRectangle(cornerRadius: Radius.eight, style: .continuous)
                                    .fill(Palette.neon)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(mode.title)
            }

            Divider().frame(height: 26)

            widthSlider

            Divider().frame(height: 26)

            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(canUndo ? Palette.onSurfaceVariant : Palette.onSurfaceVariant.opacity(0.3))
                    .frame(width: 36, height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!canUndo)
            .accessibilityLabel("Undo stroke")

            Button(action: onClear) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(canUndo ? Palette.pinkAccent : Palette.onSurfaceVariant.opacity(0.3))
                    .frame(width: 36, height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!canUndo)
            .accessibilityLabel("Clear all drawing")

            NeonButton(title: "Done", isCompact: true, action: onDone)
                .padding(.leading, 2)
        }
    }

    private var widthSlider: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Palette.onSurfaceVariant)
                .frame(width: max(4, tool.width / 3.2), height: max(4, tool.width / 3.2))
                .frame(width: 14)

            Slider(
                value: tool.mode == .highlighter ? $tool.highlighterWidth : $tool.penWidth,
                in: tool.mode == .highlighter ? 12 ... 56 : 1 ... 22
            )
            .frame(width: 108)
            .tint(Palette.accent)
        }
        .accessibilityLabel("Stroke width")
    }
}
