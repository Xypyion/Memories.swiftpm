import SwiftUI
import UIKit

/// Sensory feedback for direct-manipulation actions: grab, place, tie, cut,
/// delete, select.
///
/// `UIFeedbackGenerator` fires only on iPhone — on iPad it is a silent no-op,
/// there is no Taptic Engine. Ship it anyway: it's cheap, harmless, and pays
/// off on iPhone. The effort that matters for iPad judging is the visual
/// feedback the callers pair this with (see `Motion.pop`), not this file.
enum Haptics {

    /// Set from `preferences.reduceMotion` in `RootView`, so one switch silences
    /// both motion and haptics. `true` by default so feedback works before the
    /// first environment read.
    static var enabled = true

    static func grab() { impact(.soft) }
    static func place() { impact(.rigid) }
    static func cut() { impact(.rigid) }
    static func delete() { impact(.rigid) }
    static func select() { impact(.light) }

    static func tie() { notify(.success) }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

/// Shared spring constants, so grab/place/tie/cut feedback reads as one
/// consistent physical language instead of several one-off animations.
enum Motion {
    /// The "something popped" spring: a quick settle with a touch of overshoot.
    static let pop = Animation.spring(response: 0.3, dampingFraction: 0.6)
}
