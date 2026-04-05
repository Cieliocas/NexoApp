# Nexo — Hierarchical Academic Glossary for iOS

Nexo is a native iOS app that lets students and educators build a rich, **hierarchical academic glossary** — organised by subject, enriched with examples, and intelligently connected using **on-device AI**.

---

## Features

### 📚 Hierarchical Glossary
- Organise terms under nested subjects (Biology → Cell Biology → Mitosis)
- Each term has a name, definition, and optional worked example
- Browse all subjects in a grid or drill into a category's term list

### 🤖 On-Device AI (NaturalLanguage Framework)
All AI processing runs entirely on-device using Apple's **NaturalLanguage** framework — no data ever leaves your phone.

| Feature | How it works |
|---|---|
| **Definition Validation** | Scores language quality, length, POS composition, and semantic relevance between the term name and its definition |
| **Related-Term Discovery** | Uses `NLEmbedding` word vectors to find semantically similar terms already in your glossary |
| **Category Suggestion** | Recommends the best-matching subject for a new term via cosine similarity |

### 🔗 Concept Connections
- Manually link terms with typed relationships: *Related To, Prerequisite For, Part Of, Example Of, Contrasts With*
- AI auto-suggests connections when you save a new term

### 🔍 Full-Text Search
- Searches term names **and** definitions in real-time
- Highlights matched keywords in results

---

## Requirements

| | |
|---|---|
| **Platform** | iOS 17.0+ |
| **Xcode** | 15.0+ |
| **Swift** | 5.9+ |
| **Frameworks** | SwiftUI, SwiftData, NaturalLanguage |

---

## Project Structure

```
NexoApp/
├── Models/
│   ├── Term.swift               SwiftData model for glossary entries
│   ├── GlossaryCategory.swift   Hierarchical category model
│   └── TermRelationship.swift   Typed link between two terms
├── Services/
│   └── AIValidationService.swift  On-device NLP engine
├── ViewModels/
│   └── GlossaryViewModel.swift  Central state + business logic
├── Views/
│   ├── HomeView.swift
│   ├── CategoriesView.swift
│   ├── CategoryDetailView.swift
│   ├── TermDetailView.swift
│   ├── AddTermView.swift
│   ├── SearchView.swift
│   └── Components/
│       ├── TermCard.swift
│       ├── CategoryCard.swift
│       └── AIValidationCard.swift
└── Extensions/
    └── Color+Hex.swift
```

---

## Getting Started

1. Clone the repository
2. Open `NexoApp.xcodeproj` in Xcode 15+
3. Select an iPhone simulator (iOS 17+) and run

Eight default subjects are seeded automatically on first launch. Add your first term with the **+** button and tap **Validate with AI** to see the on-device analysis.

---

## Running Tests

Tests live in `NexoAppTests/AIValidationServiceTests.swift` and cover validation scoring, related-term discovery, and model-type correctness. Run them via **⌘U** in Xcode or:

```bash
xcodebuild test -scheme NexoApp -destination 'platform=iOS Simulator,name=iPhone 15'
```
