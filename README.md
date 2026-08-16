# Memories — a tactile digital scrapbook for iPad

A SwiftUI app built to the "Living Canvas" handoff: boards are free-form
surfaces, not grids; objects are physical; navigation floats instead of docking.

Built as a **Swift Playgrounds App Package** (`.swiftpm`), which is the one
SwiftPM product type that produces a runnable iOS app. It opens in two places:

| Where | What you need | Result |
|---|---|---|
| **Swift Playgrounds on iPad** | iPadOS 17+, Swift Playgrounds 4.4+ | Builds and runs **on the iPad itself** — no Mac |
| **Xcode on macOS** | Xcode 15+ | Opens directly, runs in the iPad simulator or on device |

---

## Running it on iPad without a Mac

This is the intended path if you're on Windows.

1. Copy the whole `Memories.swiftpm` folder to iCloud Drive (or OneDrive /
   Dropbox / a USB-C drive — anything the iPad Files app can see). Keep it as a
   folder; don't zip the contents away from each other.
2. On the iPad, open **Files** and tap `Memories.swiftpm`. It hands off to Swift
   Playgrounds automatically.
3. Tap **▶︎ Run**.

If Swift Playgrounds isn't installed, get it free from the App Store.

Cloning works too, and produces a correctly named folder:

```bash
git clone https://github.com/Xypyion/Memories.swiftpm.git
```

## Running it on a Mac

```bash
open Memories.swiftpm
```

Xcode opens it as a project. Pick an iPad simulator and hit Run. To ship it,
set your team under Signing & Capabilities — no other configuration needed.

## Why not a plain `swift build`

`Package.swift` imports `AppleProductTypes` and declares `.iOSApplication`.
That module only exists inside Xcode's and Swift Playgrounds' SwiftPM, because
an installable `.app` needs signing and an `Info.plist` that command-line SwiftPM
does not produce. Running `swift build` on Windows or Linux will fail at the
`import AppleProductTypes` line — that's expected, not a bug.

It is authored on Windows, where no Swift toolchain that can parse SwiftUI
exists, so every build and every interaction here was verified by opening the
package in Swift Playgrounds on an iPad and running it.

---

## What's in it

Sign-in, then four tabs behind a floating Liquid Glass dock, with a floating top
bar carrying your identity and Settings.

**Board** — a gallery of boards in an irregular bento, then the canvas itself:

- Pan and pinch-zoom the viewport; drag any object at any time
- Select an object to pinch-scale and two-finger-rotate it
- Double-tap anything for its inspector — caption, paper colour, sticker vinyl,
  frame style, size, rotation, plus the topic and date it's filed under
- Add mounted prints, polaroids, sticky notes, stickers and hand-drawn marks
- Import real photos from the iPad photo library
- **Twine tool** — tap two memories to tie a braided rope between them; tap the
  same pair again to cut it
- Rename, share (collaborator list + invite link), delete

**Memories** — every photo across every board, flattened, with two ways to
organise it:

- **By day** — chronological, newest first, with Today/Yesterday headings
- **By topic** — grouped by category, catalogue order first, unfiled last

Search and the favourites/shared/polaroids filters sit *above* grouping, so they
survive a switch between views. Both schemes emit the same `[MemorySection]` and
share their entire presentation layer.

**Friends** — invites you can accept or decline, an active-now row, a searchable
friend list, an activity stream, and shared boards laid out as a pinned pile.
Every person is tappable and opens their profile: what you share, their recent
activity, add-them-to-a-board, remove friend.

**Profile** — your identity header (avatar, name, handle, bio, joined date),
tappable stats, then the Personality Board: status bubble, spinning record,
pinned artists, hobby stickers. Edit profile opens a real editor with draft
state, validation, Save and Cancel.

**Settings** — appearance (light/dark/system), account, notifications, privacy,
motion, data, about. Reachable from the top bar on every tab.

**Onboarding** — five steps, Next/Back/Skip/Finish, shown once. Replayable from
Settings.

## Architecture

```
MemoriesApp/
  MemoriesRootApp.swift        @main — injects the three stores
  DesignSystem/                palette, type scale, elevation, glass, components
    Components/                stickers, paper, avatars, rope, decorations,
                               OnlineStatus, Toast
  Models/                      domain types, AppStore, AccountStore, Preferences
  Navigation/                  root switch, floating dock, floating top bar
  Features/
    Auth/                      LoginView
    Onboarding/                OnboardingOverlay
    Gallery/                   board bento + covers
    BoardEditor/               canvas, items, CanvasLiveState, RopeLayer, dock,
                               inspector, share
    Memories/                  MemoriesView, grouping, toggle, tiles, masonry
    Friends/                   hub, FriendCard, FriendProfileView
    Profile/                   MyProfileView, ProfileHeader, PersonalityBoard,
                               ProfileEditor
    Settings/                  SettingsView
```

