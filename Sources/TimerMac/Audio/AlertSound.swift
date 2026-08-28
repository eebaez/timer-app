import AppKit

/// The Blueprint §7/§13 alert sound: a nudge, never a requirement. If
/// the named sound isn't available, `NSSound(named:)` returns nil and
/// this silently does nothing — no error, no crash, matching "sound is
/// never the only carrier of the alert."
enum AlertSound {
    static func play() {
        NSSound(named: "Glass")?.play()
    }
}
