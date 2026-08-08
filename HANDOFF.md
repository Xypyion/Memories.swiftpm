# Memories — Executive Handoff

*What the application is, and how each design principle is discharged in code.*

---

## 1. What this is

**Memories is a collaborative studio, not a gallery.**

A conventional photo app answers *"where is my picture?"* and organises around
that question: grids, dates, albums, uniform cells. Memories answers a different
question — *"what did this feel like?"* — and organises around **Boards**:
free-form canvases where photos, notes, stickers and hand-drawn marks are placed
by hand, overlap, rotate, and get physically tied together with twine.

The strategic bet is that the *arrangement* carries meaning that the *contents*
alone do not. Two photos side by side on a grid are two photos. Two photos
overlapping, one taped over the corner of the other, with a rope between them
and a note that says "don't forget the disposable camera", is a memory.

Everything downstream in this document follows from that one commitment.

**Target:** iPad, portrait and landscape. iPadOS 17+.
**Surface:** four screens — Board (gallery → canvas), Memories, Friends, Profile.

---

## 2. Core design principles → implementation

### 2.1 Tactile High-Contrast

> A `#000000` foundation and a high-energy `#C8FF2E` neon green, so UI controls
> stay distinct from colourful, multi-textured photographic content.

Implemented in `DesignSystem/Palette.swift` as a full elevation ladder, not two
colours:

| Level | Token | Value | What lives here |
|---|---|---|---|
| 0 | `void` | `#000000` | The board. Absolute black. |
| 0.5 | `board` | `#050505` | Canvas field, so item shadows read |
| 1 | `charcoal` | `#101010` | Cards resting on the board |
| 2 | `paper` | `#FAFAFA` | Photo mounts, polaroids, notes |
| 3 | `neon` | `#C8FF2E` | Active state, primary action, brand |
| 3 | `pink` | `#FF2E7E` | Collaboration, reactions, urgency |

**Two rules are enforced throughout, and they are the whole discipline:**

1. **Neon is a verb, not a surface.** It marks the selected tab, the primary
   button, the live-presence ring, the armed tool. It is never a background for
   passive content. This is why it survives against photos: the eye learns that
   green means *actionable*, so it never competes with a saturated photograph —
   it categorises against it.
2. **Paper is a break, not a theme.** `#FAFAFA` appears only on objects that are
   physically *on* the board. Structural UI never uses it. The white/black
   collision is the strongest tactile signal in the system and it is spent only
   where it pays.

Pink is deliberately scoped narrower than green: it means *another person*. That
gives collaboration its own channel that never has to compete with actionability.

### 2.2 Physicality & Depth

> Elements use subtle shadows and overlapping layers to feel like physical
> objects resting on a surface.

Depth is carried by **four distinct shadow signatures**, not one blur value
(`DesignSystem/Elevation.swift`). A viewer can identify an object's level
without reading its content:

- `tactileShadow()` — wide soft shadow **plus** a tight 1pt contact shadow, so a
  card's edge sits on the board instead of hovering above it
- `paperShadow()` — a single lifted shadow for prints and notes
- `stickerShadow()` — **zero blur, 2pt hard offset.** This is what makes a
  sticker read as thick vinyl stuck on rather than ink printed in
- `neonGlow()` / `pinkGlow()` — emissive halo, used only for "this is on"

The physical vocabulary is a real component set, not decoration:

- `TapeStrip` — translucent, rotated, soft-edged, sitting over a print's top edge
- `PushPin` — radial-gradient head with a dark centre and a cast shadow
- `MountedPhoto` — 12pt white border, near-square corners like an actual print
- `PolaroidPhoto` — square image, deep bottom margin, italic caption at −1°
- `PaperNote` — coloured stock, single pin dot, no chrome
- `RopeStrand` — the signature object, described below

**Visual collision is a brand identifier, so it is engineered rather than
tolerated.** Board covers (`BoardCollage`) deliberately never resolve into a
clean grid: five tiles at fixed scales, fixed rotations and fixed offsets,
computed by pure arithmetic so they are stable across renders.

**The twine deserves its own note**, because it is the product's signature and
faking it would be visible. `RopeShape.swift` draws it properly:

- The rope **sags under its own weight** — a quadratic curve whose control point
  is pulled straight down, proportional to span
- **Two strands are drawn 180° out of phase** along the curve's normal, which is
  what produces an actual braid rather than a stripe
- A dark core underneath makes the strands appear to wrap *around* something
- The braid **tapers to nothing at both ends**, so it looks tied off
- Knots cap each end

