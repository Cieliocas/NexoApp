import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let category: GlossaryCategory

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var viewModel: GlossaryViewModel
    @Query private var allCategories: [GlossaryCategory]
    @Query(sort: \Term.name) private var allTerms: [Term]

    private var terms: [Term] {
        allTerms.filter { $0.category?.id == category.id }
    }

    private var subcategories: [GlossaryCategory] {
        viewModel.subcategories(of: category, from: allCategories)
    }

    var body: some View {
        List {
            if !subcategories.isEmpty {
                Section("Subcategories") {
                    ForEach(subcategories) { sub in
                        NavigationLink(destination: CategoryDetailView(category: sub)) {
                            Label(sub.name, systemImage: sub.icon)
                        }
                    }
                }
            }

            Section {
                if terms.isEmpty {
                    Text("No terms yet. Tap + to add one.")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(terms) { term in
                        NavigationLink(destination: TermDetailView(term: term)) {
                            TermRow(term: term)
                        }
                    }
                    .onDelete(perform: deleteTerms)
                }
            } header: {
                HStack {
                    Text("Terms")
                    Spacer()
                    Text("\(terms.count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.selectedNewTermCategory = category
                    viewModel.isAddingTerm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isAddingTerm) {
            AddTermView()
                .environmentObject(viewModel)
        }
    }

    private func deleteTerms(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(terms[index])
        }
    }
}

private struct TermRow: View {
    let term: Term

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(term.name)
                    .font(.body.weight(.semibold))
                Spacer()
                if term.isAIValidated {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            Text(term.termDefinition)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}
