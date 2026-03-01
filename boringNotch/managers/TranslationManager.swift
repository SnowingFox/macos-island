//
//  TranslationManager.swift
//  boringNotch
//
//  Translates text via Google Translate API. Supports selected text capture
//  and custom text input. Auto-detects CN<->EN direction.
//

import AppKit
import NaturalLanguage
import SwiftUI

struct TranslationResult {
    var sourceText: String = ""
    var translatedText: String = ""
    var sourceLang: String = ""
    var targetLang: String = ""
    var isLoading: Bool = false
    var error: String? = nil
}

@MainActor
class TranslationManager: ObservableObject {
    static let shared = TranslationManager()

    @Published var result = TranslationResult()
    @Published var showTranslation = false
    @Published var inputText: String = ""

    private init() {}

    func translateSelectedText() {
        Task {
            let text = await captureText()

            guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                result = TranslationResult(error: "No selected text found.")
                inputText = ""
                showTranslation = true
                return
            }

            inputText = text
            await translate(text)
        }
    }

    func translateCustomText() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Task { await translate(text) }
    }

    func translate(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let detected = detectLanguage(trimmed)
        let isChinese = detected == "zh" || detected == "zh-Hans" || detected == "zh-Hant"
        let targetCode = isChinese ? "en" : "zh-CN"

        result = TranslationResult(
            sourceText: trimmed,
            sourceLang: displayName(for: detected ?? "auto"),
            targetLang: displayName(for: targetCode),
            isLoading: true
        )
        showTranslation = true

        let translated = await googleTranslate(text: trimmed, to: targetCode)
        result.translatedText = translated
        result.isLoading = false
    }

    func dismiss() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showTranslation = false
        }
    }

    // MARK: - Google Translate API

    private func googleTranslate(text: String, to target: String) async -> String {
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=\(target)&dt=t&q=\(encoded)"
        guard let url = URL(string: urlString) else { return text }

        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: request)

            guard let json = try JSONSerialization.jsonObject(with: data) as? [Any],
                  let sentences = json.first as? [[Any]] else {
                return text
            }

            var translated = ""
            for sentence in sentences {
                if let part = sentence.first as? String {
                    translated += part
                }
            }
            return translated.isEmpty ? text : translated
        } catch {
            return text
        }
    }

    // MARK: - Text Capture

    private func captureText() async -> String? {
        // 1. Try Accessibility API for direct selected text (no clipboard pollution)
        if let axText = getSelectedTextViaAX(), !axText.isEmpty {
            return axText
        }

        // 2. Try simulated Cmd+C — only accept if clipboard actually changed
        let before = NSPasteboard.general.changeCount
        simulateCopy()
        try? await Task.sleep(for: .milliseconds(200))
        let after = NSPasteboard.general.changeCount

        if after != before, let text = NSPasteboard.general.string(forType: .string), !text.isEmpty {
            return text
        }

        // Don't fall back to existing clipboard — user expects selected text
        return nil
    }

    private func getSelectedTextViaAX() -> String? {
        let sys = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute as CFString, &focused) == .success else {
            return nil
        }
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(focused as! AXUIElement, kAXSelectedTextAttribute as CFString, &value) == .success else {
            return nil
        }
        return value as? String
    }

    private func simulateCopy() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    // MARK: - Language

    private func detectLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }

    private func displayName(for code: String) -> String {
        switch code {
        case "zh", "zh-Hans", "zh-Hant", "zh-CN": return "中文"
        case "en": return "English"
        case "ja": return "日本語"
        case "ko": return "한국어"
        case "fr": return "Français"
        case "de": return "Deutsch"
        case "es": return "Español"
        case "auto": return "Auto"
        default: return code.uppercased()
        }
    }
}