### 2.3 Immersive "Liquid" Navigation

> A floating, highly translucent container with deep background blur, so
> memories bleed to the edges of the iPad screen.

`LiquidGlassTabBar` + the `liquidGlass()` modifier
(`DesignSystem/LiquidGlass.swift`). The glass is `.ultraThinMaterial` under a
5% white tint, with a **gradient border — bright at the top, dim at the
bottom** — so it reads as a curved pane catching light rather than a flat
translucent rectangle.

**Why the sidebar was removed, stated as a trade:** a sidebar permanently claims
roughly 320pt of *layout*. The floating capsule costs roughly 90pt of *overlay*.
Content scrolls behind it and runs to the display edges. On a canvas product
where the workspace is the point, that is not a stylistic preference — it is
several hundred points of creative surface per screen.

The cost is that ~90pt at the bottom of every scroll view is obscured, so
`Space.dockClearance` is applied as bottom padding on every scrolling surface.

**The Board tab is two states, not two screens.** Gallery and canvas live in one
tab, so the dock never disappears and the user never loses their place.

### 2.4 Expressive Personality

> The Profile is the user's ultimate board — interactive widgets, not static
> lists.

`ProfileBoardView` is built from the same objects as any other board:

- **Avatar** at 180pt, ringed in neon, rotated 2° — hand-placed, not centred and
  squared
- **Status bubble** — a paper speech bubble with a real comic tail (three
  shrinking circles), at −6°
- **Streak badge** — a pink vinyl sticker with the hard offset shadow,
  deliberately overlapping the avatar's lower edge
- **The record** — a spinning vinyl over a radial-gradient disc with etched
  grooves and a centre spindle, on a pink widget
- **The locker door** — hobby stickers in a custom `FlowRow` layout, each at a
  small deterministic rotation, in mixed vinyl styles

**One honesty constraint shaped this screen:** the record widget carries *no
transport controls*. The app has no audio engine, and a play button that does
nothing would be a lie told in the most prominent widget on the user's profile.
It displays what the user set and spins as an ambient signal. Everything on this
board is something the user chose to put down — which is also why there are no
read-only statistics rows.

### 2.5 Seamless Connectivity

> Real-time presence in the header; the Friends Hub centralises activity and
> common memories.

- **Presence ring is load-bearing.** Neon = on the board now, pink = recently
  active, none = offline. Because presence is carried by the ring alone, the
  same `AvatarView` works at 26pt in a face-pile and at 180pt on the profile.
- `PresenceDot` pulses — the one genuinely-changing thing on screen earns the
  one continuous animation.
- The board header shows a `FacePile` plus an "ON THE BOARD" capsule.
- The Friends Hub leads with **invites and who is here**, not a friend list. A
  list is a directory, and directories are things you visit on purpose; the goal
  is ambient social signal.
- Activity cards **show the photos**, because "Leo added 3 photos" is not news —
  the photos are.
- "Common memories" renders shared boards as a **pinned pile**, reusing the
  canvas language to say *these are collective objects, not records*.

**Two things are simulated and labelled as such in the product**, because
shipping a convincing fake of a network feature is worse than shipping neither:
the drifting collaborator cursor is a local animation behind a menu item that
reads *"Show live presence (demo)"*, and the invite link is a generated string
that copies to the clipboard and resolves to nothing.

---

## 3. Design system baseline

**Typography — SF Pro throughout** (`DesignSystem/Typography.swift`). No bundled
font files, no licence surface, and Dynamic Type and optical sizing come free.

Tracking is stored *with* the font in a `TextStyle` token rather than applied at
call sites — the display sizes only read correctly with negative tracking and the
metadata labels only read correctly with positive tracking, and splitting them
apart is exactly how a type system drifts.

| Token | Size / leading | Tracking | Use |
|---|---|---|---|
| `displayLG` | 56 / 64 | −0.02em | Page titles, regular width |
| `displayMD` | 32 / 40 | −0.02em | Page titles compact; board titles |
| `headline` | 24 / 32 | −0.01em | Section headings |
| `bodyLG` | 18 / 28 | — | Lead paragraphs, note bodies |
| `bodyMD` | 16 / 24 | — | Default body |
| `labelCaps` | 12 / 16 | +0.1em | Timestamps, presence, metadata |
| `labelTiny` | 10 / 14 | +0.1em | Dock labels |
| `sticker` | 14 / 18 | +0.05em | Sticker faces |

**Corner radius — Round Eight as the professional baseline**, with a deliberate
spread either side:

