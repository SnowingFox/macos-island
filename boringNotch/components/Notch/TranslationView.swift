//
//  TranslationView.swift
//  boringNotch
//
//  Translation interface with text input, language display, and results.
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
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.gray)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            if !translationManager.result.sourceLang.isEmpty {
                HStack(spacing: 6) {
                    Text(translationManager.result.sourceLang)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                    Text(translationManager.result.targetLang)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else {
                Text("Translation")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Color.clear.frame(width: 44, height: 1)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                inputBar

                if let error = translationManager.result.error {
                    VStack(spacing: 6) {
                        Image(systemName: "text.cursor")
                            .font(.system(size: 20))
                            .foregroundStyle(.gray)
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                        Text("Type text above, or select text and press Fn + T")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(white: 0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else if !translationManager.result.sourceText.isEmpty {
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
                    } else {
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
                                    .foregroundStyle(.gray)
                                    .padding(5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(Color.white.opacity(0.08))
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
                            .foregroundStyle(.gray.opacity(0.5))
                        Text("Type text above and press Return to translate")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                        Text("Or select text anywhere and press Fn + T")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(white: 0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
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

    private enum TextStyle { case primary, secondary }

    private func translationSection(label: String, text: String, style: TextStyle) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.gray.opacity(0.6))
            Text(text)
                .font(.system(size: style == .primary ? 13 : 12, weight: style == .primary ? .medium : .regular))
                .foregroundStyle(style == .primary ? .white : .white.opacity(0.75))
                .textSelection(.enabled)
                .lineLimit(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
