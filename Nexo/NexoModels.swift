//
//  NexoModels.swift
//  Nexo
//
//  Created by Franciélio Castro on 03/04/26.
//

import Foundation
import SwiftData

@Model
final class Subject {
    var id: UUID
    var title: String

    // One Subject has many Terms. Cascade delete keeps tree integrity.
    @Relationship(deleteRule: .cascade)
    var terms: [Term]

    init(id: UUID = UUID(), title: String, terms: [Term] = []) {
        self.id = id
        self.title = title
        self.terms = terms
        // Não force inverses manualmente; SwiftData gerencia pelo inverse.
    }
}

@Model
final class Term {
    // Back-reference ao Subject
    var subject: Subject?

    // Relacionamento recursivo: pai
    var parentTerm: Term?

    // Relacionamento recursivo: filhos
    @Relationship(deleteRule: .cascade, inverse: \Term.parentTerm)
    var subTerms: [Term]

    // Dados
    var name: String
    var userDefinition: String
    var importance: Int
    var aiAccuracy: Double?

    init(
        name: String,
        userDefinition: String = "",
        importance: Int = 3,
        aiAccuracy: Double? = nil,
        subject: Subject? = nil,
        parentTerm: Term? = nil,
        subTerms: [Term] = []
    ) {
        self.name = name
        self.userDefinition = userDefinition
        self.importance = importance
        self.aiAccuracy = aiAccuracy
        self.subject = subject
        self.parentTerm = parentTerm
        self.subTerms = subTerms
        // Evitar setar inverses manualmente para não conflitar com macros.
    }
}
