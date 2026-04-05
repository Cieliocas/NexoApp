import SwiftUI

struct SubjectCard: View {
    let subject: Subject

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill")
                .foregroundStyle(.tint)
                .imageScale(.large)

            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title)
                    .font(.headline)
                Text("\(subject.terms.count) termo\(subject.terms.count == 1 ? \"\" : \"s\")")
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

