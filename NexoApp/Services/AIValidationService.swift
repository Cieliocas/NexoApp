import Foundation
import NaturalLanguage

// MARK: - Result Types

/// Quality grade of a validated definition.
enum ValidationGrade: String, CaseIterable {
    case excellent       = "Excellent"
    case good            = "Good"
    case fair            = "Fair"
    case needsWork       = "Needs Work"

    var sfSymbol: String {
        switch self {
        case .excellent:  return "checkmark.seal.fill"
        case .good:       return "checkmark.circle.fill"
        case .fair:       return "exclamationmark.circle.fill"
        case .needsWork:  return "xmark.circle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .excellent:  return "green"
        case .good:       return "blue"
        case .fair:       return "orange"
        case .needsWork:  return "red"
        }
    }
}

/// The outcome of validating a term's definition.
struct ValidationResult {
    let score: Double           // 0.0 – 1.0
    let isValid: Bool
    let feedback: [String]
    let suggestions: [String]

    var grade: ValidationGrade {
        switch score {
        case 0.80...1.0: return .excellent
        case 0.60..<0.80: return .good
        case 0.40..<0.60: return .fair
        default:          return .needsWork
        }
    }

    var scorePercent: Int { Int(score * 100) }
}

/// A semantically related term discovered by the AI engine.
struct RelatedTermSuggestion: Identifiable {
    let id = UUID()
    let term: Term
    let similarity: Double      // 0.0 – 1.0
    let reason: String
}

/// Sendable value-type snapshot of a Term used for background-safe computation.
struct TermSnapshot: Sendable {
    let id: UUID
    let name: String
    let definition: String

    init(term: Term) {
        self.id = term.id
        self.name = term.name
        self.definition = term.termDefinition
    }
}

/// Raw suggestion returned from background computation before mapping to full Terms.
struct RawTermSuggestion: Sendable {
    let termID: UUID
    let similarity: Double
    let reason: String
}

// MARK: - AIValidationService

/// On-device AI service that uses Apple's NaturalLanguage framework to
/// validate academic definitions and discover semantic connections between terms.
///
/// The class is not actor-isolated so expensive embedding computations can be
/// called from a background `Task` without blocking the main thread.
final class AIValidationService: ObservableObject {

    static let shared = AIValidationService()

    // NLEmbedding is thread-safe (Apple documentation) and loaded once.
    private let wordEmbedding: NLEmbedding?

    private init() {
        wordEmbedding = NLEmbedding.wordEmbedding(for: .english)
    }

    // MARK: - Definition Validation

    /// Validates an academic definition using on-device NLP heuristics.
    func validateDefinition(term: String, definition: String) -> ValidationResult {
        guard !definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ValidationResult(
                score: 0,
                isValid: false,
                feedback: [],
                suggestions: ["Please enter a definition before validating."]
            )
        }

        var score = 0.0
        var feedback: [String] = []
        var suggestions: [String] = []

        // 1. Language coherence (20 %)
        let langScore = languageCoherenceScore(for: definition)
        score += langScore * 0.20
        if langScore < 0.5 {
            suggestions.append("Write the definition in clear, standard English.")
        }

        // 2. Word-count length (20 %)
        let words = definition.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordCount = words.count
        let targetWordCount = 25.0
        let lengthScore = min(Double(wordCount) / targetWordCount, 1.0)
        score += lengthScore * 0.20
        if wordCount < 10 {
            suggestions.append("Expand your definition (currently \(wordCount) words; aim for 20+).")
        } else {
            feedback.append("Good length — \(wordCount) words.")
        }

        // 3. Academic POS composition (30 %)
        let posScore = academicPOSScore(for: definition)
        score += posScore * 0.30
        if posScore > 0.65 {
            feedback.append("Definition uses precise, academic language.")
        } else {
            suggestions.append("Use more specific nouns and descriptive adjectives.")
        }

