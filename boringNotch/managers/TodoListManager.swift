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

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.isCompleted = false
        self.createdAt = Date()
    }
}

@MainActor
class TodoListManager: ObservableObject {
    static let shared = TodoListManager()

    @Published var items: [TodoItem] {
        didSet { Defaults[.todoItems] = items }
    }
    @Published var inputText: String = ""

    private init() {
        self.items = Defaults[.todoItems]
    }

    func addItem() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.insert(TodoItem(text: trimmed), at: 0)
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
}
