import AVFAudio
import AVFoundation
import Cocoa
import Speech

@MainActor
final class SpeechManager: NSObject, ObservableObject {
    static let shared = SpeechManager()

    enum Phase: Equatable {
        case idle
        case setup
        case recordingCompact
        case recordingExpanded
        case finalizing
        case error
    }

    enum SetupState: Equatable {
        case requestingPermissions
        case permissionsReady
        case microphoneDenied
        case speechDenied
        case unsupportedLocale
        case assetsRequired
        case installingAssets
        case assetsReady
    }

    enum ErrorState: Equatable {
        case cancelled
        case emptyTranscript
        case audioFailure
        case recognitionFailure
    }

    enum PrimaryAction: Equatable {
        case none
        case openMicrophoneSettings
        case openSpeechSettings
        case installAssets
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var transcript = ""
    @Published private(set) var audioLevel: Float = 0
    @Published private(set) var recordingDuration: TimeInterval = 0
    @Published private(set) var resolvedLocale: Locale?
    @Published private(set) var setupState: SetupState?
    @Published private(set) var errorState: ErrorState?
    @Published private(set) var primaryAction: PrimaryAction = .none
    @Published private(set) var statusTitle = ""
    @Published private(set) var statusMessage = ""
    @Published private(set) var assetInstallProgress: Double = 0

    private let audioEngine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var transcriber: DictationTranscriber?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var assetInstallationRequest: AssetInstallationRequest?

    private var bootstrapTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?
    private var resultsTask: Task<Void, Never>?
    private var durationTask: Task<Void, Never>?
    private var expandTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?
    private var dismissTask: Task<Void, Never>?

    private var latestTranscript = ""
    private var expandedDuringCurrentSession = false

    var isRecording: Bool {
        switch phase {
        case .recordingCompact, .recordingExpanded, .finalizing:
            return true
        default:
            return false
        }
    }

    var isPresentingSpeechUI: Bool {
        phase != .idle
    }

    var blocksNotchInteractions: Bool {
        phase != .idle
    }

    var prefersExpandedUI: Bool {
        switch phase {
        case .setup, .error, .recordingExpanded:
            return true
        case .finalizing:
            return expandedDuringCurrentSession
        default:
            return false
        }
    }

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var displayTranscript: String {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        switch phase {
        case .recordingCompact, .recordingExpanded, .finalizing:
            return trimmed.isEmpty ? "Listening…" : trimmed
        case .setup, .error:
            return statusMessage
        case .idle:
            return ""
        }
    }

    var displayHint: String {
        switch phase {
        case .recordingCompact, .recordingExpanded:
            return "松开插入 · Esc 取消"
        case .finalizing:
            return "插入中…"
        case .setup:
            switch setupState {
            case .permissionsReady, .assetsReady:
                return "再按一次 Fn 开始听写"
            case .assetsRequired:
                return "下载后再按一次 Fn"
            default:
                return ""
            }
        case .error:
            switch errorState {
            case .cancelled:
                return "已取消"
            case .emptyTranscript:
                return "没有插入任何文本"
            default:
                return ""
            }
        case .idle:
            return ""
        }
    }

    var primaryActionTitle: String? {
        switch primaryAction {
        case .none:
            return nil
        case .openMicrophoneSettings, .openSpeechSettings:
            return "Open Settings"
        case .installAssets:
            return "Download"
        }
    }

    private override init() {
        super.init()
    }

    func beginFunctionHold() {
        guard phase == .idle else { return }
        cancelDismiss()
        bootstrapTask?.cancel()
        bootstrapTask = Task { @MainActor [weak self] in
            await self?.prepareSessionForFunctionHold()
        }
    }

    func endFunctionHold() {
        switch phase {
        case .recordingCompact, .recordingExpanded:
            finalizeCurrentSession(shouldPaste: true)
        default:
            break
        }
    }

    func cancelCurrentSession() {
        bootstrapTask?.cancel()
        switch phase {
        case .recordingCompact, .recordingExpanded:
            finalizeCurrentSession(shouldPaste: false)
        case .setup, .error:
            transitionToIdle()
        default:
            break
        }
    }

    func performPrimaryAction() {
        switch primaryAction {
        case .installAssets:
            guard let request = assetInstallationRequest else { return }
            startAssetDownload(request)
        case .openMicrophoneSettings:
            openSystemSettingsPrivacyPane("Privacy_Microphone")
        case .openSpeechSettings:
            openSystemSettingsPrivacyPane("Privacy_SpeechRecognition")
        case .none:
            break
        }
    }

