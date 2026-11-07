import Foundation
import Combine
import AVFoundation
import Speech

final class VoiceController: NSObject, ObservableObject {
    @Published private(set) var recording = false
    @Published private(set) var requesting = false
    @Published private(set) var status = "Tocca il microfono per dettare."
    @Published var error: String?
    private let engine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognition: SFSpeechRecognitionTask?
    private var tapInstalled = false
    private var inputAudioActive = false
    private var sessionID = UUID()
    private var timeout: DispatchWorkItem?

    // UI entry points and all observable mutations run on main.
    func start(allowNetwork: Bool, update: @escaping (String) -> Void) {
        guard !requesting, !recording else { return }
        silence(); error = nil; requesting = true
        let id = UUID(); sessionID = id
        SFSpeechRecognizer.requestAuthorization { authorization in
            DispatchQueue.main.async {
                guard self.sessionID == id else { return }
                guard authorization == .authorized else {
                    self.requesting = false; self.error = "Consenti Riconoscimento vocale nelle impostazioni iOS dell’app, se disponibile."; return
                }
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        guard self.sessionID == id else { return }
                        self.requesting = false
                        guard granted else { self.error = "Consenti il microfono nelle impostazioni iOS dell’app."; return }
                        do { try self.begin(id: id, allowNetwork: allowNetwork, update: update) }
                        catch { self.stop(); self.error = error.localizedDescription }
                    }
                }
            }
        }
    }
    private func begin(id: UUID, allowNetwork: Bool, update: @escaping (String) -> Void) throws {
        guard let speech = SFSpeechRecognizer(locale: Locale(identifier: "it-IT")), speech.isAvailable else { throw VoiceError.unavailable }
        guard speech.supportsOnDeviceRecognition || allowNetwork else { throw VoiceError.needsNetwork }
        let audio = AVAudioSession.sharedInstance()
        try audio.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audio.setActive(true, options: .notifyOthersOnDeactivation)
        inputAudioActive = true
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw VoiceError.noInput }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = speech.supportsOnDeviceRecognition
        self.request = request; recognizer = speech
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
        tapInstalled = true
        recording = true
        status = request.requiresOnDeviceRecognition ? "Ascolto locale · massimo 45 secondi" : "Ascolto tramite servizio Apple · massimo 45 secondi"
        recognition = speech.recognitionTask(with: request) { result, failure in
            DispatchQueue.main.async {
                guard self.sessionID == id else { return }
                if let result = result { update(String(result.bestTranscription.formattedString.prefix(1000))) }
                if result?.isFinal == true || failure != nil {
                    self.stop()
                    if let failure = failure { self.error = failure.localizedDescription }
                }
            }
        }
        engine.prepare(); try engine.start()
        let timer = DispatchWorkItem { [weak self] in
            guard let self = self, self.sessionID == id else { return }; self.stop()
        }
        timeout = timer; DispatchQueue.main.asyncAfter(deadline: .now() + 45, execute: timer)
    }
    func stop() {
        sessionID = UUID(); timeout?.cancel(); timeout = nil
        engine.stop()
        if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
        request?.endAudio(); recognition?.cancel()
        request = nil; recognition = nil; recognizer = nil
        let hadAudio = inputAudioActive
        inputAudioActive = false
        recording = false; requesting = false
        if hadAudio { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
        status = "Dettatura ferma. Rivedi il testo e premi Invia."
    }
    func speak(_ text: String) {
        guard !recording, !requesting, !text.isEmpty else { return }
        silence()
        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try audio.setActive(true)
            let utterance = AVSpeechUtterance(string: String(text.prefix(4000)))
            utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            synthesizer.speak(utterance)
        } catch { self.error = error.localizedDescription }
    }
    func silence() { synthesizer.stopSpeaking(at: .immediate) }
    func stopAll() { stop(); silence(); try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
    enum VoiceError: LocalizedError {
        case unavailable, needsNetwork, noInput
        var errorDescription: String? {
            switch self {
            case .unavailable: return "Riconoscimento italiano non disponibile ora. Prova più tardi o usa la tastiera."
            case .needsNetwork: return "La dettatura locale italiana non è disponibile. Puoi consentire il servizio vocale Apple nelle impostazioni dell’app: l’audio potrebbe essere elaborato online."
            case .noInput: return "Microfono non disponibile: termina eventuali chiamate o altre registrazioni."
            }
        }
    }
}
