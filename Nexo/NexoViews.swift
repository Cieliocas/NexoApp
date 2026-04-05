//
//  NexoViews.swift
//  Nexo
//
//  Created by Franciélio Castro on 03/04/26.
//

import SwiftUI
import SwiftData

// MARK: - Home (Subjects list)

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
                    Label("Adicionar Matéria", systemImage: "plus.circle.fill")
                }
                .accessibilityIdentifier("addSubjectButton")
            }
        }
        .sheet(isPresented: $showingAddSubject) {
            NavigationStack {
                Form {
                    Section("Nova Matéria") {
                        TextField("Título (ex: Redes de Computadores)", text: $newSubjectTitle)
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

private struct SubjectCard: View {
    let subject: Subject

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill")
                .foregroundStyle(.tint)
                .imageScale(.large)

            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title)
                    .font(.headline)
                Text("\(subject.terms.count) termo\(subject.terms.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Subject Detail (Hierarchical terms)

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
                    description: Text("Toque em “Adicionar” para criar o primeiro termo desta matéria.")
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
                                Text("Importância")
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

private struct TermRow: View {
    let term: Term

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "network")
                .foregroundStyle(.tint)
                .imageScale(.medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(term.name)
                    .font(.body)
                    .fontWeight(.medium)

                if !term.userDefinition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(term.userDefinition)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            ImportancePips(value: term.importance)
        }
        .padding(.vertical, 4)
    }
}

private struct ImportancePips: View {
    let value: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= value ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("Importância \(value) de 5")
    }
}

// MARK: - Term Detail

struct TermDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var term: Term

    @State private var showingAddSubterm = false
    @State private var newSubtermName: String = ""
    @State private var newSubtermImportance: Int = 3

    var body: some View {
        let sortedSubTerms = term.subTerms.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        List {
            Section("Informações") {
                TextField("Nome do termo", text: $term.name)
                    .textInputAutocapitalization(.words)

                Stepper(value: $term.importance, in: 1...5) {
                    HStack {
                        Text("Importância")
                        Spacer()
                        ImportancePips(value: term.importance)
                    }
                }
            }

            Section("Definição do Usuário") {
                TextEditor(text: $term.userDefinition)
                    .frame(minHeight: 160)
                    .font(.body)
                    .overlay {
                        if term.userDefinition.isEmpty {
                            Text("Escreva aqui sua definição autoral…")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
            }

            Section("Acurácia da IA") {
                HStack {
                    if let accuracy = term.aiAccuracy {
                        Gauge(value: accuracy, in: 0...1) {
                            Label("Nexo IA", systemImage: "checkmark.seal")
                        } currentValueLabel: {
                            Text(accuracy, format: .percent)
                        }
                        .tint(.green)
                    } else {
                        Label("Aguardando validação", systemImage: "checkmark.seal")
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
                                Text("Importância")
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
        // Futuro: integração com NaturalLanguage / on-device ML
        // Exemplo (comentado):
        // import NaturalLanguage
        // let tagger = NLTagger(tagSchemes: [.lexicalClass])
        // tagger.string = term.userDefinition
        // ... processar e calcular porcentagem de acurácia ...
        // term.aiAccuracy = calculo
        // try? modelContext.save()
    }
}

private extension Term {
    var outlineChildren: [Term]? {
        let children = subTerms.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return children.isEmpty ? nil : children
    }
}

// MARK: - Previews

#Preview("Home") {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: [Subject.self, Term.self], inMemory: true)
}

#Preview("Subject Detail") {
    let subject = Subject(title: "Redes de Computadores")

    // Criar termos top-level
    let camadaRede = Term(name: "Camada de Rede", importance: 5, subject: subject)
    let transporte = Term(name: "Transporte", importance: 4, subject: subject)

    // Anexar ao subject
    subject.terms.append(camadaRede)
    subject.terms.append(transporte)

    // Sub-termos de Camada de Rede
    let ipv4 = Term(name: "IPv4", importance: 4, subject: subject, parentTerm: camadaRede)
    let ipv6 = Term(name: "IPv6", importance: 4, subject: subject, parentTerm: camadaRede)
    camadaRede.subTerms.append(ipv4)
    camadaRede.subTerms.append(ipv6)

    // Sub-termos de Transporte
    let tcp = Term(name: "TCP", importance: 5, subject: subject, parentTerm: transporte)
    let udp = Term(name: "UDP", importance: 3, subject: subject, parentTerm: transporte)
    transporte.subTerms.append(tcp)
    transporte.subTerms.append(udp)

    return NavigationStack {
        SubjectDetailView(subject: subject)
    }
    .modelContainer(for: [Subject.self, Term.self], inMemory: true)
}

#Preview("Term Detail") {
    let subject = Subject(title: "Sistemas Operacionais")
    let term = Term(name: "Escalonamento", importance: 4, subject: subject)
    subject.terms.append(term)

    let rr = Term(name: "Round-Robin", importance: 3, subject: subject, parentTerm: term)
    let prio = Term(name: "Prioridades", importance: 4, subject: subject, parentTerm: term)
    term.subTerms.append(rr)
    term.subTerms.append(prio)

    return NavigationStack {
        TermDetailView(term: term)
    }
    .modelContainer(for: [Subject.self, Term.self], inMemory: true)
}