    func preferredClosedWidth(baseWidth: CGFloat, closedHeight: CGFloat, maxWidth: CGFloat) -> CGFloat? {
        guard phase != .idle else { return nil }
        if prefersExpandedUI {
            return min(460, maxWidth)
        }
        let addition = 2 * max(0, closedHeight - 4) + 30
        return min(baseWidth + addition, maxWidth)
    }

    private func prepareSessionForFunctionHold() async {
        let permissionOutcome = await ensurePermissions()
        guard !Task.isCancelled else { return }

        switch permissionOutcome {
        case .microphoneDenied:
            showSetup(
                .microphoneDenied,
                title: "Microphone access needed",
                message: "Grant microphone access, then press Fn again.",
                action: .openMicrophoneSettings,
                dismissAfter: nil
            )
            return
        case .speechDenied:
            showSetup(
                .speechDenied,
                title: "Speech access needed",
                message: "Grant speech recognition access, then press Fn again.",
                action: .openSpeechSettings,
                dismissAfter: nil
            )
            return
        case .ready(let prompted) where prompted:
            showSetup(
                .permissionsReady,
                title: "Dictation ready",
                message: "Permissions were granted. Press Fn again to start dictation.",
                action: .none,
                dismissAfter: 1.6
            )
            return
        case .ready:
            break
        }

        do {
            switch try await resolveSpeechResources() {
            case .ready(let locale, let module):
                do {
                    try await startCapture(locale: locale, module: module)
                } catch {
                    presentError(
                        .audioFailure,
                        title: "Audio capture failed",
                        message: error.localizedDescription,
                        dismissAfter: 2.0
                    )
                }
            case .needsAssetInstall(let locale, let request):
                resolvedLocale = locale
                showSetup(
                    .assetsRequired,
                    title: "Dictation model needed",
                    message: "Download the on-device model for \(locale.localizedString()).",
                    action: .installAssets,
                    dismissAfter: nil
                )
                assetInstallationRequest = request
            case .unsupportedLocale(let localeDescription):
                showSetup(
                    .unsupportedLocale,
                    title: "Locale not supported",
                    message: "\(localeDescription) is not available for on-device dictation.",
                    action: .none,
                    dismissAfter: 3.5
                )
            }
        } catch {
            presentError(
                .recognitionFailure,
                title: "Dictation unavailable",
                message: error.localizedDescription,
                dismissAfter: 2.2
            )
        }
    }

    private func startCapture(locale: Locale, module: DictationTranscriber) async throws {
        resetRuntimeState()

        resolvedLocale = locale
        transcriber = module

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let analysisFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [module],
            considering: inputFormat
        ) ?? inputFormat

        let analyzer = SpeechAnalyzer(
            modules: [module],
            options: .init(priority: .userInitiated, modelRetention: .lingering)
        )
        try await analyzer.prepareToAnalyze(in: analysisFormat)
        self.analyzer = analyzer

        let stream = AsyncStream<AnalyzerInput> { continuation in
            self.inputContinuation = continuation
        }

        analysisTask = Task { [weak self] in
            do {
                try await analyzer.start(inputSequence: stream)
            } catch is CancellationError {
            } catch {
                await self?.handleRuntimeFailure(
                    title: "Dictation stopped",
                    message: error.localizedDescription
                )
            }
        }

        resultsTask = Task { [weak self] in
            do {
                for try await result in module.results {
                    await self?.apply(result: result)
                }
            } catch is CancellationError {
            } catch {
                await self?.handleRuntimeFailure(
                    title: "Dictation results failed",
                    message: error.localizedDescription
                )
            }
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: analysisFormat) { [weak self] buffer, _ in
            self?.inputContinuation?.yield(AnalyzerInput(buffer: buffer))
            self?.processAudioLevel(buffer: buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            inputContinuation?.finish()
            self.analyzer = nil
            self.transcriber = nil
            throw error
        }

        withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.8)) {
            phase = .recordingCompact
        }
        statusTitle = "Dictating"
        statusMessage = "Listening…"

