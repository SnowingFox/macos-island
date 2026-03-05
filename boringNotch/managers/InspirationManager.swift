//
//  InspirationManager.swift
//  boringNotch
//

import Defaults
import Foundation
import AppKit

struct InspirationItem: Codable, Identifiable, Equatable, Defaults.Serializable {
    let id: UUID
    var text: String
    var createdAt: Date

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
    }
}

@MainActor
class InspirationManager: ObservableObject {
    static let shared = InspirationManager()

    @Published var items: [InspirationItem] {
        didSet { Defaults[.inspirationItems] = items }
    }
    @Published var inputText: String = ""

    private init() {
        self.items = Defaults[.inspirationItems]
    }

    func addItem() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(InspirationItem(text: trimmed))
        inputText = ""
    }

    func deleteItem(_ item: InspirationItem) {
        items.removeAll { $0.id == item.id }
    }

    func copyItem(_ item: InspirationItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.text, forType: .string)
    }

    func copyAll() {
        let allText = items.map(\.text).joined(separator: "\n\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(allText, forType: .string)
    }

    func clearAll() {
        items.removeAll()
    }
}
