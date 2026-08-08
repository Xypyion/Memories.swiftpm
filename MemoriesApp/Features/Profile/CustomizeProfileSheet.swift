import PhotosUI
import SwiftUI

/// Editing the Personality Board.
///
/// Kept as a plain form on purpose. The board itself is the expressive surface;
/// making its *editor* expressive too would put decoration in the way of the one
/// place the user needs to type quickly.
struct CustomizeProfileSheet: View {

    @Binding var profile: UserProfile

    @Environment(\.dismiss) private var dismiss

    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var hobbyDraft = ""

    var body: some View {
        NavigationStack {
            Form {
                avatarSection
                identitySection
                statusSection
                nowPlayingSection
                hobbiesSection
            }
            .scrollContentBackground(.hidden)
            .background(Palette.surface)
            .navigationTitle("Customize profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationBackground(Palette.surface)
        .onChange(of: avatarPickerItem) { _, newValue in
            guard let newValue else { return }
            Task { await importAvatar(newValue) }
        }
    }

    // MARK: Sections

    private var avatarSection: some View {
        Section {
            HStack(spacing: 18) {
                AvatarView(
                    name: profile.displayName,
                    seed: profile.avatarSeed,
                    size: 72,
                    ring: .neon,
                    imageName: profile.avatarImageName
                )

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                        Text("Choose photo")
                            .textStyle(TypeScale.sticker)
                            .foregroundStyle(Palette.neon)
                    }

                    if profile.avatarImageName != nil {
                        Button("Use generated avatar", role: .destructive) {
                            if let previous = profile.avatarImageName {
                                ImageStore.delete(named: previous)
                            }
                            profile.avatarImageName = nil
                        }
                        .textStyle(TypeScale.bodySM)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
        }
    }

    private var identitySection: some View {
        Section("You") {
            TextField("Display name", text: $profile.displayName)
            TextField("Handle", text: $profile.handle)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Stepper(value: $profile.streak, in: 0 ... 999) {
                LabeledContent("Streak", value: "\(profile.streak)")
            }
        }
    }

    private var statusSection: some View {
        Section("Status bubble") {
            TextField("What are you doing?", text: $profile.statusText, axis: .vertical)
                .lineLimit(2 ... 4)
        }
    }

    private var nowPlayingSection: some View {
        Section("On the record") {
            TextField("Track", text: $profile.nowPlaying.title)
            TextField("Artist", text: $profile.nowPlaying.artist)
        }
    }

    private var hobbiesSection: some View {
        Section("The locker door") {
            ForEach(profile.hobbies, id: \.self) { hobby in
                Text(hobby)
            }
            .onDelete { offsets in
                profile.hobbies.remove(atOffsets: offsets)
            }

            HStack {
                TextField("Add a sticker", text: $hobbyDraft)
                    .onSubmit(addHobby)

                Button("Add", action: addHobby)
                    .disabled(hobbyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(Palette.neon)
            }
        }
    }

    // MARK: Actions

    private func addHobby() {
        let trimmed = hobbyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !profile.hobbies.contains(trimmed) else { return }
        profile.hobbies.append(trimmed)
        hobbyDraft = ""
    }

    @MainActor
    private func importAvatar(_ pickerItem: PhotosPickerItem) async {
        defer { avatarPickerItem = nil }

        guard
            let data = try? await pickerItem.loadTransferable(type: Data.self),
            let name = ImageStore.save(data: data)
        else { return }

        if let previous = profile.avatarImageName {
            ImageStore.delete(named: previous)
        }
        profile.avatarImageName = name
    }
}
