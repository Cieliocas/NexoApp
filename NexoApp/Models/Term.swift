import SwiftData
import Foundation

@Model
final class Term {
    @Attribute(.unique)
    var id: UUID = UUID()
    var name: String = ""
    var termDefinition: String = ""
    var example: String = ""
    @Relationship(deleteRule: .nullify)
    var category: GlossaryCategory?
    var isAIValidated: Bool = false
    var aiScore: Double = 0.0
    var createdAt: Date = Date()

    init(
        name: String,
        definition: String,
        example: String = "",
        category: GlossaryCategory? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.termDefinition = definition
        self.example = example
        self.category = category
        self.isAIValidated = false
        self.aiScore = 0.0
        self.createdAt = Date()
    }
}
