import SwiftUI

enum TermCardStyle { case compact, standard }

struct TermCard: View {
    let term: Term
    var style: TermCardStyle = .standard

    var body: some View {
        switch style {
        case .compact:  compactBody
        case .standard: standardBody
        }
    }

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(term.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer()
                if term.isAIValidated {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.caption2)
                }
            }
            Text(term.termDefinition)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if let cat = term.category {
                Label(cat.name, systemImage: cat.icon)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: cat.colorHex))
            }
        }
        .padding(12)
        .frame(width: 180)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var standardBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(term.name)
                    .font(.headline)
                Spacer()
                if term.isAIValidated {
                    ScoreBadge(score: term.aiScore)
                }
            }
            Text(term.termDefinition)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            if let cat = term.category {
                Label(cat.name, systemImage: cat.icon)
                    .font(.caption)
                    .foregroundStyle(Color(hex: cat.colorHex))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