**Three stores, split by change rate.** `AppStore` holds boards and the social
graph, `AccountStore` holds session and first-run state, `Preferences` holds
settings. They are separate so that flipping a notification toggle does not
invalidate every view subscribed to board data.

**Persistence.** Boards are `Codable` and written to
`Application Support/Memories/state.json`, debounced 1s. Account and preferences
go to `UserDefaults`. Imported photos are downscaled to 1600px, written as JPEGs
under `Application Support/Memories/Images/`, and referenced by filename — never
inlined into the JSON.

**Forward-compatible decoding.** `CanvasItem` decodes every field with
`decodeIfPresent` and a fallback, declared in an extension so the memberwise
initialiser survives. Adding a property can never orphan somebody's boards.
This data is the user's memories and there is no server copy.

**No image assets ship with the app.** Every photo, avatar and cover on first
launch is drawn procedurally from a stable seed, so the app looks populated on
any device with a zero-byte asset catalogue.

## Performance notes

The Boards lag had one root cause and several contributors.

**Root cause.** `CanvasItemView` wrote `item.position` through the `AppStore`
binding on every drag frame — ~120 store mutations per second on a 120 Hz iPad,
each firing `objectWillChange` and invalidating *every subscribed view in the
app*. Now an in-flight gesture mutates local `@State` and commits once on
release. `CanvasLiveState` carries the live offset to `RopeLayer` alone — held
with `@State`, not `@StateObject`, so the editor keeps the reference without
subscribing to it. Twine still tracks a drag in real time; nothing else redraws.

**Contributors fixed:**

- `MemoryTexture` drew three `.blur()`-ed ellipses through `.blendMode(.screen)`
  inside a `.compositingGroup()`, plus a 220-op grain `Canvas` — per texture, and
  board covers show five. Blur and blend each force an offscreen pass; gradients
  do not. Now radial gradients, with grain opt-in via `detail`.
- Board covers rasterise once via `.drawingGroup()` instead of re-compositing
  five rotated, shadowed, layered stacks per frame.
- Gallery columns, memory masonry, friend lists and board strips are `LazyVStack`
  / `LazyHStack`, so off-screen covers are never built.
- The presence indicator no longer runs a scale-and-fade loop on every avatar
  simultaneously; the demo cursor's timer stops when the demo is off or motion is
  reduced.

**Extensibility.** Adding widget types to a board stays cheap: items are value
types in one array, the canvas renders them through a single `ForEach`, and the
gesture layer is generic over item kind. A new kind means a new
`CanvasItemKind` case and a branch in `CanvasItemView.content`.

## Accessibility

Controls carry labels, hints and traits, and every control offers at least a
44pt target — including the ones drawn smaller than that, which grow their
reachable area without growing the artwork (`minimumHitArea`).

**Dynamic Type.** Type is authored at fixed sizes and run through
`@ScaledMetric`, so each token grows on the curve Apple defines for its text
style rather than by a flat multiplier. Two surfaces are deliberately capped at
`xxLarge`: the tab bar, and objects on the canvas — a board is composed by hand
at a size the user chose, and reflowing it at accessibility sizes would rearrange
their artwork. Every other surface scales the whole way up.

**Reduce Motion.** `MotionPolicy` combines the system setting with the app's own
override, and it is the *only* route to an animation in this codebase: all 59
animation sites resolve through `motion.animation(_:)`, so one switch genuinely
governs the record spin, the presence halo, the demo cursor, toasts, press
feedback, and every view transition.

## What is simulated, and says so

- **The collaborator cursor** on the canvas is a local animation. There is no
  networking. The menu item that controls it reads "Show live presence (demo)".
- **The invite link** in the share sheet is a generated `memories://` string that
  copies to the clipboard and resolves to nothing.
- **Login verifies nothing.** It asks for a username, not a password, precisely
  so it doesn't teach you that credentials mean something here. `AccountStore`
  models the real shape — a session that can be absent, created, validated,
  restored and cleared — so a backend swaps in behind `signIn`/`restore` without
  touching any view.
- **Notification and privacy preferences** persist but are not enforced; there is
  no push service and no server. The Settings footers say so on screen.

## Known gaps

- No audio. The record widget displays the track you set and deliberately has no
  transport controls it could not honour.
- No undo stack. `Board` is a value type, so this is a small addition — but a
  direct-manipulation canvas wants it before launch.
- The free-form canvas has no VoiceOver rotor or keyboard-driven placement.
  Chrome around it is labelled; the canvas itself is not navigable without
  touch. That is real scoped work, not a polish pass.
- Boards delete from inside the editor only, not from the gallery.
- Friends are seeded sample data; there is no way to add a new person, because
  there is no directory to add them from.
