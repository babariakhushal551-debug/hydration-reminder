import Foundation
import AVFoundation
import AudioToolbox
import UserNotifications

/// One selectable notification sound.
struct SoundOption: Identifiable, Equatable {
    enum Source: Equatable {
        case systemDefault          // UNNotificationSound.default
        case bundled                // shipped inside the app bundle
        case systemLibrary          // found in /System/Library/Audio/UISounds
    }

    let id: String                  // stable identifier persisted in settings
    let displayName: String
    let fileName: String?           // file name (with extension) to play/install
    let source: Source

    static func == (lhs: SoundOption, rhs: SoundOption) -> Bool { lhs.id == rhs.id }
}

/// Discovers, previews, and activates notification sounds.
///
/// - Enumerates the device's own sound library at
///   `/System/Library/Audio/UISounds` so the catalog mirrors what the iPhone
///   already ships with ("sync the iPhone sounds into the app").
/// - Previews via AudioServices (system files) or AVAudioPlayer (with the
///   user's chosen preview volume for bundled sounds).
/// - Installs the selected system sound into `Library/Sounds` so
///   `UNNotificationSound(named:)` can use it for real alerts.
@MainActor
final class SoundManager: ObservableObject {

    static let shared = SoundManager()

    static let systemLibraryPath = "/System/Library/Audio/UISounds"
    private static let librarySoundsDir: URL = {
        let base = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Sounds", isDirectory: true)
    }()

    /// All selectable sounds (System Default first, then ours, then device library).
    @Published private(set) var options: [SoundOption] = []

    /// Currently installed-to-Library/Sounds file names (installed system sounds).
    @Published private(set) var installedSystemSounds: Set<String> = []

    private var audioPlayer: AVAudioPlayer?
    private var systemSoundID: SystemSoundID = 0

    private init() {
        rebuildCatalog()
        refreshInstalledSounds()
    }

    // MARK: - Catalog

    /// Friendly names for the classic iOS alert files.
    private static let friendlyNames: [String: String] = [
        "sms-received1": "Tri-tone",
        "sms-received2": "Chord",
        "sms-received3": "Note",
        "sms-received4": "Glass",
        "sms-received5": "Bell",
        "sms-received6": "Electronic",
        "sms-received9": "Ripple",
        "new-mail": "New Mail",
        "mail-sent": "Mail Sent",
        "tink": "Tink",
        "tock": "Tock",
        "fanfare": "Fanfare",
        "photoShutter": "Camera Click",
        "key_press_click": "Keypad",
        "campanella": "Campanella",
        "complete": "Complete",
        "expectation": "Expectation",
        "anticipate": "Anticipate",
        "prompt": "Prompt",
        "pause": "Pause",
        "slow_rise": "Slow Rise",
        "sunglow": "Sunglow",
        "waterdrip": "Water Drip"
    ]

    private func rebuildCatalog() {
        var list: [SoundOption] = [
            SoundOption(id: "default", displayName: "System Default", fileName: nil, source: .systemDefault)
        ]

        // HydroFlow's own water-themed tones (bundled via Resources/Sounds).
        let bundled: [(String, String)] = [
            ("water_drop.wav", "Water Drop"),
            ("gentle_ripple.wav", "Gentle Ripple"),
            ("glass_chime.wav", "Glass Chime")
        ]
        for (file, name) in bundled where Bundle.main.url(forResource: (file as NSString).deletingPathExtension,
                                                          withExtension: (file as NSString).pathExtension) != nil {
            list.append(SoundOption(id: "bundled:\(file)", displayName: name, fileName: file, source: .bundled))
        }

        // The iPhone's built-in sound library — enumerated live so the list
        // matches whatever this device ships with.
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(atPath: Self.systemLibraryPath) {
            let soundFiles = files
                .filter { ["caf", "aiff", "wav", "m4a"].contains((($0 as NSString).pathExtension).lowercased()) }
                .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

            for file in soundFiles {
                let stem = ((file as NSString).deletingPathExtension)
                // Skip obviously non-alert noises (keyboards, camera, UI ticks).
                let skip = ["key_press_click", "photoShutter", "keyboard", "lock", "unlock",
                            "touchtone", "vc~ended", "shake", "begin", "end_call"]
                if skip.contains(where: { stem.lowercased().contains($0) }) { continue }

                let friendly = Self.friendlyNames[stem] ?? Self.prettify(stem)
                list.append(SoundOption(id: "system:\(file)", displayName: friendly, fileName: file, source: .systemLibrary))
            }
        }

        options = list
    }

