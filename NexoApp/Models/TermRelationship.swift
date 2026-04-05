import SwiftData
import Foundation

/// The semantic relationship between two academic terms.
enum RelationshipType: String, Codable, CaseIterable {
    case relatedTo       = "Related To"
    case prerequisiteFor = "Prerequisite For"
    case partOf          = "Part Of"
    case exampleOf       = "Example Of"
    case contrastsWith   = "Contrasts With"
    case aiSuggested     = "AI Suggested"

    var icon: String {
        switch self {
        case .relatedTo:       return "arrow.left.arrow.right"
        case .prerequisiteFor: return "arrow.right"
        case .partOf:          return "square.3.layers.3d"
        case .exampleOf:       return "lightbulb"
        case .contrastsWith:   return "arrow.up.arrow.down"
        case .aiSuggested:     return "cpu"
        }
    }
}

/// A directional, typed connection between two Terms.
@Model
final class TermRelationship {
    @Attribute(.unique)
    var id: UUID = UUID()
    /// Identifier of the originating term.
    var sourceTermID: UUID = UUID()
    /// Identifier of the target term.
    var targetTermID: UUID = UUID()
    var relationshipType: RelationshipType = RelationshipType.relatedTo
    /// Similarity strength in [0, 1]; 1.0 for manually created relationships.
    var strength: Double = 1.0
    var createdAt: Date = Date()

    init(
        sourceTermID: UUID,
        targetTermID: UUID,
        type: RelationshipType,
        strength: Double = 1.0
    ) {
        self.id = UUID()
        self.sourceTermID = sourceTermID
        self.targetTermID = targetTermID
        self.relationshipType = type
        self.strength = strength
        self.createdAt = Date()
    }
}
