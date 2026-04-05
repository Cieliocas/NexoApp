import SwiftUI
import SwiftData

struct AddTermView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: GlossaryViewModel
    @Query private var categories: [GlossaryCategory]
    @Query private var allTerms: [Term]

    var body: some View {
        NavigationStack {
            Form {
                termDetailsSection
                categorySection
                aiValidationSection
            }
            .navigationTitle("New Term")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetAddTermState()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveTerm(modelContext: modelContext, allTerms: allTerms)
                        dismiss()
                    }
                    .disabled(
                        viewModel.newTermName.trimmingCharacters(in: .whitespaces).isEmpty ||
                        viewModel.newTermDefinition.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }
            }
        }
    }

    // MARK: - Sections

    private var termDetailsSection: some View {
        Section("Term Details") {
            TextField("Term name (e.g. Photosynthesis)", text: $viewModel.newTermName)
                .autocorrectionDisabled()

            VStack(alignment: .leading, spacing: 6) {
                Text("Definition")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $viewModel.newTermDefinition)
                    .frame(minHeight: 90)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Example (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $viewModel.newTermExample)
                    .frame(minHeight: 60)
            }
        }
    }

    private var categorySection: some View {
        Section("Category") {
            Picker("Subject", selection: $viewModel.selectedNewTermCategory) {
                Text("None").tag(GlossaryCategory?.none)
                ForEach(categories) { cat in
                    Label(cat.name, systemImage: cat.icon).tag(Optional(cat))
                }
            }
        }
    }

    @ViewBuilder
    private var aiValidationSection: some View {
        Section {
            Button {
                viewModel.validateCurrentTerm()
            } label: {
                HStack {
                    Image(systemName: "cpu")
                    Text(viewModel.isValidating ? "Validating…" : "Validate with AI")
                    Spacer()
                    if viewModel.isValidating {
                        ProgressView()
                    }
                }
            }
            .disabled(
                viewModel.newTermName.isEmpty ||
                viewModel.newTermDefinition.isEmpty ||
                viewModel.isValidating
            )

            if let result = viewModel.validationResult {
                AIValidationCard(result: result)
            }
        } header: {
            Text("On-Device AI")
        } footer: {
            Text("Nexo uses NaturalLanguage AI to score definition quality and discover related concepts — entirely on your device.")
                .font(.caption)
        }
    }
}

#Preview {
    AddTermView()
        .environmentObject(GlossaryViewModel())
        .modelContainer(for: [Term.self, GlossaryCategory.self, TermRelationship.self],
                        inMemory: true)
}
