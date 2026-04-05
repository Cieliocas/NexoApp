import SwiftUI
import SwiftData

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var subject: Subject

    @State private var showingAddTerm = false
    @State private var newTermName: String = ""
    @State private var newTermImportance: Int = 3

    var body: some View {
        List {
            if subject.terms.isEmpty {
                ContentUnavailableView(
                    "Sem termos ainda",
                    systemImage: "tray",
                    description: Text("Toque em \"Adicionar\" para criar o primeiro termo desta materia.")
                )
            } else {
                Section {
                    OutlineGroup(sortedTopLevelTerms(subject.terms), children: \.outlineChildren) { term in
                        NavigationLink {
                            TermDetailView(term: term)
                        } label: {
                            TermRow(term: term)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(subject.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newTermName = ""
                    newTermImportance = 3
                    showingAddTerm = true
                } label: {
                    Label("Adicionar Termo", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddTerm) {
            NavigationStack {
                Form {
                    Section("Novo Termo") {
                        TextField("Nome (ex: TCP)", text: $newTermName)
                        Stepper(value: $newTermImportance, in: 1...5) {
                            HStack {
                                Text("Importancia")
                                Spacer()
                                Text("\(newTermImportance)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Adicionar Termo")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showingAddTerm = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Salvar") {
                            addTerm(name: newTermName, importance: newTermImportance)
                            showingAddTerm = false
                        }
                        .disabled(newTermName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func sortedTopLevelTerms(_ terms: [Term]) -> [Term] {
        terms
            .filter { $0.parentTerm == nil }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func addTerm(name: String, importance: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let term = Term(name: trimmed, importance: importance, subject: subject)
        subject.terms.append(term)
        try? modelContext.save()
    }
}

private extension Term {
    var outlineChildren: [Term]? {
        let children = subTerms.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return children.isEmpty ? nil : children
    }
}

