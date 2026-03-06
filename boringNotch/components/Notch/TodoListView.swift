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
        VStack(alignment: .leading, spacing: 6) {
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

    // MARK: - Header

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

            if let selected = todoManager.selectedDate {
                Button {
                    withAnimation(.smooth) { todoManager.selectDate(nil) }
                } label: {
                    HStack(spacing: 3) {
                        Text(shortDateLabel(selected))
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(useLiquidGlass ? .white.opacity(0.7) : .gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(useLiquidGlass ? 0.12 : 0.06)))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Text("Todo")
                    .font(.system(size: 13, weight: .semibold))
                    .adaptiveText(isGlass: useLiquidGlass)
            }

            Spacer()

            if todoManager.items.contains(where: \.isCompleted) {
                Button {
                    withAnimation(.smooth) { todoManager.clearCompleted() }
                } label: {
                    Text("Clear done")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(useLiquidGlass ? .white.opacity(0.6) : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(useLiquidGlass ? 0.12 : 0.06)))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Color.clear.frame(width: 44, height: 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    // MARK: - Input

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
                    withAnimation(.smooth) { todoManager.addItem() }
                }

            Button {
                withAnimation(.smooth) { todoManager.addItem() }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.cyan)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(todoManager.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - List

    private var todoList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            let sections = todoManager.dateSections
            if sections.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 4, pinnedViews: [.sectionHeaders]) {
                    ForEach(sections) { section in
                        Section {
                            ForEach(section.items) { item in
                                todoRow(item, isOverdueSection: section.isOverdue)
                                    .id("\(item.id.uuidString)_\(item.isCompleted)")
                                    .transition(.opacity)
                            }
                        } header: {
                            sectionHeader(section)
                                .id("header_\(section.id.hashValue)_\(section.items.filter(\.isCompleted).count)")
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ section: TodoDateSection) -> some View {
        HStack(spacing: 6) {
            if section.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange)
            }

            Text(section.title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(section.isOverdue ? .orange : (useLiquidGlass ? .white.opacity(0.55) : Color(white: 0.5)))

            if !section.isOverdue && section.id != Date.distantPast {
                Text("\(section.items.filter { !$0.isCompleted }.count)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(useLiquidGlass ? .white.opacity(0.4) : Color(white: 0.45))
            }

            Spacer()

            if !section.isOverdue && section.id != Date.distantPast && todoManager.selectedDate == nil {
                Button {
                    withAnimation(.smooth) { todoManager.selectDate(section.id) }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(useLiquidGlass ? .white.opacity(0.35) : .gray.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .fill(useLiquidGlass ? Color.black.opacity(0.75) : Color.black)
        )
    }

    // MARK: - Empty & Row

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

    private func todoRow(_ item: TodoItem, isOverdueSection: Bool) -> some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.smooth) { todoManager.toggleItem(item) }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        item.isCompleted
                            ? .cyan
                            : (isOverdueSection ? .orange.opacity(0.7) : (useLiquidGlass ? .white.opacity(0.5) : .gray))
                    )
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 1) {
                Text(item.text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(item.isCompleted ? .white.opacity(0.35) : .white)
                    .strikethrough(item.isCompleted, color: .white.opacity(0.3))
                    .lineLimit(2)
                    .conditionalModifier(useLiquidGlass) { $0.shadow(color: .black.opacity(0.2), radius: 0.5, y: 0.5) }

                if isOverdueSection {
                    Text(shortDateLabel(item.dueDate))
                        .font(.system(size: 9))
                        .foregroundStyle(.orange.opacity(0.6))
                }
            }

            Spacer()

            Button {
                withAnimation(.smooth) { todoManager.deleteItem(item) }
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
                .fill(Color.white.opacity(
                    item.isCompleted ? 0.02 :
                    (isOverdueSection ? 0.06 : (useLiquidGlass ? 0.08 : 0.04))
                ))
        )
    }

    // MARK: - Helpers

    private func shortDateLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}
