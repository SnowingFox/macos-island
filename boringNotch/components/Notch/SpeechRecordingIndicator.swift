import SwiftUI

struct SpeechRecordingIndicator: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject private var speechManager = SpeechManager.shared
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 0) {
            leftIndicator
            centerGap
            rightContent
        }
        .frame(height: vm.effectiveClosedNotchHeight, alignment: .center)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .onDisappear { isPulsing = false }
    }

    private var leftIndicator: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(.red)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.3 : 0.7)
                .opacity(isPulsing ? 1.0 : 0.4)

            Image(systemName: "mic.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(
            width: max(0, vm.effectiveClosedNotchHeight - 4),
            height: max(0, vm.effectiveClosedNotchHeight - 12)
        )
    }

    private var centerGap: some View {
        Rectangle()
            .fill(.black)
            .frame(width: vm.closedNotchSize.width - cornerRadiusInsets.closed.top)
    }

    private var rightContent: some View {
        HStack(spacing: 4) {
            audioLevelBars

            Text(speechManager.formattedDuration)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(
            width: max(0, vm.effectiveClosedNotchHeight + 16),
            height: max(0, vm.effectiveClosedNotchHeight - 12)
        )
    }

    private var audioLevelBars: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.red.gradient)
                    .frame(width: 2, height: barHeight(for: i))
            }
        }
        .frame(width: 10, height: 12)
        .animation(.smooth(duration: 0.15), value: speechManager.audioLevel)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 3
        let level = CGFloat(speechManager.audioLevel)
        let offsets: [CGFloat] = [0.7, 1.0, 0.5]
        return max(base, min(12, base + level * 9 * offsets[index]))
    }
}
