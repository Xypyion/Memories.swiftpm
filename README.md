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

Zipping the folder for transfer is fine — unzip on the iPad first, then tap the
`.swiftpm` folder.

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
`import AppleProductTypes` line — that's expected, not a bug. Nothing in this
package can be compiled on Windows, since SwiftUI and the iOS SDK are
Apple-platform only.

**This code has not been compiled.** It was written on Windows, where no Swift
toolchain that can parse SwiftUI exists. Treat the first build on a Mac or iPad
as the real verification step.

---

## What's in it

Four screens behind a floating Liquid Glass dock.

**Board** — a gallery of boards in an irregular bento, then the canvas itself.
The canvas is the substance of the app:

- Pan and pinch-zoom the viewport; drag any object at any time
- Select an object to pinch-scale and two-finger-rotate it
- Double-tap anything to open its inspector (caption, paper colour, sticker
  vinyl, frame style, size, rotation)
- Add mounted prints, polaroids, sticky notes, stickers and hand-drawn marks
- Import real photos from the iPad photo library
- **Twine tool** — tap two memories to tie a braided rope between them; tap the
  same pair again to cut it
- Rename, share (collaborator list + invite link), delete

**Memories** — every photo across every board, flattened, searchable, filterable
by favourites / shared / polaroids. Still mounted on paper, still crooked.

**Friends** — invites you can accept or decline, an active-now row with live
presence rings, an activity stream, and shared boards laid out as a pinned pile.

**Profile** — the Personality Board. Avatar, speech-bubble status, streak badge,
a spinning record for the current track, pinned artists, and hobby stickers.
All editable through *customize profile*.

## Architecture

```
MemoriesApp/
  MemoriesRootApp.swift        @main
  DesignSystem/                palette, type scale, elevation, glass, components
    Components/                stickers, paper frames, avatars, rope, decorations
  Models/                      domain types, persistence, seeded sample data
  Navigation/                  root switch + the floating dock
  Features/
    Gallery/                   board bento + board covers
    BoardEditor/               the canvas, items, dock, inspector, share
    Memories/                  flattened photo grid
    Friends/                   the hub
    Profile/                   the personality board
```

- **State**: one `AppStore` (`ObservableObject`) injected as an environment
  object. Chosen over `@Observable` deliberately — the macro adds a toolchain
  dependency that buys nothing at this scale, and this has to build first time on
  a machine I can't test on.
- **Persistence**: the whole graph is `Codable` and written to
  `Application Support/Memories/state.json`, debounced 1s so dragging a photo
  doesn't re-encode the document 120 times a second.
- **Images**: imported photos are downscaled to 1600px, written as JPEGs to
  `Application Support/Memories/Images/`, and referenced by filename — never
  inlined into the JSON.
- **No image assets ship with the app.** Every photo, avatar and album cover you
  see on first launch is drawn procedurally from a stable seed
  (`MemoryTexture`, `SeededGenerator`). The app looks populated on any device
  with a zero-byte asset catalogue, and the same seed always yields the same
  picture, so objects don't reshuffle between renders.

## Two things that are simulated, and say so

- **The collaborator cursor** on the canvas is a local animation. There is no
  networking in this app. The board menu item that controls it is labelled
  "Show live presence (demo)" and it can be switched off.
- **The invite link** in the share sheet is a generated `memories://` string. It
  copies to the clipboard; nothing resolves it.

Everything else — placement, rotation, twine, photo import, favourites, search,
profile edits — is real and persists across launches.

## Known gaps

- No audio. The record widget displays the track the user set; it deliberately
  has no transport controls, because it could not honour them.
- No undo stack. `Board` is a value type, so an undo manager is a small addition
  but not one I've made.
- Accessibility: labels and traits are set on controls, but the free-form canvas
  has no VoiceOver rotor or keyboard-driven placement. That is real work, not a
  polish pass, and it should be scoped before launch.
- Boards can be deleted from inside the editor only, not from the gallery.