        // 4. Semantic relevance between term and definition (30 %)
        let relevanceScore = semanticRelevanceScore(term: term, definition: definition)
        score += relevanceScore * 0.30
        if relevanceScore < 0.25 {
            suggestions.append("Make sure the definition directly explains '\(term)'.")
        } else {
            feedback.append("Definition is semantically relevant to the term.")
        }

        let finalScore = min(score, 1.0)
        return ValidationResult(
            score: finalScore,
            isValid: finalScore >= 0.45,
            feedback: feedback,
            suggestions: suggestions
        )
    }

    // MARK: - Related-Term Discovery

    /// Returns up to `limit` semantically related terms from `allTerms`, ranked by similarity.
    func findRelatedTerms(
        for term: Term,
        in allTerms: [Term],
        limit: Int = 5
    ) -> [RelatedTermSuggestion] {
        let candidates = allTerms.filter { $0.id != term.id }
        guard !candidates.isEmpty else { return [] }

        if let embedding = wordEmbedding {
            return embeddingBasedSuggestions(for: term, candidates: candidates, embedding: embedding, limit: limit)
        }
        return keywordBasedSuggestions(for: term, candidates: candidates, limit: limit)
    }

    /// Background-safe version that works on `TermSnapshot` value types.
    /// Called from `Task.detached` in views to avoid blocking the main thread.
    func findRelatedTermSnapshots(
        for term: TermSnapshot,
        in candidates: [TermSnapshot],
        limit: Int = 5
    ) -> [RawTermSuggestion] {
        guard !candidates.isEmpty else { return [] }

        if let embedding = wordEmbedding {
            return candidates
                .compactMap { candidate -> (UUID, Double)? in
                    guard let tVec = averageVector(for: term.name, embedding: embedding),
                          let cVec = averageVector(for: candidate.name, embedding: embedding)
                    else { return nil }
                    let sim = cosineSimilarity(tVec, cVec)
                    return sim > 0.25 ? (candidate.id, sim) : nil
                }
                .sorted { $0.1 > $1.1 }
                .prefix(limit)
                .map { RawTermSuggestion(termID: $0.0, similarity: $0.1, reason: "Semantically similar concept") }
        }

        // Keyword fallback
        let termWords = Set(tokens(for: term.name + " " + term.definition).filter { $0.count > 3 })
        return candidates
            .compactMap { candidate -> (UUID, Double)? in
                let candWords = Set(tokens(for: candidate.name + " " + candidate.definition).filter { $0.count > 3 })
                let jaccard = jaccardSimilarity(termWords, candWords)
                return jaccard > 0.08 ? (candidate.id, jaccard) : nil
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { RawTermSuggestion(termID: $0.0, similarity: $0.1, reason: "Shares common terminology") }
    }

    // MARK: - Category Suggestion

    /// Suggests the best-fitting category for a term name from a list of categories.
    func suggestCategory(for termName: String, categories: [GlossaryCategory]) -> GlossaryCategory? {
        guard let embedding = wordEmbedding, !categories.isEmpty else { return nil }
        guard let termVec = averageVector(for: termName, embedding: embedding) else { return nil }

        var best: (GlossaryCategory, Double)? = nil
        for category in categories {
            guard let catVec = averageVector(for: category.name, embedding: embedding) else { continue }
            let sim = cosineSimilarity(termVec, catVec)
            if best == nil || sim > best!.1 { best = (category, sim) }
        }
        guard let (cat, sim) = best, sim > 0.25 else { return nil }
        return cat
    }

    // MARK: - Private: Scoring helpers

    private func languageCoherenceScore(for text: String) -> Double {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let lang = recognizer.dominantLanguage else { return 0.5 }
        return lang == .english ? 1.0 : 0.2
    }

    private func academicPOSScore(for text: String) -> Double {
        // NLTagger is not thread-safe; create a fresh instance per call.
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        var nouns = 0
        var total = 0
        tagger.enumerateTags(
            in: range,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, _ in
            guard let tag else { return true }
            total += 1
            if tag == .noun || tag == .adjective { nouns += 1 }
            return true
        }
        guard total > 0 else { return 0.5 }
        // Academic prose typically has 45–70 % nouns + adjectives.
        return min(Double(nouns) / Double(total) * 1.5, 1.0)
    }

    private func semanticRelevanceScore(term: String, definition: String) -> Double {
        guard let embedding = wordEmbedding else {
            return keywordRelevanceScore(term: term, definition: definition)
        }
        let termTokens = tokens(for: term)
        let defTokens  = tokens(for: definition).filter { $0.count > 3 }
        guard !termTokens.isEmpty, !defTokens.isEmpty else { return 0.5 }

        var maxSim = 0.0
        for t in termTokens {
            for d in defTokens {
                let dist = embedding.distance(between: t, and: d, distanceType: .cosine)
                let sim = 1.0 - Double(dist)
                if sim > maxSim { maxSim = sim }
            }
        }
        return maxSim
    }

    private func keywordRelevanceScore(term: String, definition: String) -> Double {
        let termWords = Set(tokens(for: term))
        let defWords  = Set(tokens(for: definition))
        let overlap   = termWords.intersection(defWords).count
        return Double(overlap) / Double(max(termWords.count, 1))
    }

    // MARK: - Private: Embedding helpers

    private func embeddingBasedSuggestions(
        for term: Term,
        candidates: [Term],
        embedding: NLEmbedding,
        limit: Int
    ) -> [RelatedTermSuggestion] {
        guard let termVec = averageVector(for: term.name, embedding: embedding) else {
            return keywordBasedSuggestions(for: term, candidates: candidates, limit: limit)
        }

        return candidates
            .compactMap { candidate -> (Term, Double)? in
                guard let cVec = averageVector(for: candidate.name, embedding: embedding) else { return nil }
                let sim = cosineSimilarity(termVec, cVec)
                return sim > 0.25 ? (candidate, sim) : nil
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { RelatedTermSuggestion(term: $0.0, similarity: $0.1, reason: "Semantically similar concept") }
    }

    private func keywordBasedSuggestions(
        for term: Term,
        candidates: [Term],
        limit: Int
    ) -> [RelatedTermSuggestion] {
        let termWords = Set(tokens(for: term.name + " " + term.termDefinition).filter { $0.count > 3 })
        return candidates
            .compactMap { candidate -> (Term, Double)? in
                let candWords = Set(tokens(for: candidate.name + " " + candidate.termDefinition).filter { $0.count > 3 })
                let jaccard = jaccardSimilarity(termWords, candWords)
                return jaccard > 0.08 ? (candidate, jaccard) : nil
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { RelatedTermSuggestion(term: $0.0, similarity: $0.1, reason: "Shares common terminology") }
    }

    private func jaccardSimilarity(_ a: Set<String>, _ b: Set<String>) -> Double {
        let inter = a.intersection(b).count
        let union = a.union(b).count
        return union > 0 ? Double(inter) / Double(union) : 0
    }

    private func averageVector(for text: String, embedding: NLEmbedding) -> [Double]? {
        let wordList = tokens(for: text)
        let vecs = wordList.compactMap { embedding.vector(for: $0) }.map { $0.map { Double($0) } }
        guard !vecs.isEmpty else { return nil }
        let dim = vecs[0].count
        var avg = [Double](repeating: 0, count: dim)
        for vec in vecs {
            for i in 0..<min(dim, vec.count) { avg[i] += vec[i] }
        }
        return avg.map { $0 / Double(vecs.count) }
    }

    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let len = min(a.count, b.count)
        guard len > 0 else { return 0 }
        var dot = 0.0, magA = 0.0, magB = 0.0
        for i in 0..<len {
            dot  += a[i] * b[i]
            magA += a[i] * a[i]
            magB += b[i] * b[i]
        }
        let denom = sqrt(magA) * sqrt(magB)
        return denom > 0 ? dot / denom : 0
    }

    private func tokens(for text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: .init(charactersIn: " \t\n\r,.;:!?\"'()[]{}-"))
            .filter { !$0.isEmpty }
    }
}
