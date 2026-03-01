//
//  ClosedNotchContent.swift
//  boringNotch
//
//  Extracted closed-state notch content views.
//

import Defaults
import SwiftUI

// MARK: - Satellite Pill (secondary widget indicator beside the notch)

struct SatellitePillView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var pomodoro = PomodoroManager.shared
    @ObservedObject var marketManager = MarketManager.shared
    @ObservedObject var musicManager = MusicManager.shared

    private var hasMusicPlaying: Bool {
        musicManager.isPlaying || !musicManager.isPlayerIdle
    }

    private var showPomodoro: Bool {
        Defaults[.closedNotchShowPomodoro] && Defaults[.enablePomodoro] && pomodoro.state != .idle
    }

    private var showMarket: Bool {
        Defaults[.closedNotchShowMarket] && Defaults[.enableMarketTicker]
    }

    private var hasSecondaryContent: Bool {
        hasMusicPlaying && (showPomodoro || showMarket)
    }

    var body: some View {
        if hasSecondaryContent && vm.notchState == .closed && !vm.hideOnClosed {
            HStack(spacing: 4) {
                if showPomodoro {
                    PomodoroClosedView()
                }
                if showMarket {
                    MarketClosedIndicatorView()
                }
            }
            .padding(.horizontal, 6)
            .frame(height: max(0, vm.effectiveClosedNotchHeight - 4))
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black)
            )
            .clipShape(Capsule(style: .continuous))
            .transition(.scale(scale: 0.3, anchor: .leading).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showPomodoro)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showMarket)
        }
    }
}

// MARK: - ClosedNotchWidgetBar (fallback when no music)

struct ClosedNotchWidgetBar: View {
    @EnvironmentObject var vm: BoringViewModel

    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(.clear).frame(width: vm.closedNotchSize.width - 20, height: vm.effectiveClosedNotchHeight)

            if Defaults[.closedNotchShowPomodoro] && Defaults[.enablePomodoro] {
                PomodoroClosedView()
            }
            if Defaults[.closedNotchShowMarket] && Defaults[.enableMarketTicker] {
                MarketClosedIndicatorView()
            }
        }
        .frame(height: vm.effectiveClosedNotchHeight, alignment: .center)
    }
}

// MARK: - BoringFaceAnimation

struct BoringFaceAnimation: View {
    @EnvironmentObject var vm: BoringViewModel

    var body: some View {
        HStack {
            HStack {
                Rectangle()
                    .fill(.clear)
                    .frame(
                        width: max(0, vm.effectiveClosedNotchHeight - 12),
                        height: max(0, vm.effectiveClosedNotchHeight - 12)
                    )
                Rectangle()
                    .fill(.black)
                    .frame(width: vm.closedNotchSize.width - 20)
                MinimalFaceFeatures()
            }
        }.frame(
            height: vm.effectiveClosedNotchHeight,
            alignment: .center
        )
    }
}

// MARK: - MusicLiveActivity

struct MusicLiveActivity: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @ObservedObject var musicManager = MusicManager.shared

    var albumArtNamespace: Namespace.ID
    var gestureProgress: CGFloat = 0

    @Default(.useMusicVisualizer) var useMusicVisualizer

    var body: some View {
        HStack {
            Image(nsImage: musicManager.albumArt)
                .resizable()
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: MusicPlayerImageSizes.cornerRadiusInset.closed)
                )
                .matchedGeometryEffect(id: "albumArt", in: albumArtNamespace)
                .frame(
                    width: max(0, vm.effectiveClosedNotchHeight - 12),
                    height: max(0, vm.effectiveClosedNotchHeight - 12)
                )

            Rectangle()
                .fill(.black)
                .overlay(
                    HStack(alignment: .top) {
                        if coordinator.expandingView.show
                            && coordinator.expandingView.type == .music
                        {
                            MarqueeText(
                                .constant(musicManager.songTitle),
                                textColor: Defaults[.coloredSpectrogram]
                                    ? Color(nsColor: musicManager.avgColor) : Color.gray,
                                minDuration: 0.4,
                                frameWidth: 100
                            )
                            .opacity(
                                (coordinator.expandingView.show
                                    && Defaults[.sneakPeekStyles] == .inline)
                                    ? 1 : 0
                            )
                            Spacer(minLength: vm.closedNotchSize.width)
                            Text(musicManager.artistName)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundStyle(
                                    Defaults[.coloredSpectrogram]
                                        ? Color(nsColor: musicManager.avgColor)
                                        : Color.gray
                                )
                                .opacity(
                                    (coordinator.expandingView.show
                                        && coordinator.expandingView.type == .music
                                        && Defaults[.sneakPeekStyles] == .inline)
                                        ? 1 : 0
                                )
                        }
                    }
                )
                .frame(
                    width: (coordinator.expandingView.show
                        && coordinator.expandingView.type == .music
                        && Defaults[.sneakPeekStyles] == .inline)
                        ? 380
                        : vm.closedNotchSize.width
                            + -cornerRadiusInsets.closed.top
                )

            HStack {
                if useMusicVisualizer {
                    Rectangle()
                        .fill(
                            Defaults[.coloredSpectrogram]
                                ? Color(nsColor: musicManager.avgColor).gradient
                                : Color.gray.gradient
                        )
                        .frame(width: 50, alignment: .center)
                        .matchedGeometryEffect(id: "spectrum", in: albumArtNamespace)
                        .mask {
                            AudioSpectrumView(isPlaying: $musicManager.isPlaying)
                                .frame(width: 16, height: 12)
                        }
                } else {
                    LottieAnimationContainer()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(
                width: max(
                    0,
                    vm.effectiveClosedNotchHeight - 12
                        + gestureProgress / 2
                ),
                height: max(
                    0,
                    vm.effectiveClosedNotchHeight - 12
                ),
                alignment: .center
            )
        }
        .frame(
            height: vm.effectiveClosedNotchHeight,
            alignment: .center
        )
    }
}
