import SwiftUI
import SwiftData

struct TermDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var term: Term

    @State private var showingAddSubterm = false
    @State private var newSubtermName: String = ""
    @State private var newSubtermImportance: Int = 3

    var body: some View {
        let sortedSubTerms = term.subTerms.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        List {
            Section("Informacoes") {
                TextField("Nome do termo", text: $term.name)
                    .textInputAutocapitalization(.words)

                Stepper(value: $term.importance, in: 1...5) {
                    HStack {
                        Text("Importancia")
                        Spacer()
                        ImportancePips(value: term.importance)
                    }
                }
            }

            Section("Definicao do Usuario") {
                TextEditor(text: $term.userDefinition)
                    .frame(minHeight: 160)
                    .font(.body)
                    .overlay {
                        if term.userDefinition.isEmpty {
                            Text("Escreva aqui sua definicao autoral...")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
            }

            Section("Acuracia da IA") {
                HStack {
                    if let accuracy = term.aiAccuracy {
                        Gauge(value: accuracy, in: 0...1) {
                            Label("Nexo IA", systemImage: "checkmark.seal")
                        } currentValueLabel: {
                            Text(accuracy, format: .percent)
                        }
                        .tint(.green)
                    } else {
                        Label("Aguardando validacao", systemImage: "checkmark.seal")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Button {
                    validateWithAI()
                } label: {
                    Label("Validar com Nexo IA", systemImage: "checkmark.seal")
                }
            }

            Section {
                if term.subTerms.isEmpty {
                    Text("Nenhum sub-termo adicionado.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedSubTerms) { child in
                        NavigationLink {
                            TermDetailView(term: child)
                        } label: {
                            TermRow(term: child)
                        }
                    }
                    .onDelete { offsets in
                        deleteSubterms(at: offsets, in: sortedSubTerms)
                    }
                }
            } header: {
                Text("Sub-termos")
            } footer: {
                Button {
                    newSubtermName = ""
                    newSubtermImportance = 3
                    showingAddSubterm = true
                } label: {
                    Label("Adicionar Sub-termo", systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
                .padding(.top, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(term.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSubterm) {
            NavigationStack {
                Form {
                    Section("Novo Sub-termo") {
                        TextField("Nome (ex: IPv4)", text: $newSubtermName)
                        Stepper(value: $newSubtermImportance, in: 1...5) {
                            HStack {
                                Text("Importancia")
                                Spacer()
                                Text("\(newSubtermImportance)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Adicionar Sub-termo")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showingAddSubterm = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Salvar") {
                            addSubterm(name: newSubtermName, importance: newSubtermImportance)
                            showingAddSubterm = false
                        }
                        .disabled(newSubtermName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func addSubterm(name: String, importance: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let child = Term(name: trimmed, importance: importance, subject: term.subject, parentTerm: term)
        term.subTerms.append(child)
        try? modelContext.save()
    }

    private func deleteSubterms(at offsets: IndexSet, in sortedSubTerms: [Term]) {
        for index in offsets {
            modelContext.delete(sortedSubTerms[index])
        }
        try? modelContext.save()
    }

    private func validateWithAI() {
        // Futuro: integracao com NaturalLanguage / on-device ML
        // Exemplo (comentado):
        // import NaturalLanguage
        // let tagger = NLTagger(tagSchemes: [.lexicalClass])
        // tagger.string = term.userDefinition
        // ... processar e calcular porcentagem de acuracia ...
        // term.aiAccuracy = calculo
        // try? modelContext.save()
    }
}

