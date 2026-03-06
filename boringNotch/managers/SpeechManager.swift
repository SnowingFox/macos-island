import AVFoundation
import Cocoa
import Speech

@MainActor
class SpeechManager: NSObject, ObservableObject {
    static let shared = SpeechManager()

    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var audioLevel: Float = 0
    @Published var recordingDuration: TimeInterval = 0
    @Published var error: String?

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var durationTimer: Timer?

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer()
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        error = nil
        transcribedText = ""
        recordingDuration = 0
        audioLevel = 0

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch status {
                case .authorized:
                    self.beginRecording()
                case .denied:
                    self.error = "Speech recognition denied"
                case .restricted:
                    self.error = "Speech recognition restricted"
                case .notDetermined:
                    self.error = "Speech recognition not determined"
                @unknown default:
                    self.error = "Unknown authorization status"
                }
            }
        }
    }

    private func beginRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            error = "Speech recognizer not available"
            return
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            error = "Failed to create recognition request"
            return
        }

        recognitionRequest.shouldReportPartialResults = true
        if #available(macOS 13, *) {
            recognitionRequest.addsPunctuation = true
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.processAudioLevel(buffer: buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) {
            [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                if let error = error as? NSError {
                    if error.domain != "kAFAssistantErrorDomain" || error.code != 1110 {
                        self.error = error.localizedDescription
                    }
                }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.error = "Audio engine failed: \(error.localizedDescription)"
            return
        }

        isRecording = true

        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recordingDuration += 0.1
            }
        }
    }

    private nonisolated func processAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return }

        var sum: Float = 0
        for i in stride(from: 0, to: frames, by: buffer.stride) {
            let val = channelDataValue[i]
            sum += val * val
        }
        let rms = sqrt(sum / Float(frames))
        let level = max(0, min(1, rms * 8))

        Task { @MainActor [weak self] in
            self?.audioLevel = level
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        durationTimer?.invalidate()
        durationTimer = nil

        isRecording = false

        let finalText = transcribedText
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        guard !finalText.isEmpty else { return }
        pasteTextToActiveApp(finalText)
    }

    private func pasteTextToActiveApp(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let source = CGEventSource(stateID: .combinedSessionState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }
}
