import SwiftUI

/// Double-tapping any object opens its inspector.
///
/// One sheet handles every item type rather than four separate editors, so the
/// interaction to learn is "double-tap the thing" regardless of what the thing
/// is.
struct ItemInspector: View {

    @Binding var item: CanvasItem
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                switch item.kind {
                case .photo(let payload), .polaroid(let payload):
                    photoSection(payload)
                    frameSection
                case .note(let payload):
                    noteSection(payload)
                case .sticker(let payload):
                    stickerSection(payload)
                case .decoration:
                    decorationSection
                }

                filingSection
                geometrySection
            }
            .scrollContentBackground(.hidden)
            .background(Palette.surface)
            .navigationTitle(item.kind.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.surface)
    }

    // MARK: Sections

    @ViewBuilder
    private func photoSection(_ payload: PhotoPayload) -> some View {
        Section("Caption") {
            TextField(
                "Say something about this",
                text: Binding(
                    get: { payload.caption },
                    set: { newValue in
                        var updated = payload
                        updated.caption = newValue
                        item.photoPayload = updated
                    }
                ),
                axis: .vertical
            )
            .lineLimit(1 ... 3)

            Toggle(
                "Favourite",
                isOn: Binding(
                    get: { payload.isFavorite },
                    set: { newValue in
                        var updated = payload
                        updated.isFavorite = newValue
                        item.photoPayload = updated
                    }
                )
            )
            .tint(Palette.pink)
        }
    }

    private var frameSection: some View {
        Section("Frame") {
            Picker("Style", selection: frameBinding) {
                Text("Mounted print").tag(0)
                Text("Polaroid").tag(1)
            }
            .pickerStyle(.segmented)
        }
    }

    private var frameBinding: Binding<Int> {
        Binding(
            get: {
                if case .polaroid = item.kind { return 1 }
                return 0
            },
            set: { newValue in
                guard let payload = item.kind.photo else { return }
                item.kind = newValue == 1 ? .polaroid(payload) : .photo(payload)
            }
        )
    }

    @ViewBuilder
    private func noteSection(_ payload: NotePayload) -> some View {
        Section("Text") {
            TextField(
                "Write something",
                text: Binding(
                    get: { payload.text },
                    set: { item.kind = .note(NotePayload(text: $0, color: payload.color)) }
                ),
                axis: .vertical
            )
            .lineLimit(3 ... 8)
        }

        Section("Paper") {
            Picker(
                "Colour",
                selection: Binding(
                    get: { payload.color },
                    set: { item.kind = .note(NotePayload(text: payload.text, color: $0)) }
                )
            ) {
                ForEach(NoteColor.allCases, id: \.self) { color in
                    Text(color.displayName).tag(color)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private func stickerSection(_ payload: StickerPayload) -> some View {
        Section("Label") {
            TextField(
                "Sticker text",
                text: Binding(
                    get: { payload.text },
                    set: { item.kind = .sticker(StickerPayload(text: $0, style: payload.style)) }
                )
            )
        }

        Section("Vinyl") {
            Picker(
                "Style",
                selection: Binding(
                    get: { payload.style },
                    set: { item.kind = .sticker(StickerPayload(text: payload.text, style: $0)) }
                )
            ) {
                ForEach(StickerStyle.allCases, id: \.self) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var decorationSection: some View {
        Section("Mark") {
            Picker("Shape", selection: decorationBinding) {
                ForEach(DecorationKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue.capitalized).tag(kind)
                }
            }
        }
    }

    private var decorationBinding: Binding<DecorationKind> {
        Binding(
            get: {
                if case .decoration(let kind) = item.kind { return kind }
                return .star
            },
            set: { item.kind = .decoration($0) }
        )
    }

    private var geometrySection: some View {
        Section("Placement") {
            LabeledContent("Size") {
                Slider(value: $item.width, in: 120 ... 460)
                    .tint(Palette.neon)
            }

            LabeledContent("Rotation") {
                Slider(value: $item.rotation, in: -30 ... 30)
                    .tint(Palette.neon)
            }

            Button("Straighten") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    item.rotation = 0
                    item.scale = 1
                }
            }
            .foregroundStyle(Palette.accent)
        }
    }

    /// Filing. Drives the Memories tab's day and topic grouping, so it lives on
    /// the item rather than in a separate "organise" mode the user has to find.
    @ViewBuilder
    private var filingSection: some View {
        if item.kind.isPhotographic {
            Section("Filing") {
                Picker("Topic", selection: topicBinding) {
                    Text("Unfiled").tag("")
                    ForEach(MemoryTopic.catalogue) { topic in
                        Text(topic.name).tag(topic.name)
                    }
                }

                DatePicker(
                    "Happened",
                    selection: dateBinding,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
    }

    private var topicBinding: Binding<String> {
        Binding(
            get: { item.topic ?? "" },
            set: { item.topic = $0.isEmpty ? nil : $0 }
        )
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { item.createdAt ?? Date() },
            set: { item.createdAt = $0 }
        )
    }
}
