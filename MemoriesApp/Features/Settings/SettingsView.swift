import SwiftUI

/// Settings.
///
/// Organised by *what the setting is about* rather than by which subsystem
/// implements it, and every section is a self-contained block so adding a new
/// group later means adding one computed property. Anything that isn't wired to
/// real behaviour yet says so on the row, rather than presenting a switch that
/// silently does nothing.
struct SettingsView: View {

    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var account: AccountStore
    @EnvironmentObject private var store: AppStore

    @Environment(\.dismiss) private var dismiss

    @State private var confirmingSignOut = false
    @State private var confirmingReset = false
    @State private var toast: ToastMessage?

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                boardSection
                accountSection
                notificationsSection
                privacySection
                accessibilitySection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Palette.surface)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .toast($toast)
        .presentationBackground(Palette.surface)
        .confirmationDialog("Sign out?", isPresented: $confirmingSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                account.signOut()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your boards stay on this device.")
        }
        .confirmationDialog(
            "Reset all boards?",
            isPresented: $confirmingReset,
            titleVisibility: .visible
        ) {
            Button("Reset to sample boards", role: .destructive) {
                store.resetToSample()
                toast = ToastMessage(text: "Boards reset", tone: .warning)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every board and memory you've made, and restores the sample set. It cannot be undone.")
        }
    }

    // MARK: Sections

    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: $preferences.themeMode) {
                ForEach(ThemeMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Appearance")
        } footer: {
            Text("“System” follows your iPad's own light and dark setting.")
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        Section("Account") {
            if let user = account.account {
                HStack(spacing: 14) {
                    AvatarView(
                        name: user.displayName,
                        seed: user.avatarSeed,
                        size: 44,
                        ring: .neon,
                        imageName: user.avatarImageName
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .textStyle(TypeScale.bodyMD)
                            .fontWeight(.semibold)
                            .foregroundStyle(Palette.onSurface)

                        Text(user.handle)
                            .textStyle(TypeScale.labelCaps)
                            .foregroundStyle(Palette.onSurfaceVariant)
                    }

                    Spacer(minLength: 0)

                    if user.isGuest {
                        StickerBadge(text: "Guest", style: .paper, rotation: 0, shape: .pill)
                    }
                }
                .padding(.vertical, 4)

                Button("Edit profile") {
                    dismiss()
                    store.tab = .profile
                }
                .foregroundStyle(Palette.accent)

                Button("Sign out", role: .destructive) { confirmingSignOut = true }
            }
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Board invites", isOn: $preferences.notifyOnInvite)
            Toggle("Friend activity", isOn: $preferences.notifyOnActivity)
            Toggle("Reactions", isOn: $preferences.notifyOnReaction)
        } header: {
            Text("Notifications")
        } footer: {
            Text("Preferences are saved on this device. Nothing is delivered yet — the app has no push service.")
        }
    }

    private var privacySection: some View {
        Section {
            Picker("Who can see your profile", selection: $preferences.profileVisibility) {
                ForEach(ProfileVisibility.allCases) { option in
                    Text(option.title).tag(option)
                }
            }

            Toggle("Show when you're active", isOn: $preferences.showsActivityStatus)
            Toggle("Anyone can invite you", isOn: $preferences.allowsInvitesFromAnyone)
        } header: {
            Text("Privacy")
        } footer: {
            Text("These are stored locally and will be enforced by the server once one exists.")
        }
    }

    private var accessibilitySection: some View {
        Section {
            Toggle("Reduce motion", isOn: $preferences.reduceMotion)
        } header: {
            Text("Motion")
        } footer: {
            Text("Stops the record spinning and removes screen transitions. Your iPad's own Reduce Motion setting is honoured too — this only adds to it.")
        }
    }

    private var boardSection: some View {
        Section {
            Picker("Grid", selection: $preferences.canvasGrid) {
                ForEach(CanvasGridStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Snap to grid", isOn: $preferences.snapToGrid)
        } header: {
            Text("Board")
        } footer: {
            Text("The surface your memories sit on. Also switchable from a board's own menu. Snapping lines objects up on release and drops new ones straight — turn it off for a free-form, hand-placed board.")
        }
    }

    private var dataSection: some View {
        Section {
            Button("Replay the tutorial") {
                account.resetOnboarding()
                dismiss()
            }
            .foregroundStyle(Palette.accent)

            Button("Reset preferences") {
                preferences.resetToDefaults()
                toast = ToastMessage(text: "Preferences reset")
            }
            .foregroundStyle(Palette.accent)

            Button("Reset all boards", role: .destructive) { confirmingReset = true }
        } header: {
            Text("Data")
        } footer: {
            Text("Boards live in this app's own storage on your iPad. There is no cloud copy.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0")
            LabeledContent("Boards", value: "\(store.boards.count)")
            LabeledContent("Memories", value: "\(store.allMemories.count)")
        }
    }
}
