import Foundation

/// Deterministic PRNG so that every generated texture, avatar and scatter is
/// stable across launches. Without this, the board would reshuffle itself every
/// time the view redrew — which would destroy the illusion that these are
/// physical objects the user placed.
struct SeededGenerator: RandomNumberGenerator {

    private var state: UInt64

    init(seed: Int) {
        // Mix and force odd so the xorshift never degenerates to zero.
        state = (UInt64(bitPattern: Int64(seed)) &* 0x9E37_79B9_7F4A_7C15) | 1
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

extension Int {
    /// A stable pseudo-random seed derived from any string (a name, a handle).
    static func seed(from string: String) -> Int {
        var hash = 5381
        for byte in string.utf8 {
            hash = (hash &* 33) &+ Int(byte)
        }
        return abs(hash)
    }
}
