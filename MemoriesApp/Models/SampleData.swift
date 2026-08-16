import SwiftUI

/// The first-run board set.
///
/// This is not filler. An empty scrapbook teaches nothing, so the seeded state
/// demonstrates every object type, a rope connection, overlapping layers and a
/// populated social graph — the user's first action is *editing* something that
/// already looks right, not staring at a blank canvas.
enum SampleData {

    struct Seeded {
        var boards: [Board]
        var friends: [Friend]
        var invites: [Invite]
        var activity: [ActivityEvent]
        var profile: UserProfile
    }

    static func make() -> Seeded {

        let sarah = Friend(
            name: "Sarah Kim", handle: "@sarahk",
            seed: .seed(from: "Sarah Kim"), isActive: true, ringStyle: .neon
        )
        let leo = Friend(
            name: "Leo Marsh", handle: "@leom",
            seed: .seed(from: "Leo Marsh"), isActive: true, ringStyle: .pink
        )
        let maya = Friend(
            name: "Maya Ortiz", handle: "@mayao",
            seed: .seed(from: "Maya Ortiz"), isActive: false, ringStyle: .offline
        )
        let marcus = Friend(
            name: "Marcus Chen", handle: "@marcusc",
            seed: .seed(from: "Marcus Chen"), isActive: false, ringStyle: .offline
        )
        let mia = Friend(
            name: "Mia Delacroix", handle: "@miad",
            seed: .seed(from: "Mia Delacroix"), isActive: true, ringStyle: .pink
        )
        let jonas = Friend(
            name: "Jonas Ek", handle: "@jonasek",
            seed: .seed(from: "Jonas Ek"), isActive: false, ringStyle: .offline
        )

        let friends = [sarah, leo, maya, marcus, mia, jonas]

        // MARK: Roadtrip Chaos — the demonstration board

        var roadtrip = Board(
            title: "Roadtrip Chaos",
            caption: "Six days, one bad map, zero regrets.",
            badge: "Summer '24",
            badgeStyle: .neon,
            seed: 1042,
            updatedAt: Date(),
            collaborators: [sarah.id, leo.id, mia.id, maya.id, marcus.id],
            tileWeight: .hero
        )

        let hero = CanvasItem(
            kind: .photo(PhotoPayload(caption: "Desert exit", aspect: 0.8)),
            position: CGPoint(x: 620, y: 430),
            rotation: -3,
            zIndex: 4,
            seed: 7311,
            width: 300
        )
        let polaroid = CanvasItem(
            kind: .polaroid(PhotoPayload(caption: "Late nights", aspect: 1)),
            position: CGPoint(x: 1120, y: 620),
            rotation: 4,
            zIndex: 3,
            seed: 2288,
            width: 260
        )
        let note = CanvasItem(
            kind: .note(NotePayload(text: "Don't forget to pack the disposable camera!", color: .blush)),
            position: CGPoint(x: 560, y: 1010),
            rotation: 2,
            zIndex: 6,
            seed: 4,
            width: 240
        )
        let vibes = CanvasItem(
            kind: .sticker(StickerPayload(text: "Vibes only", style: .neon)),
            position: CGPoint(x: 1250, y: 810),
            rotation: -12,
            zIndex: 8,
            seed: 5
        )
        let diner = CanvasItem(
            kind: .photo(PhotoPayload(caption: "Diner, 2am", isFavorite: true, aspect: 1.35)),
            position: CGPoint(x: 1620, y: 380),
            rotation: 5,
            zIndex: 2,
            seed: 9012,
            width: 320
        )
        let star = CanvasItem(
            kind: .decoration(.star),
            position: CGPoint(x: 1680, y: 950),
            rotation: 12,
            zIndex: 1,
            seed: 6,
            width: 96
        )
        let ring = CanvasItem(
            kind: .decoration(.ring),
            position: CGPoint(x: 300, y: 700),
            rotation: -20,
            zIndex: 0,
            seed: 7,
            width: 140
        )

        // MARK: The two the coach is talking about
        //
        // The board is deliberately *almost* finished. Everything above is
        // placed, angled and already roped into a chain — it reads as someone
        // else's completed page, which is what makes it worth finishing rather
        // than worth clearing.
        //
        // These last two are the hole in it. They sit together in the emptiest
        // corner, they are the only photographs on the board with no rope
        // attached, and `strayPolaroid` is knocked further off-angle than
        // anything else here. That is the entire tutorial, stated in placement
        // instead of prose: one thing obviously needs moving, two things
        // obviously belong together, and the finished chain above shows what
        // "belongs together" is supposed to look like when you're done.
        let strayPolaroid = CanvasItem(
            kind: .polaroid(PhotoPayload(caption: "Last stop", aspect: 1)),
            position: CGPoint(x: 980, y: 1180),
            rotation: -17,
            zIndex: 7,
            seed: 5514,
            width: 250
        )
        let sunset = CanvasItem(
            kind: .photo(PhotoPayload(caption: "Golden hour", aspect: 1.2)),
            position: CGPoint(x: 1370, y: 1130),
            rotation: 6,
            zIndex: 5,
            seed: 8823,
            width: 290
        )

        roadtrip.items = [hero, polaroid, note, vibes, diner, star, ring, strayPolaroid, sunset]

        // Stamped after assembly rather than inline, so the item declarations
        // above stay readable as *placement* — which is what they're really
        // demonstrating.
        for index in roadtrip.items.indices {
            roadtrip.items[index].topic = "Travel"
            roadtrip.items[index].createdAt = daysAgo(index / 3, plusHours: Double(index % 3) * 3.5)
        }

        roadtrip.ropes = [
            RopeConnection(a: hero.id, b: polaroid.id, sag: 0.20),
            RopeConnection(a: polaroid.id, b: diner.id, sag: 0.16)
        ]

        // MARK: Studio Sessions

        var studio = Board(
            title: "Studio Sessions",
            caption: "Everything we made at 3am.",
            badge: "Shared",
            badgeStyle: .pink,
            seed: 5570,
            updatedAt: Date().addingTimeInterval(-86_400 * 2),
            collaborators: [leo.id, jonas.id],
            tileWeight: .standard
        )
        studio.items = scatter(
            seeds: [3301, 3302, 3303, 3304, 3305],
            captions: ["Take 4", "Monitors", "Cable spaghetti", "Board", "Mix down"],
            topic: "Music",
            startingDaysAgo: 2
        )

        // MARK: Daily Dumps

        var dumps = Board(
            title: "Daily Dumps",
            caption: "The unedited feed.",
            badge: "Personal",
            badgeStyle: .paper,
            seed: 8890,
            updatedAt: Date().addingTimeInterval(-86_400 * 5),
            collaborators: [],
            tileWeight: .tall
        )
        dumps.items = scatter(
            seeds: [4401, 4402, 4403, 4404, 4405, 4406, 4407],
            captions: ["Tuesday", "Coffee", "The cat again", "Rain", "Nothing", "Window", "Late"],
            topic: "Everyday",
            startingDaysAgo: 0
        )

        // MARK: Graduation '23

        var graduation = Board(
            title: "Graduation '23",
            caption: "We actually finished.",
            badge: "Archive",
            badgeStyle: .ink,
            seed: 6120,
            updatedAt: Date().addingTimeInterval(-86_400 * 40),
            collaborators: [sarah.id, maya.id, marcus.id],
            tileWeight: .standard
        )
        graduation.items = scatter(
            seeds: [5501, 5502, 5503, 5504],
            captions: ["Caps up", "The walk", "Mum crying", "After party"],
            topic: "School",
            startingDaysAgo: 40
        )

        // MARK: Trip to the Alps

        var alps = Board(
            title: "Trip to the Alps",
            caption: "Cold, expensive, worth it.",
            badge: "Shared",
            badgeStyle: .neon,
            seed: 7340,
            updatedAt: Date().addingTimeInterval(-86_400 * 12),
            collaborators: [mia.id, jonas.id, leo.id],
            tileWeight: .standard
        )
        alps.items = scatter(
            seeds: [6601, 6602, 6603, 6604, 6605],
            captions: ["Golden hour", "Lift 4", "Frozen", "The hut", "Descent"],
            topic: "Travel",
            startingDaysAgo: 12
        )

        // MARK: Social

        let invites = [
            Invite(friendID: marcus.id, boardName: "Roadtrip 24"),
            Invite(friendID: jonas.id, boardName: "Studio Sessions")
        ]

        let activity = [
            ActivityEvent(
                friendID: leo.id, kind: .added, detail: "3 photos",
                boardName: "Summer Squad", date: Date().addingTimeInterval(-1_800),
                photoSeeds: [8801, 8802, 8803]
            ),
            ActivityEvent(
                friendID: sarah.id, kind: .reacted, detail: "a memory",
                boardName: "Graduation '23", date: Date().addingTimeInterval(-7_200)
            ),
            ActivityEvent(
                friendID: mia.id, kind: .commented, detail: "the polaroid",
                boardName: "Roadtrip Chaos", date: Date().addingTimeInterval(-19_000),
                photoSeeds: [8804]
            ),
            ActivityEvent(
                friendID: maya.id, kind: .joined, detail: "",
                boardName: "Trip to the Alps", date: Date().addingTimeInterval(-90_000)
            )
        ]

        let profile = UserProfile(
            handle: "@xinling01",
            displayName: "Ren",
            avatarSeed: .seed(from: "Ren Xinling"),
            avatarImageName: nil,
            statusText: "listening to leto while overthinking life",
            streak: 17,
            nowPlaying: NowPlaying(
                title: "若是月亮还没来",
                artist: "王宇宙Leto",
                artSeed: 3141
            ),
            pinnedArtists: [
                PinnedThing(name: "Twice", seed: .seed(from: "Twice")),
                PinnedThing(name: "NewJeans", seed: .seed(from: "NewJeans"))
            ],
            hobbies: ["film photography", "bouldering", "instant ramen", "vinyl"]
        )

        return Seeded(
            boards: [roadtrip, studio, dumps, graduation, alps],
            friends: friends,
            invites: invites,
            activity: activity,
            profile: profile
        )
    }

