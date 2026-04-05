import SwiftUI
import SwiftData

struct SearchView: View {
    @EnvironmentObject private var viewModel: GlossaryViewModel
    @Query(sort: \Term.name) private var allTerms: [Term]

    private var results: [Term] { viewModel.filtered(allTerms) }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.searchText.isEmpty {
                    searchPlaceholder
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                } else {
                    List(results) { term in
                        NavigationLink(destination: TermDetailView(term: term)) {
                            SearchResultRow(term: term, query: viewModel.searchText)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.searchText, prompt: "Search terms or definitions…")
        }
    }

    private var searchPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("Search Your Glossary")
                .font(.title3.bold())
            Text("Type a term name or keyword to search across all definitions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct SearchResultRow: View {
    let term: Term
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HighlightedText(text: term.name, highlight: query, font: .body.weight(.semibold))
                Spacer()
                if term.isAIValidated {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            HighlightedText(
                text: term.termDefinition,
                highlight: query,
                font: .caption,
                color: .secondary,
                lineLimit: 2
            )
            if let cat = term.category {
                Label(cat.name, systemImage: cat.icon)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Renders `text` with occurrences of `highlight` bolded.
private struct HighlightedText: View {
    let text: String
    let highlight: String
    var font: Font = .body
    var color: Color = .primary
    var lineLimit: Int? = nil

    var body: some View {
        let attributed = buildAttributedString()
        Text(attributed)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(lineLimit)
    }

    private func buildAttributedString() -> AttributedString {
        var result = AttributedString(text)
        guard !highlight.isEmpty else { return result }
        let lowerText = text.lowercased()
        let lowerHighlight = highlight.lowercased()
        var searchStart = lowerText.startIndex

        while let range = lowerText.range(of: lowerHighlight, range: searchStart..<lowerText.endIndex) {
            let offset = lowerText.distance(from: lowerText.startIndex, to: range.lowerBound)
            let attrStart = result.index(result.startIndex, offsetByCharacters: offset)
            let attrEnd = result.index(attrStart, offsetByCharacters: highlight.count)
            result[attrStart..<attrEnd].font = font.bold()
            result[attrStart..<attrEnd].foregroundColor = .primary
            searchStart = range.upperBound
        }
        return result
    }
}

#Preview {
    SearchView()
        .environmentObject(GlossaryViewModel())
        .modelContainer(for: [Term.self, GlossaryCategory.self, TermRelationship.self],
                        inMemory: true)
}
