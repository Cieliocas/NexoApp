import SwiftUI
import SwiftData

struct TermDetailView: View {
    let term: Term

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var viewModel: GlossaryViewModel
    @Query private var allTerms: [Term]
    @Query private var allRelationships: [TermRelationship]

    @State private var relatedSuggestions: [RelatedTermSuggestion] = []
    @State private var isLoadingRelated = false
    @State private var showAddRelationSheet = false
    @State private var selectedRelType: RelationshipType = .relatedTo

    private var existingRelationships: [TermRelationship] {
        allRelationships.filter { $0.sourceTermID == term.id || $0.targetTermID == term.id }
    }

    private func relatedTerm(for rel: TermRelationship) -> Term? {
        let otherID = rel.sourceTermID == term.id ? rel.targetTermID : rel.sourceTermID
        return allTerms.first { $0.id == otherID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerCard

                // Definition
                detailSection(title: "Definition", icon: "text.alignleft") {
                    Text(term.termDefinition)
                        .font(.body)
                }

                // Example (if present)
                if !term.example.isEmpty {
                    detailSection(title: "Example", icon: "lightbulb.fill") {
                        Text(term.example)
                            .font(.body)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                }

                // AI validation badge
                if term.isAIValidated {
                    aiValidationSection
                }

                // Connected Terms
                connectionsSection

                // AI-suggested relations
                aiSuggestionsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(term.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddRelationSheet = true } label: {
                    Image(systemName: "link.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showAddRelationSheet) {
            addRelationSheet
        }
        .task {
            await loadAISuggestions()
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        HStack(spacing: 14) {
            if let category = term.category {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: category.colorHex).opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: category.icon)
                        .foregroundStyle(Color(hex: category.colorHex))
                        .font(.title3)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(term.name)
                    .font(.title2.bold())
                if let cat = term.category {
                    Text(cat.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var aiValidationSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "cpu")
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Validated")
                    .font(.subheadline.bold())
                Text("Score: \(Int(term.aiScore * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ScoreBadge(score: term.aiScore)
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var connectionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Connected Terms", systemImage: "arrow.triangle.branch")
                .font(.headline)

            if existingRelationships.isEmpty {
                Text("No connections yet. Use the link button to add one.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(existingRelationships) { rel in
                    if let other = relatedTerm(for: rel) {
                        NavigationLink(destination: TermDetailView(term: other)) {
                            RelationshipRow(relationship: rel, otherTerm: other)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var aiSuggestionsSection: some View {
        if isLoadingRelated {
            HStack {
                ProgressView()
                Text("Finding related terms…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else if !relatedSuggestions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("AI Suggestions", systemImage: "cpu")
                    .font(.headline)

                ForEach(relatedSuggestions) { suggestion in
                    NavigationLink(destination: TermDetailView(term: suggestion.term)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.term.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(suggestion.reason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            SimilarityBadge(value: suggestion.similarity)
                            Button {
                                addAISuggestedRelationship(suggestion)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func detailSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Add Relation Sheet

    private var addRelationSheet: some View {
        NavigationStack {
            List {
                Section("Relationship Type") {
                    ForEach(RelationshipType.allCases, id: \.self) { type in
                        Button {
                            selectedRelType = type
                        } label: {
                            HStack {
                                Label(type.rawValue, systemImage: type.icon)
                                Spacer()
                                if selectedRelType == type {
                                    Image(systemName: "checkmark").foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Link to Term") {
                    ForEach(allTerms.filter { $0.id != term.id }) { other in
                        Button {
                            let rel = TermRelationship(
                                sourceTermID: term.id,
                                targetTermID: other.id,
                                type: selectedRelType
                            )
                            modelContext.insert(rel)
                            showAddRelationSheet = false
                        } label: {
                            VStack(alignment: .leading) {
                                Text(other.name).font(.body.weight(.semibold))
                                Text(other.termDefinition).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Add Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddRelationSheet = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Actions

    private func loadAISuggestions() async {
        guard !allTerms.isEmpty else { return }
        isLoadingRelated = true

        // Capture value types from SwiftData models before hopping off the main actor.
        let termSnapshot = TermSnapshot(term: term)
        let candidateSnapshots = allTerms.filter { $0.id != term.id }.map(TermSnapshot.init)
        let existingIDs = Set(existingRelationships.flatMap { [$0.sourceTermID, $0.targetTermID] })

        // Run embedding computation on a background priority task to avoid
        // blocking the main thread for large glossaries.
        let rawSuggestions = await Task.detached(priority: .userInitiated) {
            AIValidationService.shared.findRelatedTermSnapshots(
                for: termSnapshot,
                in: candidateSnapshots
            )
        }.value

        // Map back to full Term objects on the main actor.
        let termsByID = Dictionary(uniqueKeysWithValues: allTerms.map { ($0.id, $0) })
        relatedSuggestions = rawSuggestions
            .filter { !existingIDs.contains($0.termID) }
            .compactMap { raw in
                guard let fullTerm = termsByID[raw.termID] else { return nil }
                return RelatedTermSuggestion(term: fullTerm, similarity: raw.similarity, reason: raw.reason)
            }
        isLoadingRelated = false
    }

    private func addAISuggestedRelationship(_ suggestion: RelatedTermSuggestion) {
        let rel = TermRelationship(
            sourceTermID: term.id,
            targetTermID: suggestion.term.id,
            type: .aiSuggested,
            strength: suggestion.similarity
        )
        modelContext.insert(rel)
        relatedSuggestions.removeAll { $0.id == suggestion.id }
    }
}

// MARK: - Supporting views

private struct RelationshipRow: View {
    let relationship: TermRelationship
    let otherTerm: Term

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: relationship.relationshipType.icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(otherTerm.name)
                    .font(.subheadline.weight(.semibold))
                Text(relationship.relationshipType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if relationship.relationshipType == .aiSuggested {
                SimilarityBadge(value: relationship.strength)
            }
        }
    }
}

struct ScoreBadge: View {
    let score: Double
    private var color: Color {
        score >= 0.8 ? .green : score >= 0.6 ? .blue : score >= 0.4 ? .orange : .red
    }
    var body: some View {
        Text("\(Int(score * 100))%")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

struct SimilarityBadge: View {
    let value: Double
    var body: some View {
        Text(String(format: "%.0f%%", value * 100))
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.8))
            .clipShape(Capsule())
    }
}
