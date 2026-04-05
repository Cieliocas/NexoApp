# Nexo

Nexo e um app de glossario academico hierarquico para iOS (SwiftUI + SwiftData). A ideia e ajudar estudantes de computacao a organizar conceitos em forma de arvore (Materia > Termo > Sub-termo) e, no futuro, validar o aprendizado com IA on-device.

## Funcionalidades

- Materias (`Subject`) com lista de termos
- Termos (`Term`) com:
  - definicao autoral do usuario
  - importancia (1 a 5)
  - acuracia da IA (opcional, para integracao futura)
  - sub-termos recursivos (estrutura em arvore)
- Navegacao com `NavigationStack`
- Lista hierarquica de termos com `OutlineGroup` (expand/collapse)
- Tela de detalhe do termo com `TextEditor`, `Gauge` e gestao de sub-termos
- UI seguindo Apple HIG (SF Symbols, Dark Mode, `InsetGrouped` list style)

## Arquitetura (alto nivel)

- SwiftUI para UI e navegacao
- SwiftData para persistencia local
- Injecao via `@Environment(\\.modelContext)` nas views

## Modelo de dados (SwiftData)

- `Subject`
  - `id: UUID`
  - `title: String`
  - `terms: [Term]`
- `Term`
  - `name: String`
  - `userDefinition: String`
  - `importance: Int` (1...5)
  - `aiAccuracy: Double?` (0...1, opcional)
  - `parentTerm: Term?`
  - `subTerms: [Term]`

## Como rodar

1. Abra `Nexo.xcodeproj` no Xcode.
2. Selecione um simulador (ex: iPhone).
3. Rode com `Cmd + R`.

## Roadmap

- Integracao de validacao com IA local (NaturalLanguage / modelos on-device)
- Melhorias de UX para criar/editar termos e sub-termos
- Busca e filtragem de termos por materia
