//
//  ClosedNotchContent.swift
//  boringNotch
//
//  Extracted closed-state notch content views.
//

import Defaults
import SwiftUI

// MARK: - Closed Widget Visibility Helpers

@MainActor
func closedWidgetShowPomodoro() -> Bool {
    Defaults[.closedNotchShowPomodoro] && Defaults[.enablePomodoro] && PomodoroManager.shared.state != .idle
}

@MainActor
func closedWidgetShowMarket() -> Bool {
    Defaults[.closedNotchShowMarket] && Defaults[.enableMarketTicker]
}

@MainActor
func hasAnyClosedWidgetContent() -> Bool {
    closedWidgetShowPomodoro() || closedWidgetShowMarket()
}

// MARK: - ClosedNotchWidgetBar (no music — widgets flank the notch cutout)

struct ClosedNotchWidgetBar: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject private var pomodoroManager = PomodoroManager.shared
    @ObservedObject private var marketManager = MarketManager.shared

    var body: some View {
        let showPom = closedWidgetShowPomodoro()
        let showMkt = closedWidgetShowMarket()
        let widgetCount = (showPom ? 1 : 0) + (showMkt ? 1 : 0)

        if widgetCount == 0 {
            Rectangle().fill(.clear)
                .frame(width: vm.closedNotchSize.width - 20, height: vm.effectiveClosedNotchHeight)
        } else if widgetCount == 1 {
            singleWidgetFlankingLayout(showPom: showPom, showMkt: showMkt)
        } else {
            twoWidgetFlankingLayout
        }
    }

    /// Single widget: split icon (left) | notch gap | data (right) — like MusicLiveActivity
    @ViewBuilder
    private func singleWidgetFlankingLayout(showPom: Bool, showMkt: Bool) -> some View {
        HStack(spacing: 0) {
            if showPom {
                PomodoroClosedView().leftContent
                    .padding(.trailing, 8)
            } else if showMkt {
                MarketClosedIndicatorView().leftContent
                    .padding(.trailing, 8)
            }

            Rectangle().fill(.black)
                .frame(width: vm.closedNotchSize.width - cornerRadiusInsets.closed.top)

            if showPom {
                PomodoroClosedView().rightContent
                    .padding(.leading, 8)
            } else if showMkt {
                MarketClosedIndicatorView().rightContent
                    .padding(.leading, 8)
            }
        }
        .frame(height: vm.effectiveClosedNotchHeight, alignment: .center)
    }

    /// Two widgets: whole widget (left) | notch gap | whole widget (right)
    private var twoWidgetFlankingLayout: some View {
        HStack(spacing: 0) {
            PomodoroClosedView()
                .padding(.trailing, 10)

            Rectangle().fill(.black)
                .frame(width: vm.closedNotchSize.width - cornerRadiusInsets.closed.top)

            MarketClosedIndicatorView()
                .padding(.leading, 10)
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
