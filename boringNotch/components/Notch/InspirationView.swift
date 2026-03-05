//
//  InspirationView.swift
//  boringNotch
//

import Defaults
import SwiftUI

struct InspirationView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var inspirationManager = InspirationManager.shared
    @Default(.useLiquidGlass) var useLiquidGlass
    @State private var copiedItemId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            chatList
            inputBar
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
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

            Text("Inspiration")
                .font(.system(size: 13, weight: .semibold))
                .adaptiveText(isGlass: useLiquidGlass)

            Spacer()

            HStack(spacing: 6) {
                if !inspirationManager.items.isEmpty {
                    Button {
                        inspirationManager.copyAll()
                        withAnimation(.smooth) { copiedItemId = nil }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 9))
                            Text("Copy all")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(useLiquidGlass ? .white.opacity(0.7) : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(useLiquidGlass ? 0.12 : 0.06))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        withAnimation(.smooth) {
                            inspirationManager.clearAll()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(useLiquidGlass ? .white.opacity(0.5) : .gray.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Color.clear.frame(width: 44, height: 1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                if inspirationManager.items.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(inspirationManager.items) { item in
                            messageBubble(item)
                                .id(item.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                }
            }
            .onChange(of: inspirationManager.items.count) { _, _ in
                if let lastId = inspirationManager.items.last?.id {
                    withAnimation(.smooth) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "lightbulb")
                .font(.system(size: 20))
                .conditionalModifier(useLiquidGlass) { $0.glassIcon() }
                .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(.gray.opacity(0.5)) }
            Text("Record your inspirations here")
                .font(.system(size: 11))
                .conditionalModifier(useLiquidGlass) { $0.glassSecondaryText() }
                .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(.gray) }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func messageBubble(_ item: InspirationItem) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: 40)

            VStack(alignment: .trailing, spacing: 3) {
                Text(item.text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .conditionalModifier(useLiquidGlass) { $0.shadow(color: .black.opacity(0.2), radius: 0.5, y: 0.5) }
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

                HStack(spacing: 6) {
                    Text(item.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.35))

                    Button {
                        inspirationManager.copyItem(item)
                        withAnimation(.smooth) { copiedItemId = item.id }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.smooth) {
                                if copiedItemId == item.id { copiedItemId = nil }
                            }
                        }
                    } label: {
                        Image(systemName: copiedItemId == item.id ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 8))
                            .foregroundStyle(copiedItemId == item.id ? .green : .white.opacity(0.35))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        withAnimation(.smooth) {
                            inspirationManager.deleteItem(item)
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(useLiquidGlass ? Color.white.opacity(0.12) : Color.cyan.opacity(0.15))
            )
        }
    }

    private var inputBar: some View {
        HStack(spacing: 6) {
            TextField("What's on your mind...", text: $inspirationManager.inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(useLiquidGlass ? Color.white.opacity(0.1) : Color.white.opacity(0.06))
                )
                .onSubmit {
                    withAnimation(.smooth) {
                        inspirationManager.addItem()
                    }
                }

            Button {
                withAnimation(.smooth) {
                    inspirationManager.addItem()
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.cyan)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(inspirationManager.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}
