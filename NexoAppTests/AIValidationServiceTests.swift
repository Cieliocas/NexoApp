import XCTest
@testable import NexoApp

// NOTE: AIValidationService is @MainActor, so tests run on the main actor.
@MainActor
final class AIValidationServiceTests: XCTestCase {

    var service: AIValidationService!

    override func setUp() {
        super.setUp()
        service = AIValidationService.shared
    }

    // MARK: - validateDefinition

    func test_emptyDefinition_returnsInvalidResult() {
        let result = service.validateDefinition(term: "Mitosis", definition: "")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.score, 0)
    }

    func test_shortDefinition_hasLowScore() {
        let result = service.validateDefinition(term: "Mitosis", definition: "Cell division")
        // Very short — score should be below the valid threshold
        XCTAssertLessThan(result.score, 0.6)
        XCTAssertFalse(result.suggestions.isEmpty)
    }

    func test_goodDefinition_isValid() {
        let definition = """
        Mitosis is the process of cell division in eukaryotic organisms where a single parent cell \
        divides to produce two genetically identical daughter cells, each containing the same \
        number of chromosomes as the original cell.
        """
        let result = service.validateDefinition(term: "Mitosis", definition: definition)
        XCTAssertTrue(result.isValid)
        XCTAssertGreaterThanOrEqual(result.score, 0.45)
    }

    func test_validationGrade_excellent() {
        let result = ValidationResult(score: 0.85, isValid: true, feedback: [], suggestions: [])
        XCTAssertEqual(result.grade, .excellent)
    }

    func test_validationGrade_needsWork() {
        let result = ValidationResult(score: 0.20, isValid: false, feedback: [], suggestions: [])
        XCTAssertEqual(result.grade, .needsWork)
    }

    func test_scorePercent() {
        let result = ValidationResult(score: 0.75, isValid: true, feedback: [], suggestions: [])
        XCTAssertEqual(result.scorePercent, 75)
    }

    // MARK: - findRelatedTerms

    func test_findRelatedTerms_emptyList_returnsEmpty() {
        let term = Term(name: "Photosynthesis", definition: "Process by which plants make food from sunlight.")
        let suggestions = service.findRelatedTerms(for: term, in: [])
        XCTAssertTrue(suggestions.isEmpty)
    }

    func test_findRelatedTerms_excludesSelf() {
        let term = Term(name: "Mitosis", definition: "Cell division process in eukaryotes.")
        let suggestions = service.findRelatedTerms(for: term, in: [term])
        XCTAssertTrue(suggestions.isEmpty)
    }

    func test_findRelatedTerms_respectsLimit() {
        let base = Term(name: "Cell", definition: "The basic structural and functional unit of all living organisms.")
        let others = (1...10).map { i in
            Term(name: "Term\(i)", definition: "A biological cell unit organism structure \(i).")
        }
        let suggestions = service.findRelatedTerms(for: base, in: others, limit: 3)
        XCTAssertLessThanOrEqual(suggestions.count, 3)
    }

    func test_relatedTermSuggestion_hasPositiveSimilarity() {
        let base = Term(name: "Algorithm", definition: "A step-by-step procedure for solving a computational problem.")
        let related = Term(name: "Computational Complexity", definition: "The study of algorithm efficiency and resource requirements.")
        let suggestions = service.findRelatedTerms(for: base, in: [related], limit: 5)
        for s in suggestions {
            XCTAssertGreaterThan(s.similarity, 0)
            XCTAssertLessThanOrEqual(s.similarity, 1)
        }
    }

    // MARK: - suggestCategory

    func test_suggestCategory_emptyList_returnsNil() {
        let category = service.suggestCategory(for: "Photosynthesis", categories: [])
        XCTAssertNil(category)
    }

    // MARK: - RelationshipType

    func test_relationshipType_allCasesHaveIcon() {
        for relType in RelationshipType.allCases {
            XCTAssertFalse(relType.icon.isEmpty, "\(relType) should have a non-empty SF Symbol name")
        }
    }
}
