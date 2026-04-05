import SwiftData
import Foundation

@Model
final class GlossaryCategory {
    @Attribute(.unique)
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "book.closed.fill"
    var colorHex: String = "#5E6AD2"
    /// UUID of the parent category (nil = root level)
    var parentID: UUID?
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Term.category)
    var terms: [Term] = []

    init(
        name: String,
        icon: String = "book.closed.fill",
        colorHex: String = "#5E6AD2",
        parentID: UUID? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.parentID = parentID
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