| Token | Value | Use |
|---|---|---|
| `print` | 4 | Photo prints — near-square, like a real print |
| `eight` | **8** | The baseline |
| `card` | 16 | Buttons, input fields — iPadOS-native feel |
| `panel` | 24 | Cards and panels |
| `widget` | 32 | Personality Board widgets |

**Spacing** — 8pt unit; 16pt object gap; 32pt canvas margin; 12pt sticker
padding. `Space.dockClearance` (132pt) is the clearance every scroll view owes
the floating dock.

**Navigation** — floating bottom bar, Liquid Glass, four destinations.

---

## 4. The canvas model

The one piece of architecture worth knowing.

- A board is a fixed **2200 × 1500 logical coordinate space**. Items store an
  absolute centre point, a rotation in degrees, and a scale. **Nothing snaps to
  a grid** — that is the product.
- The viewport pans and pinch-zooms over that space the way a hand moves over a
  table.
- Item drags read their translation in a **named canvas coordinate space**, so a
  drag lands under the finger at any zoom level without callers dividing by the
  scale factor.
- **Gesture arbitration is a deliberate asymmetry:** drag is always live —
  you should never have to select something before you can move it — but pinch
  and rotate require selection first. Without that rule, the user could never
  zoom the canvas whenever their fingers happened to land on a photo. Selection
  is the disambiguator.
- `zIndex` is per-item and explicit; new objects land on top.

---

## 5. Light mode

Added after the original handoff. The principle that made it cheap:

> **Objects don't change colour when you turn the lights on.**

Light mode changes the *board* — the desk the memories are lying on — not the
memories. The surface ladder, body text and hairlines adapt; paper, vinyl,
photographs and sticker keylines do not. That is why the tactile language
survives the theme switch intact instead of becoming a washed-out inversion of
itself, and it is also why a photo mount reads as an object in both themes: it is
the same white it always was, sitting on a different desk.

Mechanically, `Palette` tokens are `UIColor` dynamic providers rather than a
`@Published` theme object. Every existing call site — `Palette.charcoal`,
`Palette.onSurface` — adapts with no change, and reading a colour never triggers
a re-render.

Two tokens exist purely to keep contrast honest:

- `Palette.accent` — the neon **as a foreground**. `#C8FF2E` is unreadable as
  text on a light surface, so this darkens to the palette's own deep green
  (`#4E6700`) there. `Palette.neon` remains the fill, and always carries
  near-black `onNeon` text, so it is legible on either theme.
- `Palette.onScrim` — text on the dark gradient painted over a cover photo. Fixed
  light, because that gradient does not change with the theme.

Shadow colours adapt too: a 70 %-black shadow reads as depth on a black board and
as grime on a white one.

## 6. Identity vs. expression

The Profile tab now carries two distinct things, and keeping them apart is
deliberate.

`UserAccount` is **identity** — who you are, what you're called, what the app
should call you. `UserProfile` is **expression** — the status bubble, the record,
the locker door. They persist separately because they answer to different owners:
identity would come from an auth backend, the Personality Board never would. A
profile leads with identity and then hands the rest of the page to expression.

`AccountStore` models the full session shape — absent, created, validated,
restored, cleared, and guest-promoted-to-named — against local storage. A real
identity provider swaps in behind `signIn`/`restore` without touching a single
view.

## 7. What is deliberately not built

Stated so it is a decision on the record rather than a discovery in QA.

- **No networking.** Presence and invites are simulated, and labelled as demos in
  the UI itself.
- **Login verifies nothing**, and asks for no password on purpose. Prompting for
  a credential we do not check would teach the user their credentials mean
  something here, which is the beginning of a real security problem.
- **Notification and privacy preferences persist but are not enforced.** There is
  no push service and no server; the Settings footers say so on screen.
- **No audio.** See §2.4.
- **No undo stack.** `Board` is a value type so this is a small addition, but it
  is not done, and a direct-manipulation canvas will want it before launch.
- **Canvas accessibility is incomplete.** Controls carry labels, hints and traits,
  and `MotionPolicy` governs every animation from one switch — but the free-form
  canvas has no VoiceOver rotor and no keyboard-driven placement. That is real
  scoped work, not a polish pass.
- **Boards delete from inside the editor only**, not from the gallery.
- **Friends cannot be added**, only removed — there is no directory to add them
  from without a backend.

---

## 8. Verification status

The package has **not been compiled**. It was authored on Windows, where no
Swift toolchain capable of parsing SwiftUI exists. The first build on a Mac or
on an iPad running Swift Playgrounds is the real verification step. Build
instructions are in `README.md`.
