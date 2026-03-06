//
//  TodoListManager.swift
//  boringNotch
//

import Defaults
import Foundation

struct TodoItem: Codable, Identifiable, Equatable, Defaults.Serializable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date

    init(text: String, dueDate: Date? = nil) {
        self.id = UUID()
        self.text = text
        self.isCompleted = false
        self.createdAt = Date()
        self.dueDate = dueDate ?? Calendar.current.startOfDay(for: Date())
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
            ?? Calendar.current.startOfDay(for: createdAt)
    }
}

struct TodoDateSection: Identifiable {
    let id: Date
    let title: String
    let items: [TodoItem]
    let isOverdue: Bool
}

@MainActor
class TodoListManager: ObservableObject {
    static let shared = TodoListManager()

    @Published var items: [TodoItem] {
        didSet { Defaults[.todoItems] = items }
    }
    @Published var inputText: String = ""
    @Published var selectedDate: Date? = nil

    private init() {
        self.items = Defaults[.todoItems]
    }

    var overdueItems: [TodoItem] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return items.filter { !$0.isCompleted && $0.dueDate < startOfToday }
    }

    var dateSections: [TodoDateSection] {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())

        let source: [TodoItem]
        if let selected = selectedDate {
            let selectedStart = cal.startOfDay(for: selected)
            source = items.filter { cal.startOfDay(for: $0.dueDate) == selectedStart }
        } else {
            source = items
        }

        let grouped = Dictionary(grouping: source) { item in
            cal.startOfDay(for: item.dueDate)
        }

        var sections: [TodoDateSection] = []

        let overdue = source.filter { !$0.isCompleted && $0.dueDate < startOfToday }
        if !overdue.isEmpty && selectedDate == nil {
            sections.append(TodoDateSection(
                id: Date.distantPast,
                title: "Overdue",
                items: overdue.sorted { $0.dueDate < $1.dueDate },
                isOverdue: true
            ))
        }

        let sortedDates = grouped.keys.sorted(by: >)
        for date in sortedDates {
            guard var dayItems = grouped[date] else { continue }
            if selectedDate == nil && date < startOfToday {
                dayItems = dayItems.filter { $0.isCompleted }
                if dayItems.isEmpty { continue }
            }
            dayItems.sort { ($0.isCompleted ? 1 : 0) < ($1.isCompleted ? 1 : 0) }
            sections.append(TodoDateSection(
                id: date,
                title: sectionTitle(for: date),
                items: dayItems,
                isOverdue: false
            ))
        }

        return sections
    }

    func addItem() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let due = selectedDate ?? Calendar.current.startOfDay(for: Date())
        items.insert(TodoItem(text: trimmed, dueDate: due), at: 0)
        inputText = ""
    }

    func toggleItem(_ item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
        }
    }

    func deleteItem(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearCompleted() {
        items.removeAll { $0.isCompleted }
    }

    func selectDate(_ date: Date?) {
        selectedDate = date
    }

    private static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd EEEE"
        formatter.locale = Locale.current
        return formatter
    }()

    private func sectionTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Today"
        } else if cal.isDateInYesterday(date) {
            return "Yesterday"
        } else if cal.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            return Self.sectionDateFormatter.string(from: date)
        }
    }
}
