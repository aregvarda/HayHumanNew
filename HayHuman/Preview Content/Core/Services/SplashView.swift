import SwiftUI
import AVFoundation

/// Мини-сплэш, который показывает launch.mp4 и сам закрывается
struct MinimalSplashView: View {
    var onFinish: () -> Void
    @State private var player: AVPlayer? = nil

    var body: some View {
        PlayerContainer(player: player)
            .background(Color.black)
            .ignoresSafeArea()
            .onAppear(perform: start)
    }

    private func start() {
        guard let url = Bundle.main.url(forResource: "launch", withExtension: "mp4") else {
            onFinish()
            return
        }
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.isMuted = true
        player = p

        // закрыть по окончании видео
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
            onFinish()
        }

        // fallback через 4 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            onFinish()
        }

        item.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            p.play()
        }
    }
}

private struct PlayerContainer: UIViewRepresentable {
    let player: AVPlayer?
    func makeUIView(context: Context) -> PlayerView {
        let v = PlayerView()
        v.playerLayer.videoGravity = .resizeAspectFill
        return v
    }
    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        layer.masksToBounds = true
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        layer.masksToBounds = true
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
