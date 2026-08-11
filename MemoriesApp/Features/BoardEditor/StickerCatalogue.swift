import SwiftUI

/// The sticker sheet.
///
/// The board previously shipped exactly one sticker — "Vibes only" — which made
/// the sticker button feel like a bug rather than a tool. These are grouped the
/// way a real sheet of stickers is: by what you'd use them for, not
/// alphabetically.
enum StickerCatalogue {

    struct Sheet: Identifiable {
        var id: String { name }
        var name: String
        var stickers: [StickerPayload]
    }

    static let sheets: [Sheet] = [
        Sheet(name: "Moods", stickers: [
            StickerPayload(text: "Vibes only", style: .neon),
            StickerPayload(text: "No thoughts", style: .paper),
            StickerPayload(text: "Unserious", style: .pink),
            StickerPayload(text: "Feral", style: .neon),
            StickerPayload(text: "Soft launch", style: .blush),
            StickerPayload(text: "Main character", style: .pink)
        ]),
        Sheet(name: "Reactions", stickers: [
            StickerPayload(text: "!!!", style: .neon),
            StickerPayload(text: "obsessed", style: .pink),
            StickerPayload(text: "crying", style: .blush),
            StickerPayload(text: "no way", style: .paper),
            StickerPayload(text: "iconic", style: .neon),
            StickerPayload(text: "10/10", style: .ink)
        ]),
        Sheet(name: "Time", stickers: [
            StickerPayload(text: "3am", style: .ink),
            StickerPayload(text: "golden hour", style: .blush),
            StickerPayload(text: "day one", style: .neon),
            StickerPayload(text: "last summer", style: .paper),
            StickerPayload(text: "finally", style: .pink),
            StickerPayload(text: "again", style: .lilac)
        ]),
        Sheet(name: "Labels", stickers: [
            StickerPayload(text: "do not lose", style: .pink),
            StickerPayload(text: "keep forever", style: .neon),
            StickerPayload(text: "blurry but real", style: .paper),
            StickerPayload(text: "unposted", style: .ink),
            StickerPayload(text: "the good one", style: .neon),
            StickerPayload(text: "evidence", style: .lilac)
        ])
    ]
}

/// Picker sheet. Also lets the user type their own, because no catalogue will
/// ever contain the phrase somebody actually wants.
struct StickerPicker: View {

    let onPick: (StickerPayload) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var customText = ""
    @State private var customStyle: StickerStyle = .neon

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.unit * 4) {
                    customSection

                    ForEach(StickerCatalogue.sheets) { sheet in
                        VStack(alignment: .leading, spacing: 14) {
                            Text(sheet.name)
                                .textStyle(TypeScale.labelCaps)
                                .foregroundStyle(Palette.onSurfaceVariant)

                            FlowRow(spacing: 12) {
                                ForEach(sheet.stickers, id: \.text) { sticker in
                                    Button {
                                        onPick(sticker)
                                        dismiss()
                                    } label: {
                                        StickerBadge(
                                            text: sticker.text,
                                            style: sticker.style,
                                            rotation: Double((sticker.text.count % 5) - 2),
                                            shape: .pill
                                        )
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                }
                            }
                        }
                    }
                }
                .padding(Space.unit * 3)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Palette.surface)
            .navigationTitle("Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.surface)
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Write your own")
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onSurfaceVariant)

            HStack(spacing: 10) {
                TextField("Say something", text: $customText)
                    .textFieldStyle(.plain)
                    .textStyle(TypeScale.bodyMD)
                    .foregroundStyle(Palette.onSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(Palette.charcoal, in: Capsule())
                    .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
                    .onSubmit(commitCustom)

                NeonButton(title: "Add", isCompact: true, action: commitCustom)
                    .disabled(trimmedCustom.isEmpty)
                    .opacity(trimmedCustom.isEmpty ? 0.4 : 1)
            }

            Picker("Vinyl", selection: $customStyle) {
                ForEach(StickerStyle.allCases, id: \.self) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(20)
        .glassPanel(cornerRadius: Radius.panel)
    }

    private var trimmedCustom: String {
        customText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commitCustom() {
        guard !trimmedCustom.isEmpty else { return }
        onPick(StickerPayload(text: trimmedCustom, style: customStyle))
        dismiss()
    }
}
