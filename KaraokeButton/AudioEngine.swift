import Foundation
import AVFoundation
import Combine

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
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothA2DP, .allowAirPlay, .defaultToSpeaker]
            )
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func setupEngine() {
        inputNode = engine.inputNode
        outputNode = engine.outputNode

        engine.attach(mixer)

        let audioSession = AVAudioSession.sharedInstance()

        // Obtain formats from hardware. If they are invalid (zero sample rate or
        // channel count), fall back to the session's defaults. This prevents
        // crashes when the engine is initialized in environments without
        // fully configured audio hardware, such as SwiftUI previews.
        let rawInputFormat = inputNode.outputFormat(forBus: 0)
        let inputFormat: AVAudioFormat
        if rawInputFormat.sampleRate > 0 && rawInputFormat.channelCount > 0 {
            inputFormat = rawInputFormat
        } else {
            inputFormat = AVAudioFormat(
                standardFormatWithSampleRate: audioSession.sampleRate,
                channels: AVAudioChannelCount(max(1, audioSession.inputNumberOfChannels))
            )!
        }

        let rawOutputFormat = outputNode.inputFormat(forBus: 0)
        let outputFormat: AVAudioFormat
        if rawOutputFormat.sampleRate > 0 && rawOutputFormat.channelCount > 0 {
            outputFormat = rawOutputFormat
        } else {
            outputFormat = AVAudioFormat(
                standardFormatWithSampleRate: audioSession.sampleRate,
                channels: AVAudioChannelCount(max(1, audioSession.outputNumberOfChannels))
            )!
        }

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
