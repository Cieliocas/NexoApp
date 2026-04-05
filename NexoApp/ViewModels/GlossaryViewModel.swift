import SwiftUI
import SwiftData

@MainActor
final class GlossaryViewModel: ObservableObject {

    // MARK: - Search
    @Published var searchText: String = ""

    // MARK: - Add-Term sheet state
    @Published var isAddingTerm: Bool = false
    @Published var newTermName: String = ""
    @Published var newTermDefinition: String = ""
    @Published var newTermExample: String = ""
    @Published var selectedNewTermCategory: GlossaryCategory?

    // MARK: - AI state
    @Published var validationResult: ValidationResult?
    @Published var isValidating: Bool = false
    @Published var suggestedRelations: [RelatedTermSuggestion] = []

    // AIValidationService is non-isolated (thread-safe), so it can safely be
    // called from this @MainActor ViewModel without any cross-isolation concerns.
    private let aiService = AIValidationService.shared

    // MARK: - Validation

    func validateCurrentTerm() {
        guard !newTermName.isEmpty, !newTermDefinition.isEmpty else { return }
        isValidating = true
        validationResult = nil
        Task {
            let result = aiService.validateDefinition(term: newTermName, definition: newTermDefinition)
            self.validationResult = result
            self.isValidating = false
        }
    }

    // MARK: - Save

    func saveTerm(modelContext: ModelContext, allTerms: [Term]) {
        guard !newTermName.trimmingCharacters(in: .whitespaces).isEmpty,
              !newTermDefinition.trimmingCharacters(in: .whitespaces).isEmpty
        else { return }

        let term = Term(
            name: newTermName.trimmingCharacters(in: .whitespaces),
            definition: newTermDefinition.trimmingCharacters(in: .whitespaces),
            example: newTermExample.trimmingCharacters(in: .whitespaces),
            category: selectedNewTermCategory
        )

        if let result = validationResult {
            term.isAIValidated = result.isValid
            term.aiScore = result.score
        }

        modelContext.insert(term)

        // Auto-create AI-suggested relationships for the top matches.
        let suggestions = aiService.findRelatedTerms(for: term, in: allTerms, limit: 3)
        for suggestion in suggestions {
            let rel = TermRelationship(
                sourceTermID: term.id,
                targetTermID: suggestion.term.id,
                type: .aiSuggested,
                strength: suggestion.similarity
            )
            modelContext.insert(rel)
        }

        resetAddTermState()
    }

    func resetAddTermState() {
        newTermName = ""
        newTermDefinition = ""
        newTermExample = ""
        selectedNewTermCategory = nil
        validationResult = nil
        suggestedRelations = []
        isValidating = false
        isAddingTerm = false
    }

    // MARK: - Filtering

    func filtered(_ terms: [Term]) -> [Term] {
        guard !searchText.isEmpty else { return terms }
        let q = searchText.lowercased()
        return terms.filter {
            $0.name.lowercased().contains(q) ||
            $0.termDefinition.lowercased().contains(q)
        }
    }

    // MARK: - Category helpers

    /// Returns all root-level categories (no parent).
    func rootCategories(from categories: [GlossaryCategory]) -> [GlossaryCategory] {
        categories.filter { $0.parentID == nil }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Returns direct children of a given category.
    func subcategories(of parent: GlossaryCategory, from all: [GlossaryCategory]) -> [GlossaryCategory] {
        all.filter { $0.parentID == parent.id }.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Default seed data

    func insertDefaultCategoriesIfNeeded(modelContext: ModelContext, existing: [GlossaryCategory]) {
        guard existing.isEmpty else { return }

        let defaults: [(String, String, String)] = [
            ("Biology",          "leaf.fill",                    "#34C759"),
            ("Mathematics",      "function",                     "#5E6AD2"),
            ("Computer Science", "cpu.fill",                     "#0071E3"),
            ("Physics",          "atom",                         "#FF9500"),
            ("Chemistry",        "flask.fill",                   "#FF3B30"),
            ("History",          "clock.fill",                   "#8E8E93"),
            ("Literature",       "book.fill",                    "#AF52DE"),
            ("Economics",        "chart.line.uptrend.xyaxis",    "#30B0C7"),
        ]

        for (i, (name, icon, color)) in defaults.enumerated() {
            let cat = GlossaryCategory(name: name, icon: icon, colorHex: color, sortOrder: i)
            modelContext.insert(cat)
        }
    }
}
