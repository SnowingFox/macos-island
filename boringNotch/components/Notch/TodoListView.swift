//
//  TodoListView.swift
//  boringNotch
//

import Defaults
import SwiftUI

struct TodoListView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var todoManager = TodoListManager.shared
    @Default(.useLiquidGlass) var useLiquidGlass

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            inputBar
                .padding(.horizontal, 12)
            todoList
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

            Text("Todo")
                .font(.system(size: 13, weight: .semibold))
                .adaptiveText(isGlass: useLiquidGlass)

            Spacer()

            if todoManager.items.contains(where: \.isCompleted) {
                Button {
                    withAnimation(.smooth) {
                        todoManager.clearCompleted()
                    }
                } label: {
                    Text("Clear done")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(useLiquidGlass ? .white.opacity(0.6) : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(useLiquidGlass ? 0.12 : 0.06))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Color.clear.frame(width: 44, height: 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var inputBar: some View {
        HStack(spacing: 6) {
            TextField("Add a task...", text: $todoManager.inputText)
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
                        todoManager.addItem()
                    }
                }

            Button {
                withAnimation(.smooth) {
                    todoManager.addItem()
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.cyan)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(todoManager.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var todoList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            if todoManager.items.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(todoManager.items) { item in
                        todoRow(item)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "checklist")
                .font(.system(size: 20))
                .conditionalModifier(useLiquidGlass) { $0.glassIcon() }
                .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(.gray.opacity(0.5)) }
            Text("No tasks yet — type above to add one")
                .font(.system(size: 11))
                .conditionalModifier(useLiquidGlass) { $0.glassSecondaryText() }
                .conditionalModifier(!useLiquidGlass) { $0.foregroundStyle(.gray) }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func todoRow(_ item: TodoItem) -> some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.smooth) {
                    todoManager.toggleItem(item)
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(item.isCompleted ? .cyan : (useLiquidGlass ? .white.opacity(0.5) : .gray))
            }
            .buttonStyle(PlainButtonStyle())

            Text(item.text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(item.isCompleted ? .white.opacity(0.35) : .white)
                .strikethrough(item.isCompleted, color: .white.opacity(0.3))
                .lineLimit(2)
                .conditionalModifier(useLiquidGlass) { $0.shadow(color: .black.opacity(0.2), radius: 0.5, y: 0.5) }

            Spacer()

            Button {
                withAnimation(.smooth) {
                    todoManager.deleteItem(item)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(useLiquidGlass ? .white.opacity(0.35) : .gray.opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(item.isCompleted ? 0.02 : (useLiquidGlass ? 0.08 : 0.04)))
        )
    }
}
