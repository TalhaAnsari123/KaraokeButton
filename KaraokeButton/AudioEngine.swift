import Foundation
import AVFoundation

class AudioEngine: ObservableObject {
    private var engine = AVAudioEngine()
    private var inputNode: AVAudioInputNode!
    private var outputNode: AVAudioOutputNode!
    private var mixer = AVAudioMixerNode()
    private var isEngineRunning = false

    @Published var isRunning = false

    init() {
        setupAudioSession()
        setupEngine()
        addRouteChangeObserver()
    }

    deinit {
        removeRouteChangeObserver()
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothA2DP, .allowAirPlay, .defaultToSpeaker])
            
            
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func setupEngine() {
        inputNode = engine.inputNode
        outputNode = engine.outputNode

        engine.attach(mixer)

        let inputFormat = inputNode.outputFormat(forBus: 0)
        let outputFormat = outputNode.inputFormat(forBus: 0)

        engine.connect(inputNode, to: mixer, format: inputFormat)
        engine.connect(mixer, to: outputNode, format: outputFormat)
    }

    func start() {
        guard !isEngineRunning else { return }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
        
        engine.prepare()
        do {
            try engine.start()
            isRunning = true
            isEngineRunning = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stop() {
        guard isEngineRunning else { return }
        engine.stop()
        isRunning = false
        isEngineRunning = false
    }

    private func addRouteChangeObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)
    }

    private func removeRouteChangeObserver() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable:
            restartEngine()
        default:
            break
        }
    }

    private func restartEngine() {
        if isEngineRunning {
            stop()
            start()
        }
    }
}
