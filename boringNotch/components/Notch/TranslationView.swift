//
//  TranslationView.swift
//  boringNotch
//
//  Translation interface with text input, language picker, and results.
//

import Defaults
import SwiftUI

struct TranslationView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var translationManager = TranslationManager.shared
    @Default(.useLiquidGlass) var useLiquidGlass

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            content
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        )
    }

    private var header: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    translationManager.dismiss()
                    BoringViewCoordinator.shared.currentView = .home
                    vm.notchSize = openNotchSize
                    NSApp.keyWindow?.resignKey()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(useLiquidGlass ? .white.opacity(0.7) : .gray)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            languageIndicator

            Spacer()

            Color.clear.frame(width: 44, height: 1)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var languageIndicator: some View {
        if !translationManager.result.sourceLang.isEmpty {
            HStack(spacing: 6) {
                Text(translationManager.result.sourceLang)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .conditionalModifier(useLiquidGlass) { $0.shadow(color: .black.opacity(0.2), radius: 0.5, y: 0.5) }
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundStyle(useLiquidGlass ? .white.opacity(0.6) : .gray)
                Text(translationManager.result.targetLang)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .conditionalModifier(useLiquidGlass) { $0.shadow(color: .black.opacity(0.2), radius: 0.5, y: 0.5) }
            }
        } else {
            Text("Translation")
                .font(.system(size: 13, weight: .semibold))
                .adaptiveText(isGlass: useLiquidGlass)
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            inputBar
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 8) {
                    if !translationManager.result.sourceText.isEmpty {
                        translationSection(
                            label: "ORIGINAL",
                            text: translationManager.result.sourceText,
                            style: .secondary
                        )

                        Divider().background(Color.white.opacity(0.1))

                        if translationManager.result.isLoading {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Translating...")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray)
                            }
                            .padding(.vertical, 8)
                        } else if !translationManager.result.translatedText.isEmpty {
                            HStack(alignment: .top) {
                                translationSection(
                                    label: "TRANSLATION",
                                    text: translationManager.result.translatedText,
                                    style: .primary
                                )

                                Spacer()

                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(translationManager.result.translatedText, forType: .string)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundStyle(useLiquidGlass ? .white.opacity(0.7) : .gray)
                                        .padding(5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .fill(Color.white.opacity(useLiquidGlass ? 0.12 : 0.08))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Copy translation")
                            }
                        }
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.system(size: 20))
                                .conditionalModifier(useLiquidGlass) { $0.glassIcon() }
                                .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(.gray.opacity(0.5)) }
                            Text("Type text above and press Return to translate")
                                .font(.system(size: 11))
                                .conditionalModifier(useLiquidGlass) { $0.glassSecondaryText() }
                                .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(.gray) }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 6) {
            TextField("Type or paste text to translate...", text: $translationManager.inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(useLiquidGlass ? Color.white.opacity(0.1) : Color.white.opacity(0.06))
                )
                .onSubmit {
                    translationManager.translateCustomText()
                }

            targetLanguagePicker

            Button {
                translationManager.translateCustomText()
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.cyan)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(translationManager.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var targetLanguagePicker: some View {
        Menu {
            ForEach(TranslationLanguage.allCases) { lang in
                Button {
                    translationManager.targetLanguage = lang
                } label: {
                    HStack {
                        Text(lang.displayName)
                        if translationManager.targetLanguage == lang {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "globe")
                    .font(.system(size: 10))
                Text(translationManager.targetLanguage.displayName)
                    .font(.system(size: 10, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .semibold))
            }
            .foregroundStyle(useLiquidGlass ? .white.opacity(0.8) : .gray)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(useLiquidGlass ? 0.12 : 0.08))
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private enum TextStyle { case primary, secondary }

    private func translationSection(label: String, text: String, style: TextStyle) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(useLiquidGlass ? .white.opacity(0.5) : .gray.opacity(0.6))
                .conditionalModifier(useLiquidGlass) { $0.shadow(color: .black.opacity(0.15), radius: 0.5, y: 0.5) }
            Text(text)
                .font(.system(size: style == .primary ? 13 : 12, weight: style == .primary ? .medium : .regular))
                .foregroundStyle(style == .primary ? .white : .white.opacity(0.75))
                .conditionalModifier(useLiquidGlass) { $0.shadow(color: .black.opacity(0.3), radius: 1, y: 0.5) }
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
