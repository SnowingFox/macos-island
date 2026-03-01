//
//  MarketTickerView.swift
//  boringNotch
//
//  Displays real-time crypto, stock, and commodity prices in the open notch.
//

import Defaults
import SwiftUI

struct MarketTickerView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var marketManager = MarketManager.shared
    @Default(.useLiquidGlass) var useLiquidGlass

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            tickerGrid
            footer
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        )
        .onAppear { marketManager.startMonitoring() }
    }

    private var header: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    BoringViewCoordinator.shared.currentView = .widgets
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Widgets")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(useLiquidGlass ? .white.opacity(0.7) : .gray)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Text("Markets")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .adaptiveText(isGlass: useLiquidGlass)

            Spacer()

            Button {
                marketManager.fetchAll()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .conditionalModifier(useLiquidGlass) { $0.glassIcon() }
                    .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(.gray) }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var tickerGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6),
                ],
                spacing: 6
            ) {
                ForEach(marketManager.assets) { asset in
                    AssetCardView(asset: asset, useLiquidGlass: useLiquidGlass)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private var footer: some View {
        HStack {
            Text("Updated \(formatTime(marketManager.lastUpdated))")
                .font(.system(size: 9))
                .conditionalModifier(useLiquidGlass) { $0.glassSecondaryText() }
                .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(Color(white: 0.5)) }
            Spacer()
            Text("Auto-refresh 30s")
                .font(.system(size: 9))
                .conditionalModifier(useLiquidGlass) { $0.glassSecondaryText() }
                .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(Color(white: 0.5)) }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }
}

private struct AssetCardView: View {
    let asset: MarketAsset
    let useLiquidGlass: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(asset.symbol)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .adaptiveText(isGlass: useLiquidGlass)
                typeIcon
            }

            if asset.isLoaded {
                Text(asset.formattedPrice)
                    .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                    .adaptiveText(isGlass: useLiquidGlass)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 3) {
                    Image(systemName: asset.change24h >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 8, weight: .bold))
                    Text(asset.formattedChange)
                        .font(.system(size: 10, weight: .medium, design: .rounded).monospacedDigit())
                }
                .foregroundStyle(asset.changeColor)
                .conditionalModifier(useLiquidGlass) { $0.shadow(color: .black.opacity(0.25), radius: 0.5, y: 0.5) }

                Text("Vol \(asset.formattedVolume)")
                    .font(.system(size: 8, design: .rounded).monospacedDigit())
                    .conditionalModifier(useLiquidGlass) { $0.glassSecondaryText() }
                    .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(Color(white: 0.5)) }
            } else {
                ProgressView()
                    .controlSize(.mini)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(useLiquidGlass ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
        )
    }

    @ViewBuilder
    private var typeIcon: some View {
        let (icon, color): (String, Color) = {
            switch asset.type {
            case .crypto: return ("bitcoinsign.circle.fill", .orange)
            case .stock: return ("chart.line.uptrend.xyaxis", .blue)
            case .commodity: return ("laurel.leading", .yellow)
            }
        }()
        Image(systemName: icon)
            .font(.system(size: 8))
            .foregroundStyle(color.opacity(0.7))
    }
}

// MARK: - Compact Market Widget (for home view right column)

struct MarketCompactWidget: View {
    @ObservedObject var marketManager = MarketManager.shared
    @Default(.useLiquidGlass) var useLiquidGlass

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 9))
                    .conditionalModifier(useLiquidGlass) { $0.glassSecondaryText() }
                    .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(.gray) }
                Text("Markets")
                    .font(.system(size: 10, weight: .semibold))
                    .conditionalModifier(useLiquidGlass) { $0.glassSecondaryText() }
                    .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(.gray) }
                Spacer()
            }

            let loaded = marketManager.assets.filter(\.isLoaded)
            if loaded.isEmpty {
                Text("Loading...")
                    .font(.system(size: 10))
                    .conditionalModifier(useLiquidGlass) { $0.glassSecondaryText() }
                    .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(Color(white: 0.5)) }
            } else {
                HStack(spacing: 6) {
                    ForEach(loaded.prefix(3)) { asset in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(asset.symbol)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .conditionalModifier(useLiquidGlass) { $0.glassSecondaryText() }
                                .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(.gray) }
                            Text(asset.formattedPrice)
                                .font(.system(size: 10, weight: .medium, design: .rounded).monospacedDigit())
                                .adaptiveText(isGlass: useLiquidGlass)
                                .contentTransition(.numericText())
                        }
                        if asset.id != loaded.prefix(3).last?.id {
                            Divider().frame(height: 20).opacity(useLiquidGlass ? 0.4 : 0.3)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(useLiquidGlass ? Color.white.opacity(0.1) : Color.white.opacity(0.04))
        )
        .onAppear { marketManager.startMonitoring() }
    }
}

// MARK: - Closed Notch Market Indicator

struct MarketClosedIndicatorView: View {
    @ObservedObject var marketManager = MarketManager.shared
    @State private var displayIndex: Int = 0
    @State private var cycleTimer: Timer?

    private var loadedAssets: [MarketAsset] {
        marketManager.assets.filter(\.isLoaded)
    }

    var body: some View {
        let assets = loadedAssets
        if !assets.isEmpty {
            let safeIdx = assets.isEmpty ? 0 : displayIndex % assets.count
            let asset = assets[safeIdx]

            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.gray)

                Text(asset.symbol)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.gray)
                    .contentTransition(.opacity)
                    .lineLimit(1)

                Text(asset.compactPrice)
                    .font(.system(size: 10, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .lineLimit(1)

                Image(systemName: asset.change24h >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(asset.changeColor)
                    .contentTransition(.opacity)
            }
            .fixedSize()
            .animation(.easeInOut(duration: 0.5), value: safeIdx)
            .onAppear { startCycling(count: assets.count) }
            .onDisappear { stopCycling() }
            .onChange(of: assets.count) { newCount in
                if displayIndex >= newCount { displayIndex = 0 }
                startCycling(count: newCount)
            }
        }
    }

    private var currentAsset: MarketAsset? {
        let assets = loadedAssets
        guard !assets.isEmpty else { return nil }
        return assets[displayIndex % assets.count]
    }

    /// Left half for flanking layout: icon + symbol
    @ViewBuilder
    var leftContent: some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.gray)
            if let asset = currentAsset {
                Text(asset.symbol)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.gray)
                    .contentTransition(.opacity)
                    .lineLimit(1)
            }
        }
        .fixedSize()
    }

    /// Right half for flanking layout: price + arrow
    @ViewBuilder
    var rightContent: some View {
        if let asset = currentAsset {
            HStack(spacing: 3) {
                Text(asset.compactPrice)
                    .font(.system(size: 10, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                Image(systemName: asset.change24h >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(asset.changeColor)
                    .contentTransition(.opacity)
            }
            .fixedSize()
        }
    }

    private func startCycling(count: Int) {
        stopCycling()
        guard count > 1 else { return }
        cycleTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task { @MainActor in
                let c = loadedAssets.count
                guard c > 0 else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    displayIndex = (displayIndex + 1) % c
                }
            }
        }
    }

    private func stopCycling() {
        cycleTimer?.invalidate()
        cycleTimer = nil
    }
}
