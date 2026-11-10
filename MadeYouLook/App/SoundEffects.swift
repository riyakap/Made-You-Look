import AVFoundation

/// Short UI sounds ("ding!") for saving items and adding to the bag.
/// Uses the ambient audio category, so sounds respect the silent switch and mix with music.
final class SoundEffects {
    static let shared = SoundEffects()

    /// UserDefaults key behind Settings > Sound Effects.
    static let enabledKey = "soundEffectsEnabled"

    enum Sound: String, CaseIterable {
        case save = "ding_save"
        case addToBag = "ding_bag"
    }

    private var players: [Sound: AVAudioPlayer] = [:]

    private init() {
        UserDefaults.standard.register(defaults: [Self.enabledKey: true])
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.volume = 0.6
            player.prepareToPlay()
            players[sound] = player
        }
    }

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    func play(_ sound: Sound) {
        guard isEnabled, let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
    }
}
