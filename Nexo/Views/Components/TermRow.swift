import SwiftUI

struct TermRow: View {
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

