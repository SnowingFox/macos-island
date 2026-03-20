import SwiftUI

struct SpeechRecordingIndicator: View {
    @EnvironmentObject private var vm: BoringViewModel
    @ObservedObject private var speechManager = SpeechManager.shared
    @Namespace private var speechNamespace

    private var closedHeight: CGFloat {
        max(28, vm.effectiveClosedNotchHeight)
    }

    private var centerGapWidth: CGFloat {
        max(0, vm.closedNotchSize.width - cornerRadiusInsets.closed.top)
    }

    private var leadingWidth: CGFloat {
        speechManager.prefersExpandedUI ? 88 : max(0, closedHeight + 14)
    }

    private var trailingWidth: CGFloat {
        if speechManager.prefersExpandedUI {
            return max(220, 460 - centerGapWidth - leadingWidth)
        }
        return max(0, closedHeight + 24)
    }

    var body: some View {
        HStack(spacing: 0) {
            leadingSurface
            centerGap
            trailingSurface
        }
        .frame(height: closedHeight, alignment: .center)
        .animation(.interactiveSpring(response: 0.38, dampingFraction: 0.8), value: speechManager.phase)
        .animation(.smooth(duration: 0.16), value: speechManager.audioLevel)
        .animation(.smooth(duration: 0.16), value: speechManager.assetInstallProgress)
    }

    private var leadingSurface: some View {
        ZStack {
            Capsule()
                .fill(Color.clear)
                .frame(width: leadingWidth, height: max(0, closedHeight - 8))
                .glassEffect(.regular, in: .capsule)
                .glassEffectID("speech.leadingSurface", in: speechNamespace)

            HStack(spacing: speechManager.prefersExpandedUI ? 8 : 6) {
                micHero

                if speechManager.prefersExpandedUI {
                    Text(micLabel)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "speech.label", in: speechNamespace)
                }
            }
            .padding(.horizontal, speechManager.prefersExpandedUI ? 12 : 8)
        }
        .frame(width: leadingWidth, height: closedHeight)
    }

    private var micHero: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.16))
                .frame(width: speechManager.prefersExpandedUI ? 28 : 18, height: speechManager.prefersExpandedUI ? 28 : 18)
                .phaseAnimator([0.85, 1.12, 0.9]) { content, scale in
                    content
                        .scaleEffect(scale)
                        .opacity(speechManager.isRecording ? 1 : 0.7)
                } animation: { _ in
                    .easeInOut(duration: 0.8)
                }

            Image(systemName: symbolName)
                .font(.system(size: speechManager.prefersExpandedUI ? 13 : 10, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
                .matchedGeometryEffect(id: "speech.symbol", in: speechNamespace)
        }
    }

    private var centerGap: some View {
        Rectangle()
            .fill(.black)
            .frame(width: centerGapWidth)
    }

    private var trailingSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: speechManager.prefersExpandedUI ? 16 : 14, style: .continuous)
                .fill(Color.clear)
                .frame(width: trailingWidth, height: max(0, closedHeight - 8))
                .glassEffect(.regular, in: .rect(cornerRadius: speechManager.prefersExpandedUI ? 16 : 14))
                .glassEffectID("speech.trailingSurface", in: speechNamespace)

            Group {
                switch speechManager.phase {
                case .recordingCompact:
                    compactTrailingContent
                case .recordingExpanded, .finalizing:
                    expandedTrailingContent
                case .setup:
                    setupTrailingContent
                case .error:
                    errorTrailingContent
                case .idle:
                    EmptyView()
                }
            }
            .padding(.horizontal, speechManager.prefersExpandedUI ? 14 : 10)
        }
        .frame(width: trailingWidth, height: closedHeight)
    }

    private var compactTrailingContent: some View {
        HStack(spacing: 8) {
            audioLevelBars(barCount: 3)
                .matchedGeometryEffect(id: "speech.meter", in: speechNamespace)

            Text(speechManager.formattedDuration)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var expandedTrailingContent: some View {
        HStack(spacing: 10) {
            Text(expandedHeadline)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .matchedGeometryEffect(id: "speech.transcript", in: speechNamespace)

            Spacer(minLength: 0)

            audioLevelBars(barCount: 5)
                .matchedGeometryEffect(id: "speech.meter", in: speechNamespace)

            Text(speechManager.formattedDuration)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.86))
        }
    }

    private var setupTrailingContent: some View {
        HStack(spacing: 10) {
            if case .installingAssets = speechManager.setupState {
                installProgress
            } else {
                Text(speechManager.displayTranscript)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let title = speechManager.primaryActionTitle {
                Button(title) {
                    speechManager.performPrimaryAction()
                }
                .buttonStyle(.glassProminent)
                .controlSize(.small)
            }
        }
    }

    private var errorTrailingContent: some View {
        HStack(spacing: 10) {
            Text(speechManager.displayTranscript)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)

            Spacer(minLength: 0)

            if let title = speechManager.primaryActionTitle {
                Button(title) {
                    speechManager.performPrimaryAction()
                }
                .buttonStyle(.glassProminent)
                .controlSize(.small)
            }
        }
    }

    private var installProgress: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(Color.white.opacity(0.12))
                .frame(width: 64, height: 5)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(accentColor.gradient)
                        .frame(width: max(8, 64 * speechManager.assetInstallProgress), height: 5)
                }

            Text("\(Int(speechManager.assetInstallProgress * 100))%")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.82))
        }
    }

    private func audioLevelBars(barCount: Int) -> some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(accentColor.gradient)
                    .frame(width: speechManager.prefersExpandedUI ? 3 : 2.2, height: barHeight(for: index, total: barCount))
            }
        }
        .frame(height: speechManager.prefersExpandedUI ? 16 : 12)
    }

    private func barHeight(for index: Int, total: Int) -> CGFloat {
        let level = CGFloat(speechManager.audioLevel)
        let base = speechManager.prefersExpandedUI ? 4.5 : 3
        let maxHeight = speechManager.prefersExpandedUI ? 16.0 : 12.0
        let offsets = total == 5 ? [0.35, 0.65, 1.0, 0.7, 0.4] : [0.7, 1.0, 0.5]
        return min(maxHeight, max(base, base + level * maxHeight * offsets[index]))
    }

    private var expandedHeadline: String {
        let transcript = speechManager.displayTranscript
        if transcript == "Listening…" || transcript.isEmpty {
            return speechManager.displayHint
        }
        return transcript
    }

    private var symbolName: String {
        switch speechManager.phase {
        case .finalizing:
            return "arrow.turn.down.left"
        case .error:
            return speechManager.errorState == .cancelled ? "mic.slash" : "exclamationmark.bubble"
        case .setup:
            switch speechManager.setupState {
            case .assetsRequired, .installingAssets:
                return "arrow.down.circle"
            case .microphoneDenied, .speechDenied, .unsupportedLocale:
                return "mic.slash"
            default:
                return "mic.fill"
            }
        default:
            return "mic.fill"
        }
    }

    private var micLabel: String {
        switch speechManager.phase {
        case .finalizing:
            return "Insert"
        case .setup:
            return "Setup"
        case .error:
            return "Retry"
        default:
            return "Dictate"
        }
    }

    private var accentColor: Color {
        switch speechManager.phase {
        case .error:
            return .orange
        case .setup:
            return speechManager.setupState == .assetsRequired || speechManager.setupState == .installingAssets
                ? .cyan
                : .orange
        case .finalizing:
            return .green
        default:
            return .red
        }
    }
}
