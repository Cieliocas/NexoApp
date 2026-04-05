import SwiftUI
import SwiftData

#Preview("Home") {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: [Subject.self, Term.self], inMemory: true)
}

#Preview("Subject Detail") {
    let subject = Subject(title: "Redes de Computadores")

    let camadaRede = Term(name: "Camada de Rede", importance: 5, subject: subject)
    let transporte = Term(name: "Transporte", importance: 4, subject: subject)
    subject.terms.append(camadaRede)
    subject.terms.append(transporte)

    let ipv4 = Term(name: "IPv4", importance: 4, subject: subject, parentTerm: camadaRede)
    let ipv6 = Term(name: "IPv6", importance: 4, subject: subject, parentTerm: camadaRede)
    camadaRede.subTerms.append(ipv4)
    camadaRede.subTerms.append(ipv6)

    let tcp = Term(name: "TCP", importance: 5, subject: subject, parentTerm: transporte)
    let udp = Term(name: "UDP", importance: 3, subject: subject, parentTerm: transporte)
    transporte.subTerms.append(tcp)
    transporte.subTerms.append(udp)

    NavigationStack {
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

    NavigationStack {
        TermDetailView(term: term)
    }
    .modelContainer(for: [Subject.self, Term.self], inMemory: true)
}