    private static func prettify(_ stem: String) -> String {
        stem.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "~", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }

    // MARK: - Lookup

    func option(forID id: String) -> SoundOption? {
        options.first { $0.id == id }
    }

    /// Resolve a settings sound id into the UNNotificationSound for scheduling.
    func notificationSound(forID id: String) -> UNNotificationSound {
        guard id != "default", let option = option(forID: id) else { return .default }
        switch option.source {
        case .systemDefault:
            return .default
        case .bundled:
            guard let file = option.fileName else { return .default }
            return UNNotificationSound(named: UNNotificationSoundName(file))
        case .systemLibrary:
            guard let file = option.fileName else { return .default }
            // Works only when the file has been copied into Library/Sounds.
            return installedSystemSounds.contains(file)
                ? UNNotificationSound(named: UNNotificationSoundName(file))
                : .default
        }
    }

    // MARK: - Selection / installation

    /// Install a system-library sound into Library/Sounds so notifications
    /// can reference it. Returns whether the file is notification-ready.
    @discardableResult
    func installForNotifications(_ option: SoundOption) -> Bool {
        switch option.source {
        case .systemDefault, .bundled:
            return true
        case .systemLibrary:
            guard let file = option.fileName else { return false }
            if installedSystemSounds.contains(file) { return true }

            let fm = FileManager.default
            try? fm.createDirectory(at: Self.librarySoundsDir, withIntermediateDirectories: true)
            let src = URL(fileURLWithPath: Self.systemLibraryPath).appendingPathComponent(file)
            let dst = Self.librarySoundsDir.appendingPathComponent(file)

            if fm.fileExists(atPath: dst.path) {
                installedSystemSounds.insert(file)
                return true
            }
            do {
                try fm.copyItem(at: src, to: dst)
                installedSystemSounds.insert(file)
                return true
            } catch {
                // Sandbox refused — the sound stays preview-only.
                return false
            }
        }
    }

    private func refreshInstalledSounds() {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: Self.librarySoundsDir.path)) ?? []
        installedSystemSounds = Set(files)
    }

    // MARK: - Preview

    /// Play the sound at the given volume (volume applies to bundled/Library
    /// sounds via AVAudioPlayer; AudioServices previews play at system level).
    func preview(_ option: SoundOption, volume: Double) {
        stopPreview()

        switch option.source {
        case .systemDefault:
            AudioServicesPlaySystemSound(1004)   // classic "new mail" ping as the system default stand-in
        case .bundled, .systemLibrary:
            guard let file = option.fileName else { return }
            let url: URL?
            switch option.source {
            case .bundled:
                url = Bundle.main.url(forResource: (file as NSString).deletingPathExtension,
                                      withExtension: (file as NSString).pathExtension)
            case .systemLibrary:
                let installed = Self.librarySoundsDir.appendingPathComponent(file)
                let native = URL(fileURLWithPath: Self.systemLibraryPath).appendingPathComponent(file)
                url = FileManager.default.fileExists(atPath: installed.path) ? installed : native
            default:
                url = nil
            }
            guard let url else { return }

            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.volume = Float(min(max(volume, 0), 1))
                player.play()
                audioPlayer = player
            } else {
                // AVAudioPlayer refused (rare) — fall back to AudioServices.
                if AudioServicesCreateSystemSoundID(url as CFURL, &systemSoundID) == kAudioServicesNoError {
                    AudioServicesPlaySystemSound(systemSoundID)
                }
            }
        }
    }

    func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        if systemSoundID != 0 {
            AudioServicesDisposeSystemSoundID(systemSoundID)
            systemSoundID = 0
        }
    }
}
