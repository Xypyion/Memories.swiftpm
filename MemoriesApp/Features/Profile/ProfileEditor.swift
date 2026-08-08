import PhotosUI
import SwiftUI

/// Editing your identity and your Personality Board, in one place.
///
/// **Draft semantics.** The previous version wrote every keystroke straight to
/// the store, which meant "Cancel" was a lie — there was nothing left to cancel.
/// This edits a local draft and commits it only on Save, so Cancel genuinely
/// discards, validation can block a bad save, and the user gets one clear
/// confirmation at the end.
///
/// The form is deliberately plain. The board is the expressive surface;
/// decorating its *editor* would put ornament between the user and the one
/// screen where they need to type quickly.
struct ProfileEditor: View {

    let account: UserAccount
    let profile: UserProfile

    /// Commits both halves at once, so a save can never land identity without
    /// personality or vice versa.
    let onSave: (UserAccount, UserProfile) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draftAccount: UserAccount
    @State private var draftProfile: UserProfile
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var hobbyDraft = ""
    @State private var confirmingDiscard = false
    /// Errors only appear once the user has tried to save, so the form doesn't
    /// scold them while they're still typing their first character.
    @State private var hasAttemptedSave = false

    init(
        account: UserAccount,
        profile: UserProfile,
        onSave: @escaping (UserAccount, UserProfile) -> Void
    ) {
        self.account = account
        self.profile = profile
        self.onSave = onSave
        _draftAccount = State(initialValue: account)
        _draftProfile = State(initialValue: profile)
    }

    // MARK: Validation

    private var usernameError: String? {
        AccountValidator.usernameProblem(AccountValidator.normalisedUsername(draftAccount.username))
    }

    private var displayNameError: String? {
        AccountValidator.displayNameProblem(draftAccount.displayName)
    }

    private var bioError: String? {
        AccountValidator.bioProblem(draftAccount.bio)
    }

    private var isValid: Bool {
        usernameError == nil && displayNameError == nil && bioError == nil
    }

    private var hasChanges: Bool {
        draftAccount != account || draftProfile != profile
    }

    var body: some View {
        NavigationStack {
            Form {
                avatarSection
                identitySection
                bioSection
                statusSection
                nowPlayingSection
                hobbiesSection
            }
            .scrollContentBackground(.hidden)
            .background(Palette.surface)
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges {
                            confirmingDiscard = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!hasChanges)
                }
            }
            .confirmationDialog(
                "Discard changes?",
                isPresented: $confirmingDiscard,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
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
                    name: draftAccount.displayName,
                    seed: draftAccount.avatarSeed,
                    size: 76,
                    ring: .neon,
                    imageName: draftAccount.avatarImageName
                )

                VStack(alignment: .leading, spacing: 10) {
                    PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                        Label("Choose photo", systemImage: "photo")
                            .textStyle(TypeScale.bodyMD)
                            .foregroundStyle(Palette.accent)
                    }

                    if draftAccount.avatarImageName != nil {
                        Button("Use generated avatar", role: .destructive) {
                            draftAccount.avatarImageName = nil
                        }
                        .textStyle(TypeScale.bodySM)
                    } else {
                        Button("Shuffle generated avatar") {
                            draftAccount.avatarSeed = Int.random(in: 0 ..< 100_000)
                        }
                        .textStyle(TypeScale.bodySM)
                        .foregroundStyle(Palette.onSurfaceVariant)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
        }
    }

    private var identitySection: some View {
        Section("You") {
            VStack(alignment: .leading, spacing: 6) {
                TextField("Display name", text: $draftAccount.displayName)
                if hasAttemptedSave { FieldError(text: displayNameError) }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 2) {
                    Text("@")
                        .foregroundStyle(Palette.onSurfaceVariant)
                    TextField("username", text: $draftAccount.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                if hasAttemptedSave { FieldError(text: usernameError) }
            }

            if !draftAccount.isGuest {
                TextField("Email (optional)", text: $draftAccount.email)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }
        }
    }

    private var bioSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                TextField("A line about you", text: $draftAccount.bio, axis: .vertical)
                    .lineLimit(2 ... 4)
                if hasAttemptedSave { FieldError(text: bioError) }
            }
        } header: {
            Text("Bio")
        } footer: {
            Text("\(draftAccount.bio.count)/160")
                .foregroundStyle(draftAccount.bio.count > 160 ? Palette.pinkAccent : Palette.onSurfaceVariant)
        }
    }

    private var statusSection: some View {
        Section("Status bubble") {
            TextField("What are you doing?", text: $draftProfile.statusText, axis: .vertical)
                .lineLimit(2 ... 4)

            Stepper(value: $draftProfile.streak, in: 0 ... 999) {
                LabeledContent("Streak", value: "\(draftProfile.streak)")
            }
        }
    }

    private var nowPlayingSection: some View {
        Section("On the record") {
            TextField("Track", text: $draftProfile.nowPlaying.title)
            TextField("Artist", text: $draftProfile.nowPlaying.artist)
        }
    }

    private var hobbiesSection: some View {
        Section {
            ForEach(draftProfile.hobbies, id: \.self) { hobby in
                Text(hobby)
            }
            .onDelete { offsets in
                draftProfile.hobbies.remove(atOffsets: offsets)
            }

            HStack {
                TextField("Add a sticker", text: $hobbyDraft)
                    .onSubmit(addHobby)

                Button("Add", action: addHobby)
                    .disabled(hobbyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(Palette.accent)
            }
        } header: {
            Text("The locker door")
        } footer: {
            Text("Swipe a sticker to peel it off.")
        }
    }

    // MARK: Actions

    private func addHobby() {
        let trimmed = hobbyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !draftProfile.hobbies.contains(trimmed) else { return }
        draftProfile.hobbies.append(trimmed)
        hobbyDraft = ""
    }

    private func save() {
        hasAttemptedSave = true
        guard isValid else { return }

        var account = draftAccount
        account.username = AccountValidator.normalisedUsername(account.username)
        account.displayName = account.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        account.bio = account.bio.trimmingCharacters(in: .whitespacesAndNewlines)

        // Keep the Personality Board's own handle/name in step with identity, so
        // the two halves of the profile can never disagree on screen.
        var profile = draftProfile
        profile.handle = "@\(account.username)"
        profile.displayName = account.displayName
        profile.avatarSeed = account.avatarSeed
        profile.avatarImageName = account.avatarImageName

        onSave(account, profile)
        dismiss()
    }

    @MainActor
    private func importAvatar(_ pickerItem: PhotosPickerItem) async {
        defer { avatarPickerItem = nil }

        guard
            let data = try? await pickerItem.loadTransferable(type: Data.self),
            let name = ImageStore.save(data: data)
        else { return }

        draftAccount.avatarImageName = name
    }
}