    /// Lays out photographic items in a loose, rotated scatter — never a grid,
    /// per the free-form canvas principle.
    ///
    /// Dates are spread backwards a day or two at a time from `startingDaysAgo`,
    /// so the day view has genuine multi-day structure to show on first launch
    /// rather than dumping everything under "Today".
    private static func scatter(
        seeds: [Int],
        captions: [String],
        topic: String,
        startingDaysAgo: Int
    ) -> [CanvasItem] {
        var rng = SeededGenerator(seed: seeds.first ?? 1)

        return seeds.enumerated().map { index, seed in
            let column = index % 3
            let row = index / 3

            let x = 480 + CGFloat(column) * 520 + CGFloat.random(in: -60 ... 60, using: &rng)
            let y = 420 + CGFloat(row) * 480 + CGFloat.random(in: -50 ... 50, using: &rng)

            let payload = PhotoPayload(
                caption: index < captions.count ? captions[index] : "",
                isFavorite: index == 1,
                aspect: index.isMultiple(of: 3) ? 1.0 : 0.8
            )

            let dayOffset = startingDaysAgo + (index / 2)
            let hourOffset = Double(index % 2) * 5.5

            var item = CanvasItem(
                kind: index.isMultiple(of: 2) ? .photo(payload) : .polaroid(payload),
                position: CGPoint(x: x, y: y),
                rotation: Double.random(in: -6 ... 6, using: &rng),
                zIndex: Double(index),
                seed: seed,
                width: CGFloat.random(in: 230 ... 300, using: &rng)
            )
            item.createdAt = daysAgo(dayOffset, plusHours: hourOffset)
            item.topic = topic
            return item
        }
    }

    private static func daysAgo(_ days: Int, plusHours hours: Double = 0) -> Date {
        Date().addingTimeInterval(-Double(days) * 86_400 + hours * 3_600)
    }
}
