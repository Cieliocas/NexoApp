import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.title, order: .forward) private var subjects: [Subject]

    @State private var showingAddSubject = false
    @State private var newSubjectTitle: String = ""

    var body: some View {
        List {
            ForEach(subjects) { subject in
                NavigationLink {
                    SubjectDetailView(subject: subject)
                } label: {
                    SubjectCard(subject: subject)
                }
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteSubjects)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Nexo")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSubject = true
                    newSubjectTitle = ""
                } label: {
                    Label("Adicionar Materia", systemImage: "plus.circle.fill")
                }
                .accessibilityIdentifier("addSubjectButton")
            }
        }
        .sheet(isPresented: $showingAddSubject) {
            NavigationStack {
                Form {
                    Section("Nova Materia") {
                        TextField("Titulo (ex: Redes de Computadores)", text: $newSubjectTitle)
                            .textInputAutocapitalization(.words)
                    }
                }
                .navigationTitle("Adicionar")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showingAddSubject = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Salvar") {
                            addSubject(title: newSubjectTitle.trimmingCharacters(in: .whitespacesAndNewlines))
                            showingAddSubject = false
                        }
                        .disabled(newSubjectTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func addSubject(title: String) {
        guard !title.isEmpty else { return }
        let subject = Subject(title: title)
        modelContext.insert(subject)
        try? modelContext.save()
    }

    private func deleteSubjects(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(subjects[index])
        }
        try? modelContext.save()
    }
}