        durationTask = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard self.phase == .recordingCompact || self.phase == .recordingExpanded else { return }
                self.recordingDuration += 0.1
            }
        }

        expandTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            guard let self, !Task.isCancelled, self.phase == .recordingCompact else { return }
            self.expandedDuringCurrentSession = true
            withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.8)) {
                self.phase = .recordingExpanded
            }
        }
    }

    private func apply(result: DictationTranscriber.Result) {
        let newTranscript = String(result.text.characters)
        transcript = newTranscript
        latestTranscript = newTranscript
        if result.isFinal {
            statusTitle = "Finalizing dictation"
        }
    }

    private func finalizeCurrentSession(shouldPaste: Bool) {
        guard phase == .recordingCompact || phase == .recordingExpanded else { return }

        durationTask?.cancel()
        expandTask?.cancel()

        let analyzer = self.analyzer
        let currentAnalysisTask = analysisTask
        let currentResultsTask = resultsTask
        stopAudioCapture()

        if shouldPaste {
            withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.8)) {
                phase = .finalizing
            }
            statusTitle = "Inserting dictation"
            statusMessage = "Finishing up…"

            Task { @MainActor [weak self] in
                guard let self else { return }
                var finishedCleanly = true
                if let analyzer {
                    finishedCleanly = await self.awaitFinalization(for: analyzer)
                    if !finishedCleanly {
                        await analyzer.cancelAndFinishNow()
                    }
                }
                await currentAnalysisTask?.value
                await currentResultsTask?.value
                self.cleanupAnalyzerState()

                let finalText = self.latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !finalText.isEmpty else {
                    self.presentError(
                        .emptyTranscript,
                        title: "No speech detected",
                        message: finishedCleanly
                            ? "Try speaking a little louder and hold Fn slightly longer."
                            : "Final result timed out. Nothing was inserted.",
                        dismissAfter: 1.6
                    )
                    return
                }

                self.pasteTextToActiveApp(finalText)
                self.scheduleDismiss(after: 0.3)
            }
        } else {
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let analyzer {
                    await analyzer.cancelAndFinishNow()
                }
                await currentAnalysisTask?.value
                await currentResultsTask?.value
                self.cleanupAnalyzerState()
                self.presentError(
                    .cancelled,
                    title: "Dictation cancelled",
                    message: "Nothing was inserted.",
                    dismissAfter: 0.7
                )
            }
        }
    }

    private func stopAudioCapture() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        inputContinuation?.finish()
        inputContinuation = nil
        audioLevel = 0
    }

    private func cleanupAnalyzerState() {
        analysisTask?.cancel()
        resultsTask?.cancel()
        analysisTask = nil
        resultsTask = nil
        analyzer = nil
        transcriber = nil
    }

    private func resetRuntimeState() {
        bootstrapTask?.cancel()
        dismissTask?.cancel()
        progressTask?.cancel()
        durationTask?.cancel()
        expandTask?.cancel()

        statusTitle = ""
        statusMessage = ""
        primaryAction = .none
        setupState = nil
        errorState = nil
        assetInstallProgress = 0
        transcript = ""
        latestTranscript = ""
        audioLevel = 0
        recordingDuration = 0
        expandedDuringCurrentSession = false
        assetInstallationRequest = nil
    }

    private func showSetup(
        _ state: SetupState,
        title: String,
        message: String,
        action: PrimaryAction,
        dismissAfter: TimeInterval?
    ) {
        resetRuntimeState()
        phase = .setup
        setupState = state
        primaryAction = action
        statusTitle = title
        statusMessage = message
        if let dismissAfter {
            scheduleDismiss(after: dismissAfter)
        }
    }

    private func presentError(
        _ state: ErrorState,
        title: String,
        message: String,
        dismissAfter: TimeInterval?
    ) {
        resetRuntimeState()
        phase = .error
        errorState = state
        statusTitle = title
        statusMessage = message
        if let dismissAfter {
            scheduleDismiss(after: dismissAfter)
        }
    }

    private func transitionToIdle() {
        resetRuntimeState()
        phase = .idle
    }

    private func scheduleDismiss(after delay: TimeInterval) {
        dismissTask?.cancel()
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            guard let self, !Task.isCancelled else { return }
            self.transitionToIdle()
        }
    }

    private func cancelDismiss() {
        dismissTask?.cancel()
        dismissTask = nil
    }

    private func startAssetDownload(_ request: AssetInstallationRequest) {
        showSetup(
            .installingAssets,
            title: "Downloading dictation",
            message: "Installing the on-device language model…",
            action: .none,
            dismissAfter: nil
        )

        progressTask = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled {
                self.assetInstallProgress = request.progress.fractionCompleted
                try? await Task.sleep(for: .milliseconds(120))
            }
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await request.downloadAndInstall()
                self.progressTask?.cancel()
                self.assetInstallProgress = 1
                self.showSetup(
                    .assetsReady,
                    title: "Dictation installed",
                    message: "The model is ready. Press Fn again to start dictation.",
                    action: .none,
                    dismissAfter: 1.6
                )
            } catch {
                self.progressTask?.cancel()
                self.presentError(
                    .recognitionFailure,
                    title: "Download failed",
                    message: error.localizedDescription,
                    dismissAfter: 2.5
                )
            }
        }
    }

    private enum PermissionOutcome {
        case ready(prompted: Bool)
        case microphoneDenied
        case speechDenied
    }

    private func ensurePermissions() async -> PermissionOutcome {
        var prompted = false

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .notDetermined:
            prompted = true
            let granted = await requestMicrophonePermission()
            guard granted else { return .microphoneDenied }
        case .denied, .restricted:
            return .microphoneDenied
        @unknown default:
            return .microphoneDenied
        }

        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            break
        case .notDetermined:
            prompted = true
            let granted = await requestSpeechPermission()
            guard granted else { return .speechDenied }
        case .denied, .restricted:
            return .speechDenied
        @unknown default:
            return .speechDenied
        }

        return .ready(prompted: prompted)
    }

    private enum ResourceOutcome {
        case ready(locale: Locale, module: DictationTranscriber)
        case needsAssetInstall(locale: Locale, request: AssetInstallationRequest)
        case unsupportedLocale(String)
    }

    private func resolveSpeechResources() async throws -> ResourceOutcome {
        let systemLocale = Locale.autoupdatingCurrent
        guard let locale = await DictationTranscriber.supportedLocale(equivalentTo: systemLocale) else {
            return .unsupportedLocale(systemLocale.localizedString(forIdentifier: systemLocale.identifier) ?? systemLocale.identifier)
        }

        resolvedLocale = locale
        let module = DictationTranscriber(locale: locale, preset: .progressiveLongDictation)
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            return .needsAssetInstall(locale: locale, request: request)
        }

        return .ready(locale: locale, module: module)
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func awaitFinalization(for analyzer: SpeechAnalyzer) async -> Bool {
        let finalizationTask = Task {
            do {
                try await analyzer.finalizeAndFinishThroughEndOfInput()
                return true
            } catch {
                return false
            }
        }

        let timeoutTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            return false
        }

        let result = await withTaskGroup(of: Bool.self) { group in
            group.addTask { await finalizationTask.value }
            group.addTask { await timeoutTask.value }
            let firstResult = await group.next() ?? false
            group.cancelAll()
            return firstResult
        }

        timeoutTask.cancel()
        if !result {
            finalizationTask.cancel()
        }
        return result
    }

    private func handleRuntimeFailure(title: String, message: String) {
        guard phase != .idle else { return }
        stopAudioCapture()
        cleanupAnalyzerState()
        presentError(.recognitionFailure, title: title, message: message, dismissAfter: 2.0)
    }

    private nonisolated func processAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return }

        var sum: Float = 0
        for index in stride(from: 0, to: frames, by: buffer.stride) {
            let value = channelDataValue[index]
            sum += value * value
        }

        let rms = sqrt(sum / Float(frames))
        let level = max(0, min(1, rms * 8))

        Task { @MainActor [weak self] in
            self?.audioLevel = level
        }
    }

    private func pasteTextToActiveApp(_ text: String) {
        let pasteboard = NSPasteboard.general
        let previousItems = (pasteboard.pasteboardItems ?? []).compactMap { $0.copy() as? NSPasteboardItem }

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let temporaryChangeCount = pasteboard.changeCount

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let source = CGEventSource(stateID: .combinedSessionState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            guard pasteboard.changeCount == temporaryChangeCount else { return }
            pasteboard.clearContents()
            if !previousItems.isEmpty {
                pasteboard.writeObjects(previousItems)
            }
        }
    }

    private func openSystemSettingsPrivacyPane(_ pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

private extension Locale {
    func localizedString() -> String {
        localizedString(forIdentifier: identifier) ?? identifier
    }
}
